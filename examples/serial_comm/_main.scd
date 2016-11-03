/*
Serial Input Example

once again, activate UART5 like so
root@bela:~# echo BB-UART5 > /sys/devices/platform/bone_capemgr/slots
check for an active serial port ttyS5
root@bela:~# dmesg | grep ttyS

and even check for incoming serial data
root@bela:~# screen -S serial /dev/ttyS5 115200
root@boot:~# (CTRL-A + D to exit screen)
root@bela:~# screen -X -S serial quit

results:
analog inputs work fine with UART5 enabled.
UART1+5 enabled: inputs still seem to work
UART1+2+5 enabled: inputs still seem to work
As I only really care about UART5 not disabling analog inputs, I'll leave it there. 

analog outputs also work (with UART1+2+5 enabled)


*/

s = Server.default;

// Bela OS/firmware configuration

s.options.numAnalogInChannels = 4;  // number of active analog ins, can be 2, 4 or 8
s.options.numAnalogOutChannels = 4; // number of active analog outs, can be 2, 4 or 8
s.options.numDigitalChannels = 16;  // active digital channels
s.options.maxLogins = 10;            // important so that you can ssh into the bela

s.options.speakerMuted = 1;    // disable the speaker amp

s.options.blockSize = 32; // a low block size causes underruns, pops & clicks, 32 seems manageable..
// larger block size seem to cause instability in the Bela RT thread

s.options.numInputBusChannels = 2;   // only use stereo inputs as audio, the other 8 analog inputs can be used as CTRL signals
s.options.numOutputBusChannels = 2; // number of Audio busses (uses Bela's stereo + 6 analog outputs)

~mypath = "".resolveRelative;

~verboseLoading = 2;

// This function is used throughout the program.
~log = {arg msg, level=1;
	if(~verboseLoading >= level) {
		msg.postln;
	};
};

// Do preprocessing here

// Boot the server & run commands after boot
s.waitForBoot({

	s.sync;
	~log.value("Finished!");

	// Load Serial Parsing Routine
	~log.value("Loading serialparser...");
	(~mypath +/+ "SerialParser.scd").load; // Load the serial parser
	s.sync;
	1.0.wait;
	~log.value("Finished!");

	// ------ AUDIO PATCH ------------
	SynthDef(\main, {|control1=0.5, control2=0.5, control3=0.5, amp=1.0, out=0|
		var mic_in, mic_distorted, fx, main_out;
		var deltime=0.5, decaytime=1.0, wetdry_mix=0.5;
		var distortion=1.0, verbsize=0.5;
		var rate = 1;
		
		distortion = control1 * 30;
		deltime = control2 * 4;
		decaytime = control2 * control3 * 3;
		wetdry_mix = 1 - control3;
		verbsize = min(1.0, (control1 - control3).abs);
		rate = (control1 + control2 + control3) * 6;
		amp = control1 + control2;
		
		mic_in = SoundIn.ar(0);
		mic_in = Saw.ar([1.1,1.5,1.256,2.0,3.0,2.75,4.1,5.75] * (2000 * control3), mul: 0.2).sum * EnvGen.ar(Env.perc(0.001, 0.05), Impulse.ar(rate));
		mic_distorted = (mic_in * distortion).tanh * amp;
		fx = [CombL.ar(mic_distorted, 6.0, deltime, decaytime), CombL.ar(mic_distorted, 6.0, deltime / 1.5, decaytime)];
		fx = FreeVerb.ar(fx, 0.8, verbsize, 0.5);
		main_out = (fx * wetdry_mix) + (mic_distorted * (1 - wetdry_mix)); 
		main_out = Limiter.ar(main_out, 0.96, 0.001);
		Out.ar(out, main_out);
	}).add;
	
	s.sync;
	
	~synth = Synth(\main);
	// ------ END AUDIO PATCH --------


	
	~log.value("Configuring serial control...");
	~parseData = {|data|
		var result = "";
		~synth.set(\control1, data[0].asFloat, \control2, data[1].asFloat, \control3, data[2].asFloat);
	};

	~log.value("Hello World");
});