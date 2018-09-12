function contexts = aggregate_contexts(spikes_cell_array, specs_layer)

% FIXME : use the fieldname for the polarity in order to do multiple layers

n_channels = specs_layer.n_channels;
radius = specs_layer.radius;
tau = specs_layer.tau;
fieldname_polarity = specs_layer.fieldname_polarity;
n_polarities = specs_layer.n_polarities;

n_el_context = (2*radius+1)*n_polarities;
n_spikes = sum(cellfun(@(ev) numel(ev.ts), spikes_cell_array));

if (n_el_context*n_spikes*8 > 8*1024^3)
  error(['Context of all spikes need ', num2str(n_el_context*n_spikes*8/(1024^3), '%.1f'), ...
    ' Go of RAM. Aborting.'])
end
contexts = cell(1,numel(spikes_cell_array)); %NOTE: this can be huge, but it's nice to preallocate
for ind = 1:numel(spikes_cell_array)
  contexts{ind} = zeros(numel(spikes_cell_array{ind}.ts), n_el_context);
end

for ind = 1:numel(spikes_cell_array)
  events_buffer = zeros(n_polarities, n_channels+2*radius); % NOTE: adding offset to extract the context easily
  % h = imagesc(events_buffer);
  spikes = spikes_cell_array{ind};
  for ind_ev = 1:numel(spikes.ts)
    c = spikes.channel(ind_ev) + radius + 1;
    t_ev = double(spikes.ts(ind_ev));
    pol = uint32(spikes.(fieldname_polarity)(ind_ev)) + 1;
    for ind_p = 1:n_polarities
      contexts{ind}(ind_ev,(1:(2*radius+1))+(2*radius+1)*(ind_p-1)) = ...
        exp(-(t_ev - events_buffer(ind_p, c-radius:c+radius)) / tau);
    end
    events_buffer(pol, c) = t_ev;
    % h.CData = exp(-(t_ev - events_buffer) / tau);
    % drawnow;
  end
end

contexts = vertcat(contexts{:});
