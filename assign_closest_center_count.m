function spikes_cell_array = assign_closest_center_count(spikes_cell_array, centers, metric_pdist, decay_rate)

metric_pdist

% exist(metric_pdist)
% exist(metric_pdist, 'var')
%
% if ~exist(metric_pdist, 'var')
%   metric_pdist = 'cosine';
% end
%
% metric_pdist

decay_rate = 1e-7;

clusters = centers.data;
n_channels = centers.n_channels;
%radius = centers.radius;
tau = centers.tau;
fieldname_polarity = centers.fieldname_polarity;
n_polarities = centers.n_polarities;
n_el_context = n_channels*n_polarities;

wb = waitbar(0, ['Crushing ', inputname(1), '...']);
wb.Children.Title.Interpreter = 'none';
for ind = 1:numel(spikes_cell_array)
  events_buffer = zeros(n_polarities, n_channels);
  spikes = spikes_cell_array{ind};
  ctx_spikes = zeros(numel(spikes.ts), n_el_context);
  cpt_ctx = 0;
  for ind_ev = 1:numel(spikes.ts)
    c = spikes.channel(ind_ev) + 1;
    t_ev = double(spikes.ts(ind_ev));
    if strcmp(fieldname_polarity, 'closest_center')
      pol = uint32(spikes.(fieldname_polarity)(ind_ev));
    else
      pol = uint32(spikes.(fieldname_polarity)(ind_ev)) + 1;
    end

    cpt_ctx = cpt_ctx + 1;
    for ind_p = 1:n_polarities
      ctx_spikes(cpt_ctx,(1:n_channels)+n_channels*(ind_p-1)) = ...
        events_buffer(ind_p, 1:n_channels);
    end
    delay_to_add = (t_ev - max(events_buffer(:)));
    % delay_to_add*decay_rate
    % 1-delay_to_add*decay_rate
    events_buffer = (1-delay_to_add*decay_rate) .* events_buffer;
    events_buffer(events_buffer<0) = 0;
    events_buffer(pol, c) = events_buffer(pol, c) + 1;
  end
  % figure;
  % subplot(121)
  % imagesc(ctx_spikes)
  % colorbar
  % subplot(122)
  % imagesc(clusters)
  % colorbar
  [spikes_cell_array{ind}.dist_closest_center, spikes_cell_array{ind}.closest_center] = min(pdist2(ctx_spikes, ...
    clusters, metric_pdist), [], 2);
    % figure
    %   subplot(121)
    % imagesc(spikes_cell_array{ind}.closest_center)
    % colorbar
    %   subplot(122)
    % imagesc(spikes_cell_array{ind}.dist_closest_center)
    % colorbar
    % pause
  waitbar(ind/numel(spikes_cell_array),wb)
end
delete(wb)
