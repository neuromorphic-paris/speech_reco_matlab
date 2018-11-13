function mat = unspikify(spikes, padding)

if ~exist('padding', 'var')
  padding = 4e3; % us
end

n_c = double(max(spikes.channel)) + 1;
n_b = ceil(double(spikes.ts(end))/padding);
n_p = 2;
mat = zeros(n_c, n_b, n_p);

for ind = 1:numel(spikes.ts)
  mat(spikes.channel(ind) + 1, ceil(double(spikes.ts(ind))/padding), spikes.is_increase(ind)+1) = ...
    mat(spikes.channel(ind) + 1, ceil(double(spikes.ts(ind))/padding), spikes.is_increase(ind)+1) + 1;
end
mat = mat(:, 6:end , :);

figure(3)
subplot(211)
imagesc(mat(:,:,1))
title('OFF polarity')
xlabel(['Time * ', num2str(padding), ' us'])
ylabel('Channel')
colorbar
axis xy

subplot(212)
imagesc(mat(:,:,2))
title('ON polarity')
xlabel(['Time * ', num2str(padding), ' us'])
ylabel('Channel')
colorbar
axis xy
