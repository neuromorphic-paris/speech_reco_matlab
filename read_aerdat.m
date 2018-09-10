function spikes = read_aerdat(fn, integrity_check, display_plot)
% READ AERDAT Reads files with cochlear data format
%   [SPIKES] = READ_AERDAT(FILENAME) loads the file which location is
%   according to the FILENAME string.
%   By default, READ_AERDAT return a structure containing information about the
%   spike stream :
%       - Timestamps of each spikes in an uint32, fieldname ts
%       - Filter channel in an uint16, from 0 to 32, fieldname channel
%       - Polarity in an logical, fieldname is_increase.
%
%   [SPIKES] = READ_AERDAT(FILENAME, INTEGRITY_CHECK) checks the integrity (if
%   set to true) of the file, by checking if the timestamps are in ascending %
%   order and the channel is bewteen 0 and 32.
%
%   [SPIKES] = READ_AERDAT(FILENAME, INTEGRITY_CHECK, DISPLAY_PLOT) plots
%   (if true) the stream.

if ~exist('integrity_check', 'var')
  integrity_check = true;
end

if ~exist('display_plot', 'var')
  display_plot = false;
end

f = fopen(fn);
% fseek(f, 0, 'eof');
% n_ev = ftell(f)/6;
% fseek(f, 0, 'bof');
spikes.channel=fread(f,Inf,'*uint16',4,'b'); % can be Inf instead of n_ev
fseek(f,2,'bof');
spikes.ts=fread(f,Inf,'*uint32',2,'b');
fclose(f);

if integrity_check
  cond1 = max(spikes.channel) <= 63;
  cond2 = sum(sign(int64(spikes.ts(2:end))-int64(spikes.ts(1:end-1))) < 0) == 0;
  if ~cond1
    error(['Max channel is ', num2str(max(spikes.channel)), ' on the file ', fn, '.']);
  end
  if ~cond2
    % bad_events = sign(int64(spikes.ts(2:end))-int64(spikes.ts(1:end-1))) < 0;
    %
    % plot(spikes.ts(bad_events), 1, '.r')
    % hold on;
    % plot(spikes.ts(~bad_events), 1, '.g')
    % hold off;
    % pause

    warning(['There are ', num2str(sum(sign(int64(spikes.ts(2:end)) - ...
        int64(spikes.ts(1:end-1))) < 0)), ' events back in time. Fixing...']);
    [spikes.ts, idxsort] = sort(spikes.ts);
    spikes.channel = spikes.channel(idxsort);
  end
end

spikes.ts = spikes.ts/5; % NOTE: to correct hardware behavior
events_channel_on = (mod(spikes.channel, 2) == 0);
spikes.is_increase = false(size(spikes.ts));
spikes.is_increase(events_channel_on) = true;
spikes.channel = (spikes.channel / 2) - 1; % putting it between 0 and max_channel -1

if display_plot
  plot(spikes.ts(~spikes.is_increase), spikes.channel(~spikes.is_increase), '.r')
  hold on;
  plot(spikes.ts(spikes.is_increase), spikes.channel(spikes.is_increase), '.g')
  ylabel('channel')
  xlabel('time in us')
  title(fn, 'interpreter', 'none')
  hold off;
  legend({'OFF', 'ON'})
  grid minor
  drawnow;
end
