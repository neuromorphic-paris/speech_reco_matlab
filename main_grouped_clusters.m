clearvars -except spikes_feature_train spikes_train spikes_test class_train class_test;
close all;

%% Let's be deterministic
rng(0);

nb_channels = 32;
nb_blocs = 4;

if ~exist('spikes_feature_train', 'var')
% Loading filenames
  [filenames_train, class_train, filenames_test, class_test] = ...
    get_filenames_on_off_database(10);


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

  spikes_feature_train
  
  spikes_feature_train = cellfun(@(x) split_spike_channels(x, nb_channels, nb_blocs), spikes_feature_train, 'un', 0);
  
  spikes_feature_train
  
  spikes_train = cellfun(@(x) split_spike_channels(x, nb_channels, nb_blocs), spikes_train, 'un', 0);
  spikes_test = cellfun(@(x) split_spike_channels(x, nb_channels, nb_blocs), spikes_test, 'un', 0);

%   spikes_feature_train = vertcat(spikes_feature_train{:});
%   spikes_train = vertcat(spikes_train{:});
%   spikes_test = vertcat(spikes_test{:});
end
