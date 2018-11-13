function fn = make_sinus()

amp = 0.7;
freq = 200; %Hz
duration = 1; %sec
nb_harmonics = 5;
fs = 44100; %Hz

t = (1:fs)/fs;
vec = zeros(size(t));
for ii = 1:nb_harmonics
    vec = vec + sin(2*pi*freq*(2*ii-1)*t)/(2*ii-1);
end
vec = vec*amp;

% plot(t,vec)
% axis([0 0.02 -1 1])
sound(vec,fs);
fn = ['sinewaves_', num2str(nb_harmonics), '_harmonics_', num2str(freq), '_hz.wav'];
audiowrite(fn, vec, fs);
