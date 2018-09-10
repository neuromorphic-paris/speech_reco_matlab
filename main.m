clearvars -except spikes_train spikes_test class_train class_test;
close all;

if ~exist('spikes_test', 'var')
% Loading filenames
  [filenames_train, class_train, filenames_test, class_test] = ...
    get_filenames_on_off_database();

% Reading files
fprintf('Reading spikes....\n');
tstart_reading = tic;
spikes_train = cellfun(@(x)read_aerdat(x,1), filenames_train, 'un', 0);
spikes_test = cellfun(@(x)read_aerdat(x,1), filenames_test, 'un', 0);
t_reading = toc(tstart_reading);

n_spikes_train = cellfun(@(ev) numel(ev.ts), spikes_train);
n_spikes_test = cellfun(@(ev) numel(ev.ts), spikes_test);
fprintf('Read %d spikes fron %d files in %.2f seconds.\n', ...
  sum(n_spikes_train)+sum(n_spikes_test), ...
  numel(spikes_train)+numel(spikes_test), t_reading)
% plot(ev.ts, ev.channel, '.k')
end

%% Let's be deterministic
rng(0);


%% Splitting train into feature train and classifier train
% NOTE: maybe should split according to the class (e.g. all class represented)
numel_files_to_train_features = 5;
feature_train_files = randperm(numel(spikes_train), numel_files_to_train_features);
class_feature_train = class_train(feature_train_files)
spikes_feature_train = spikes_train(feature_train_files);
class_train(feature_train_files) = [];
spikes_train(feature_train_files) = [];


%% Training feature extractor
n_channels = 32;

specs_layer1.radius = 5;
specs_layer1.tau = 1000; % tau is an exponential decay, in microseconds
specs_layer1.n_channels = n_channels;
specs_layer1.fieldname_polarity = 'is_increase';
specs_layer1.n_polarities = 2; %is_increase is a logical

all_train_context = aggregate_contexts(spikes_feature_train, specs_layer1);


%% Rejecting empty contexts
thresh_too_far_event = 3*specs_layer1.tau; % in microseconds
ratio_empty_ctx = 0.3; % below this ratio the context will be discarded
nb_clusters = 100;

ctx_to_discard = sum(all_train_context > ...
  exp(-thresh_too_far_event/specs_layer1.tau), 2) ...
  < ratio_empty_ctx;
all_train_context(ctx_to_discard,:) = [];


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
metric_dist_assignement = 'cosine';
spikes_train = assign_closest_center(spikes_train, centers, metric_dist_assignement);
spikes_test = assign_closest_center(spikes_test, centers, metric_dist_assignement);
t_affectation = toc(tstart_affectation)


%% Compute signatures of each file
make_sig = @(x) hist(x.closest_center, nb_clusters);
make_sig_normalized = @(x) make_sig(x) / numel(x.closest_center);
sigs_train = cellfun(make_sig, spikes_train, 'un', 0)';
sigs_train = vertcat(sigs_train{:});
sigs_test = cellfun(make_sig, spikes_test, 'un', 0)';
sigs_test = vertcat(sigs_test{:});


%% Recognition task
[~, argmin] = min(pdist2(sigs_train, sigs_test));
truth = class_test;
pred = class_train(argmin);
% plotconfusion(ind2vec(truth), ind2vec(pred))
rate = sum(pred == truth)/numel(truth)
