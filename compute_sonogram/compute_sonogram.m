function compute_sonogram(file)

[allAddr, allTs] = loadaerdat(file);

allTs = allTs .*0.2;
allAddr = allAddr + 1;
totalTime = max(allTs) - min(allTs);


%figure()
%plot(allTs, allAddr, '.')


bin_size = 2000; %microseconds
num_channels = 32;

sonogram = zeros(num_channels*2, ceil(totalTime/bin_size));



spikes=zeros(num_channels*2,1);
last_time = allTs(1);

 for t = 1:ceil(totalTime/bin_size)

     %block = squashed(squashed(:,2)<last_time+bin_width & squashed(:,2)>=last_time,:);

     condition = (allTs >= last_time) & (allTs < last_time + bin_size);

     blockTs = allTs(condition);
     blockAddr = allAddr(condition);


     for i=1:size(blockAddr, 1)
     	try
            spikes(blockAddr(i,1))=spikes(blockAddr(i,1))+1;
        catch
            disp('ooops')
        end

     end

	last_time = last_time + bin_size;
    sonogram(:,t) = spikes;
    spikes=zeros(num_channels*2,1);

 end

 figure()
 imagesc(sonogram);
 axis xy

 figure()

 [aud, fs] = audioread( file(1:end-6))   %%Here the wav file with the same name as the AEDAT file should be selected
 %%spectrogram(audioread('c120e80e_nohash_8.wav'),'yaxis');
 spectrogram(aud, 256, 128, 2^8, fs, 'yaxis');
 sound(aud,fs)

% a = dir;
% a = {a.name};
% a = a(3:end);
% for ind = 1:numel(a)
% a{ind}
% [aud, fs] = audioread(a{ind})   %%Here the wav file with the same name as the AEDAT file should be selected
% %%spectrogram(audioread('c120e80e_nohash_8.wav'),'yaxis');
% spectrogram(aud, 256, 128, 2^8, fs, 'yaxis');
% sound(aud,fs)
% title(a{ind}, 'interp', 'none')
% pause
% end
