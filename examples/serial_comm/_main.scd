/*
Serial Input

*/

s = Server.default;

// Bela OS/firmware configuration

s.options.numAnalogInChannels = 8;  // number of active analog ins, can be 2, 4 or 8
s.options.numAnalogOutChannels = 8; // number of active analog outs, can be 2, 4 or 8
s.options.numDigitalChannels = 16;  // active digital channels
s.options.maxLogins = 10;            // important so that you can ssh into the bela

s.options.speakerMuted = 1;    // disable the speaker amp

s.options.blockSize = 32; // a low block size causes underruns, pops & clicks


s.options.numInputBusChannels = 2;   // only use stereo inputs as audio, the other 8 analog inputs can be used as CTRL signals
s.options.numOutputBusChannels = 2; // number of Audio busses (uses Bela's stereo + 6 analog outputs)

~mypath = "".resolveRelative;

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

	~log.value("Loading serialparser...");
	(~mypath +/+ "SerialParser.scd").load; // Load the serial parser
	s.sync;
	2.0.wait;
	~log.value("Finished!");

	~log.value("Loading serial control...");
	(~mypath +/+ "serialcontrol.scd").load; // Load the serial control
	s.sync;
	~log.value("Finished!");

	~log.value("Loading oscdefs...");
	(~mypath +/+ "oscdefs.scd").load; // finally, create the OSCDefs which respond to synths sending data back from the server
	~log.value("DONE!");

	// Let the user know that everything is up and running!
	// Activates and deactivates synths according to the mode select button and active/idle switch.
	~modeSelector.free; // stop the loading display

	// enable mode selection
	~modeSelector = Synth.new( \fancyModeSelector, [
		// 'nodeid1', ~quakeListener.nodeID,
		'nodeid2', ~receiverTest.nodeID,
		'nodeid3', ~quakeCycle.nodeID,
		'nodeid4', ~transducerTest.nodeID,
		'ctrlout', ~resetBus
	], target: ~utilgroup);


	// Play a greeting sound
	~log.value("Hello World");
	Synth.head(s, 'greetingSound', ['f0', 500, 'fmod', 505.9, 'amp', 0.6, 'dur', 5]);

});