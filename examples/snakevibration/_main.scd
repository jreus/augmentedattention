/*******************
Snake Vibration, translates microphone input to skin transducer output.

AnalogIn returns a value from 0-1

.ar (analogPin: 0, mul: 1, add: 0)

analogPin:  Analog pin number to read. Pin numbers begin at 0. This value can be modulated at audiorate.

(c) 2019: Jonathan Reus
*/

s = Server.default;

s.options.numAnalogInChannels = 2; // can only be 2, 4 or 8
s.options.numAnalogOutChannels = 2;
s.options.numDigitalChannels = 0;
s.options.maxLogins = 16;  	   // set max number of clients

s.options.blockSize = 16;
s.options.numInputBusChannels = 4;
s.options.numOutputBusChannels = 4;

s.waitForBoot{
	"Server Booted".postln;

  r = {
    var mic, amp, outsig;
    //mic = In.ar(0,2);
    mic = SoundIn.ar([0,1]);
    amp = Amplitude.kr(mic, 0.01, 0.01);
    amp.poll(1);
    outsig = Limiter.ar(mic * 10);
    //outsig = SinOsc.ar([200, 300]) * 0.2;
    Out.ar(0, outsig);
  }.play(outbus: 0);

};

