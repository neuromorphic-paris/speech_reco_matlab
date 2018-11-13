function [events] = synthetic_aer_gen()
  [samples, fs] = audioread(make_sinus, 'native');
   events = AEGen(samples, fs)
end
