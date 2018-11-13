function [filenames_train, class_train, filenames_test, class_test] = get_filenames_on_off_database(nb_files)

%% Training and testing files as suggested
training_files = table2array(readtable(...
  fullfile(pwd, 'speech_commands_dataset_validation_list.txt'), ...
  'Delimiter','/','ReadVariableNames',false));
testing_files = table2array(readtable(...
  fullfile(pwd, 'speech_commands_dataset_testing_list.txt'), ...
  'Delimiter','/','ReadVariableNames',false));


%% Getting on and off classes
used_classes = {'on', 'off'};
% first_folder = 'on-off_minus27db_attenuation';
first_folder = 'on-off';
folders = {fullfile(pwd, first_folder, 'on_aedats'), ...
  fullfile(pwd, first_folder, 'off_aedats')};

filenames_train = {};
filenames_test = {};
class_train = [];
class_test = [];

files_missing = 0;
for ind = 1:numel(used_classes)
  curr_class = used_classes{ind};
  files_with_curr_class = cellfun(@(x) strcmp(x, curr_class), training_files(:,1));

  curr_files_training = training_files(files_with_curr_class, :);
  nb_files_curr_class = numel(find(files_with_curr_class));
  if exist('nb_files', 'var')
    if nb_files>nb_files_curr_class
      error('Number of files argument is too big')
    else
      perm = randperm(nb_files_curr_class, nb_files);
      curr_files_training = curr_files_training(perm,:);
    end
  end

  for ind_files = 1:size(curr_files_training,1)
    curr_filename = fullfile(folders{ind}, ...
      [curr_files_training{ind_files,2}, '.aedat'])
    fid = fopen(curr_filename);
    if fid ~= -1
      filenames_train = [filenames_train;  {curr_filename}];
      class_train = [class_train, ind];
      fclose(fid);
    else
      files_missing = files_missing + 1;
    end
  end

  curr_files_testing = testing_files(files_with_curr_class, :);
  nb_files_curr_class = numel(find(files_with_curr_class));
  if exist('nb_files', 'var')
    if nb_files>nb_files_curr_class
      error('Number of files argument is too big')
    else
      perm = randperm(nb_files_curr_class, nb_files);
      curr_files_testing = curr_files_testing(perm,:);
    end
  end

  for ind_files = 1:size(curr_files_testing,1)
    curr_filename = fullfile(folders{ind}, ...
      [curr_files_testing{ind_files,2}, '.aedat']);
    fid = fopen(curr_filename);
    if fid ~= -1
      filenames_test = [filenames_test; {curr_filename}];
      class_test = [class_test, ind];
      fclose(fid);
    else
      files_missing = files_missing + 1;
    end
  end
end
% training_files
% testing_files
% filenames_train
% filenames_test
% class_train
% class_test

if isempty(class_train) || isempty(class_test)
  error('Not enough files. Is the dataset really here?')
end

% At this point, we have two variables, filenames_train and filenames_test
% which contains all full filenames of train and test files of the two classes.
fprintf(['%d files missing according to the suggested', ...
  ' train/validation list of files.\n'], files_missing)
