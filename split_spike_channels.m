function spikes_cell_array = split_spike_channels(spikes, nb_channels, nb_blocs, overlapping)

if exist('overlapping', 'var')
  warning('Overlapping not coded yet.')
  overlapping = false;
else
  overlapping = false;
end

if ~exist('nb_blocs', 'var')
  nb_blocs = 4;
end

if nb_channels/nb_blocs ~= floor(nb_channels/nb_blocs)
  error('Number of channels have to be a multiple of the number of blocs')
end

spikes_cell_array = cell(1, nb_blocs);
if ~overlapping
  channels = reshape(1:nb_channels, [], nb_blocs);
end

spikes_cell_array = spikes;
spikes.group = zeros(size(spikes.ts), 'uint8');

for ind = 1:nb_blocs
  curr_events = ismember(spikes.channel, channels(:,ind));

  % spikes_cell_array{ind}.ts = spikes.ts(curr_events);
  % spikes_cell_array{ind}.is_increase = spikes.is_increase(curr_events);
  % spikes_cell_array{ind}.channel = spikes.channel(curr_events) - (ind-1)*(nb_channels/nb_blocs);
  spikes.group(curr_events) = ind;
  
end
