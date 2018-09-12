function spikes_cell_array = assign_closest_center_window(spikes_cell_array, centers, metric_pdist)

if ~exist(metric_pdist, 'var')
  metric_pdist = 'cosine';
end

clusters = centers.data;
n_channels = centers.n_channels;
%radius = centers.radius;
tau = centers.tau;
fieldname_polarity = centers.fieldname_polarity;
n_polarities = centers.n_polarities;
n_el_context = n_channels)*n_polarities;

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
    pol = uint32(spikes.(fieldname_polarity)(ind_ev)) + 1;
    cpt_ctx = cpt_ctx + 1;
    for ind_p = 1:n_polarities
      ctx_spikes(cpt_ctx,(1:n_channels)+n_channels*(ind_p-1)) = ...
        exp(-(t_ev - events_buffer(ind_p, 1:n_channels)) / tau);
    end
    events_buffer(pol, c) = t_ev;
  end
  [~, spikes_cell_array{ind}.closest_center] = min(pdist2(ctx_spikes, clusters, ...
    metric_pdist), [], 2);
  waitbar(ind/numel(spikes_cell_array),wb)
end
delete(wb)
