/*******************
All Outputs

Plays a sequence of sounds through the stereo headphone outputs followed by all the outputs of the Wearable Capelet.

(c) 2019: Jonathan Reus
*/

s = Server.default;

s.options.numAnalogInChannels = 8; // can only be 2, 4 or 8
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 0;
s.options.maxLogins = 16;  	   // set max number of clients

s.options.blockSize = 16;
s.options.numInputBusChannels = 8;
s.options.numOutputBusChannels = 10;

(
s.waitForBoot{
	"Server Booted".postln;
	SynthDef(\blip, {|out=0, freq=440|
    var sig;
    sig = Blip.ar(freq, 30) * EnvGen.ar(Env.perc, doneAction: 2);
    Out.ar(out, sig);
	}).add;

	s.sync;

  r={
    inf.do {|i|
      var cnt = i%8;
      cnt.postln;
      Synth(\blip, [\out, cnt, \freq, (cnt+1) * 60]);
      1.wait;
    };
  }.fork;

};
);

//r.stop;