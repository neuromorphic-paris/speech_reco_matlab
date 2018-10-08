clearvars -except spikes_feature_train spikes_train spikes_test class_train class_test;
close all;

%% Let's be deterministic
rng(0);

if ~exist('spikes_feature_train', 'var')
% Loading filenames
  [filenames_train, class_train, filenames_test, class_test] = ...
    get_filenames_on_off_database(30);


  % Reading files
  fprintf('Reading spikes....\n');
  tstart_reading = tic;
  spikes_train = cellfun(@read_aerdat, filenames_train, 'un', 0);
  spikes_test = cellfun(@read_aerdat, filenames_test, 'un', 0);
  t_reading = toc(tstart_reading);

  n_spikes_train = cellfun(@(ev) numel(ev.ts), spikes_train);
  n_spikes_test = cellfun(@(ev) numel(ev.ts), spikes_test);
  fprintf('Read %d spikes fron %d files in %.2f seconds.\n', ...
    sum(n_spikes_train)+sum(n_spikes_test), ...
    numel(spikes_train)+numel(spikes_test), t_reading)
  % plot(ev.ts, ev.channel, '.k')

  %% Splitting train into feature train and classifier train
  % NOTE: maybe should split according to the class (e.g. all class represented)
  numel_files_to_train_features = 5;
  feature_train_files = randperm(numel(spikes_train), numel_files_to_train_features);
  class_feature_train = class_train(feature_train_files)
  spikes_feature_train = spikes_train(feature_train_files);
  class_train(feature_train_files) = [];
  spikes_train(feature_train_files) = [];
end


%% Training feature extractor
n_channels = 32;

specs_layer1.radius = 4;
specs_layer1.tau = 4000; % tau is an exponential decay, in microseconds
specs_layer1.n_channels = n_channels;
specs_layer1.fieldname_polarity = 'is_increase';
specs_layer1.n_polarities = 2; %is_increase is a logical

t_start_compute_context = tic;
fprintf('Computing contexts...\n')
all_train_context = aggregate_contexts(spikes_feature_train, specs_layer1);
t_compute_context = toc(t_start_compute_context);
fprintf('Contexts computed in %.1f seconds.\n', t_compute_context)


%% Rejecting empty contexts
thresh_too_far_event = 3*specs_layer1.tau; % in microseconds
ratio_empty_ctx = 0.6; % below this ratio the context will be discarded
nb_clusters = 10;

fprintf('Size of all_train_context before reject : ')
size(all_train_context)
ctx_to_discard = (sum(all_train_context > ...
  exp(-thresh_too_far_event/specs_layer1.tau), 2) / size(all_train_context, 2)) ...
   < ratio_empty_ctx;
all_train_context(ctx_to_discard,:) = [];

fprintf('\nSize of all_train_context after reject : ')
size(all_train_context)
fprintf('\n')

%% Clustering
centers = specs_layer1;
t_start_clustering = tic;
fprintf('Kmeans clustering...\n')
[~, centers.data] = kmeans(all_train_context, nb_clusters, 'Distance', 'cosine');
t_clustering = toc(t_start_clustering);
fprintf('Done in %.2f seconds.\n', t_clustering)


%% Affecting to each event a polarity
% representing the index of the center which is close to the context
tstart_affectation = tic;
fprintf('Assigning spikes, this can take a long time...\n')
metric_dist_assignement = 'cosine';
spikes_train = assign_closest_center_window(spikes_train, centers, metric_dist_assignement);
spikes_test = assign_closest_center_window(spikes_test, centers, metric_dist_assignement);
t_affectation = toc(tstart_affectation)
fprintf('Done in %.2f seconds.\n', t_affectation)


%% Keeping only closest events
thresh_dist_validity = 0.3;
for ind = 1:numel(spikes_train)
  spikes_train{ind}.validity = spikes_train{ind}.dist_closest_center < thresh_dist_validity;
end
for ind = 1:numel(spikes_test)
  spikes_test{ind}.validity = spikes_test{ind}.dist_closest_center < thresh_dist_validity;
end


%% Compute signatures of each file
make_sig = @(x) hist(x.closest_center(x.validity), nb_clusters);
make_sig_normalized = @(x) make_sig(x) / numel(find(x.validity));
sigs_train = cellfun(make_sig_normalized, spikes_train, 'un', 0)';
sigs_train = vertcat(sigs_train{:});
sigs_test = cellfun(make_sig_normalized, spikes_test, 'un', 0)';
sigs_test = vertcat(sigs_test{:});

%% Recognition task
[~, argmin] = min(pdist2(sigs_train, sigs_test));
truth = class_test;
pred = class_train(argmin);
% plotconfusion(ind2vec(truth), ind2vec(pred))
rate = sum(pred == truth)/numel(truth)
figure;
subplot(121)
imagesc(sigs_train)
colorbar
title('train')
subplot(122)
imagesc(sigs_test)
colorbar
title('test')


fprintf('Layer 1 done.\n')
pause

%% 2nd layer?
specs_layer2.radius = 8;
specs_layer2.tau = 20000; % tau is an exponential decay, in microseconds
specs_layer2.n_channels = n_channels;
specs_layer2.fieldname_polarity = 'closest_center';
specs_layer2.n_polarities = nb_clusters; %is_increase is a logical

spikes_feature_train = assign_closest_center(spikes_feature_train, centers, metric_dist_assignement);
for ind = 1:numel(spikes_feature_train)
  spikes_feature_train{ind}.validity = spikes_feature_train{ind}.dist_closest_center < thresh_dist_validity;
end
all_train_context2 = aggregate_contexts(spikes_feature_train, specs_layer2);

thresh_too_far_event2 = 3*specs_layer2.tau; % in microseconds
ratio_empty_ctx2 = 0.3; % below this ratio the context will be discarded
nb_clusters2 = 20;

fprintf('Size of all_train_context before reject : ')
size(all_train_context2)
ctx_to_discard2 = (sum(all_train_context2 > ...
  exp(-thresh_too_far_event2/specs_layer2.tau), 2) / size(all_train_context2, 2)) ...
   < ratio_empty_ctx2;
all_train_context2(ctx_to_discard2,:) = [];

fprintf('\nSize of all_train_context after reject : ')
size(all_train_context2)
fprintf('\n')


centers2 = specs_layer2;
t_start_clustering2 = tic;
fprintf('Kmeans clustering...\n')
[~, centers2.data] = kmeans(all_train_context2, nb_clusters2, 'Distance', 'cosine');
t_clustering2 = toc(t_start_clustering2);
fprintf('Done in %.2f seconds.\n', t_clustering2)

tstart_affectation2 = tic;
metric_dist_assignement = 'cosine';
spikes_train2 = assign_closest_center(spikes_train, centers2, metric_dist_assignement);
spikes_test2 = assign_closest_center(spikes_test, centers2, metric_dist_assignement);
t_affectation2 = toc(tstart_affectation2)

thresh_dist_validity = 1;
for ind = 1:numel(spikes_train)
  spikes_train2{ind}.validity = spikes_train2{ind}.dist_closest_center < thresh_dist_validity;
end
for ind = 1:numel(spikes_test)
  spikes_test2{ind}.validity = spikes_test2{ind}.dist_closest_center < thresh_dist_validity;
end


%% Compute signatures of each file
make_sig = @(x) hist(x.closest_center(x.validity), nb_clusters2);
make_sig_normalized = @(x) make_sig(x) / numel(find(x.validity));
sigs_train2 = cellfun(make_sig_normalized, spikes_train2, 'un', 0)';
sigs_train2 = vertcat(sigs_train2{:});
sigs_test2 = cellfun(make_sig_normalized, spikes_test2, 'un', 0)';
sigs_test2 = vertcat(sigs_test2{:});
[~, argmin2] = min(pdist2(sigs_train2, sigs_test2));
truth = class_test;
pred2 = class_train(argmin2);
% plotconfusion(ind2vec(truth), ind2vec(pred))
rate2 = sum(pred2 == truth)/numel(truth)
figure;
subplot(121)
imagesc(sigs_train2)
colorbar
title('train')
subplot(122)
imagesc(sigs_test2)
colorbar
title('test')
pause



%% 3nd layer?
spikes_train = spikes_train2;
spikes_test = spikes_test2;

specs_layer3.radius = 16;
specs_layer3.tau = 100000; % tau is an exponential decay, in microseconds
specs_layer3.n_channels = n_channels;
specs_layer3.fieldname_polarity = 'closest_center';
specs_layer3.n_polarities = nb_clusters; %is_increase is a logical

spikes_feature_train = assign_closest_center(spikes_feature_train, centers2, metric_dist_assignement);
for ind = 1:numel(spikes_feature_train)
  spikes_feature_train{ind}.validity = spikes_feature_train{ind}.dist_closest_center < thresh_dist_validity;
end
all_train_context3 = aggregate_contexts(spikes_feature_train, specs_layer3);

thresh_too_far_event3 = 3*specs_layer3.tau; % in microseconds
ratio_empty_ctx3 = 0.3; % below this ratio the context will be discarded
nb_clusters3 = 40;

fprintf('Size of all_train_context before reject : ')
size(all_train_context3)
ctx_to_discard3 = (sum(all_train_context3 > ...
  exp(-thresh_too_far_event3/specs_layer3.tau), 2) / size(all_train_context3, 2)) ...
   < ratio_empty_ctx3;
all_train_context3(ctx_to_discard3,:) = [];

fprintf('\nSize of all_train_context after reject : ')
size(all_train_context3)
fprintf('\n')

centers3 = specs_layer3;
t_start_clustering3 = tic;
fprintf('Kmeans clustering...\n')
[~, centers3.data] = kmeans(all_train_context3, nb_clusters3, 'Distance', 'cosine');
t_clustering3 = toc(t_start_clustering3);
fprintf('Done in %.2f seconds.\n', t_clustering3)

tstart_affectation3 = tic;
metric_dist_assignement = 'cosine';
spikes_train3 = assign_closest_center(spikes_train2, centers3, metric_dist_assignement);
spikes_test3 = assign_closest_center(spikes_test2, centers3, metric_dist_assignement);
t_affectation3 = toc(tstart_affectation3)

thresh_dist_validity = 0.6;
for ind = 1:numel(spikes_train)
  spikes_train3{ind}.validity = spikes_train3{ind}.dist_closest_center < thresh_dist_validity;
end
for ind = 1:numel(spikes_test)
  spikes_test3{ind}.validity = spikes_test3{ind}.dist_closest_center < thresh_dist_validity;
end


%% Compute signatures of each file
make_sig = @(x) hist(x.closest_center(x.validity), nb_clusters3);
make_sig_normalized = @(x) make_sig(x) / numel(find(x.validity));
sigs_train3 = cellfun(make_sig_normalized, spikes_train3, 'un', 0)';
sigs_train3 = vertcat(sigs_train3{:});
sigs_test3 = cellfun(make_sig_normalized, spikes_test3, 'un', 0)';
sigs_test3 = vertcat(sigs_test3{:});
[~, argmin3] = min(pdist2(sigs_train3, sigs_test3));
truth = class_test;
pred3 = class_train(argmin3);
% plotconfusion(ind2vec(truth), ind2vec(pred))
rate3 = sum(pred3 == truth)/numel(truth)

figure;
subplot(121)
imagesc(sigs_train3)
colorbar
title('train')
subplot(122)
imagesc(sigs_test3)
colorbar
title('test')
pause
