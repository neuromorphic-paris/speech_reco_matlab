function contexts = aggregate_contexts_count(spikes_cell_array, specs_layer, decay_rate)

% FIXME : use the fieldname for the polarity in order to do multiple layers

n_channels = specs_layer.n_channels;
%radius = specs_layer.radius;
tau = specs_layer.tau;
fieldname_polarity = specs_layer.fieldname_polarity;
n_polarities = specs_layer.n_polarities;

n_el_context = n_channels*n_polarities;
n_spikes = sum(cellfun(@(ev) numel(ev.ts), spikes_cell_array));

if (n_el_context*n_spikes*8 > 8*1024^3)
  error(['Context of all spikes need ', num2str(n_el_context*n_spikes*8/(1024^3), '%.1f'), ...
    ' Go of RAM. Aborting.'])
end

contexts = zeros(n_spikes, n_el_context); %NOTE: this can be huge, but it's nice to preallocate

cpt_ctx = 0;
for ind = 1:numel(spikes_cell_array)
  events_buffer = zeros(n_polarities, n_channels); % NOTE: adding offset to extract the context easily
  h = imagesc(events_buffer);
  spikes = spikes_cell_array{ind};
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
      contexts(cpt_ctx,(1:n_channels)+n_channels*(ind_p-1)) = ...
        events_buffer(ind_p, 1:n_channels);
    end

    delay_to_add = t_ev - max(events_buffer(:));
    % delay_to_add*decay_rate
    % 1-delay_to_add*decay_rate

    events_buffer = (1-delay_to_add*decay_rate) .* events_buffer;
    events_buffer(events_buffer<0) = 0;
    events_buffer(pol, c) = events_buffer(pol, c) + 1;

    % if ind == 1
    %   imagesc(events_buffer)
    %   title(num2str(ind_ev/numel(spikes.ts)))
    %   drawnow;
    % end
    % t_ev
    % events_buffer
    % tau
    % -(t_ev - events_buffer)
    % -(t_ev - events_buffer)/tau
    % exp(-(t_ev - events_buffer) / tau)
%     ind
%     ind_ev
%     spikes.ts(ind_ev)
%     spikes.is_increase(ind_ev)
%     spikes.channel(ind_ev)
% 
% 
%     h.CData = events_buffer;
%     colorbar
%     title(num2str(t_ev))
%     drawnow;
    % pause
  end
end
