function fh = draw_spikes(spikes, fn)

  nb_subp = 3;

  ax1 = subplot(nb_subp,1,1);
  plot(spikes.ts(~spikes.is_increase), 32 - spikes.channel(~spikes.is_increase), '.b', 'MarkerSize', 0.1)
  axis xy;
  hold on;
  plot(spikes.ts(spikes.is_increase),32 -spikes.channel(spikes.is_increase), '.g',  'MarkerSize', 0.1)
  axis xy;
  legend({'OFF', 'ON'})
  ylabel({'Channel (log frequencies)','arbitrary'})
  xlabel('Time (µs) /arbitrary?')
  new_fn = fn(55:end-6);
  title(['Spikegram of ', new_fn], 'interp', 'none')
  colorbar
  hold off;

  ax2 = subplot(nb_subp,1,2);
  padding_x = 1e4; % us
  padding_y = 0.05;
  % max(spikes.channel)
  % double(max(spikes.channel)+ 1)
  % log(double(max(spikes.channel)) + 1)
  % log(double(max(spikes.channel)) + 1)/padding_y
  n_c = ceil(log(double(max(spikes.channel)) + 1)/padding_y)+1;
  n_b = ceil(double(spikes.ts(end))/padding_x);
  n_p = 2;
  mat = zeros(n_c, n_b, n_p);

  for ind = 1:numel(spikes.ts)
    mat(ceil(log(32 - double(spikes.channel(ind)))/padding_y)+1, ceil(double(spikes.ts(ind))/padding_x), spikes.is_increase(ind)+1) = ...
      mat(ceil(log(32 - double(spikes.channel(ind)))/padding_y)+1, ceil(double(spikes.ts(ind))/padding_x), spikes.is_increase(ind)+1) + 1;
  end
  mat = mat(:, 6:end , :);

  imagesc(mat(:,:,2))
  title(['Spectrogram generated with the spikegram of ', new_fn], 'interp', 'none')
  xlabel(['Time * ', num2str(padding_x), ' us /arbitrary?'])
  ylabel({'Channel (linear frequencies)','arbitrary'})
  cb = colorbar;
  ylabel(cb, 'Number of spikes')
  % caxis([10 120])
  axis xy


  ax3 = subplot(nb_subp,1,3);
  [aud, fs] = audioread( fn(1:end-6));
  [s,w,t] = spectrogram(aud, 256, 200, 2^8, fs, 'yaxis');
  imagesc(t, w/1000, 10*log10(abs(s)));
  title(['Spectrogram of ', new_fn], 'interp', 'none')
  xlabel(['Time (s)'])
  ylabel('Channel (kHz)')
  cb = colorbar;
  ylabel(cb, 'Power (arbitrary)')
  axis xy
  title(['Spectrogram of ', new_fn], 'interp', 'none')

  % linkaxes([ax1,ax2,ax3],'xy')
end
