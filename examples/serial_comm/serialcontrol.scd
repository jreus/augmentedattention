//////////////////////////////////////////////////////////////////////////////
// USEFUL DEBUGGING FLAGS //
////////////////////////////
~debugSerial = false; // set to false to not output each time
//~debugSerial = true; // set to true to view all incoming serial data
////////////////////////////////////////////////////////

// Set by changeMode OSC def when the mode selector goes into step 1
~installationRunning = ~installationRunning ? false;

~quakeReleaseTime = ~quakeReleaseTime ? 1.0;

~quakesRunning = Array.fill( 12, { false } );
~receiverDistances = Array.fill( 12, { 0 } );
~currentlyPlaying = -1; // currently playing quake (in Marfa, only one quake plays at a time)
~currentlyPlayingSince = -1;
~maybePlay = -1; // waiting to play this quake if we detect its signal for long enough
~maybePlaySince = -1;

~thresholds = IdentityDictionary.new;

(
~thresholds[ \off ] = 40; // threshhold under which a prox value will be timed to turn off its quake
~thresholds[ \delayTime ] = 2.0;
~thresholds[ \delayTimeOff ] = 5.0; // time a proximity value can be below the off threshhold before its quake can be freed
~thresholds[ \timeBeforeTrigger ] = 1.0; // time a proximity value must be high before triggering

~thresholds[ \timeToOff ] = Array.fill( 12, { -1 } ); // stores times since each prox value has been under the turnoff threshhold, value of -1 means the quake hasn't been triggered

// Threshhold to turn on a quake if no other is playing (0-1023)
~thresholds[ \onIfNone ] = 100; // if no quakes are running turn one on if above 100
~thresholds[ \timeToOn2 ] = Array.fill( 12, { -1 } ); // value for not yet triggered
~thresholds[ \timeToOn2Reset ] = Array.fill( 12, { 0 } ); //
~thresholds[ \maxResetCount ] = 4;

// Threshhold to turn on a quake if another is already playing (0-1023)
~thresholds[ \onIfOther ] = 100; // if no quakes are running turn one on if stronger than this threshold relative to the one playing
~thresholds[ \timeToOn3 ] = Array.fill( 12, { -1 } ); // value for not yet triggered

~thresholds[ \timeOn ] = Array.fill( 12, { -1 } ); // time the quake has been running (set to -1 when it has been turned off)
~thresholds[\loopTime] = 15.0; // time before retriggering a quake, no quake should be longer than this time!!
);

(
~distanceSpec = [ 10, 1023, -4 ].asSpec; // this linearizes the values
~distAmpSpec = [ 0.1, 1.0, -9 ].asSpec;

~distAmpSpecRecv = [ 0.0005, 1.0, -7 ].asSpec;

~getDistAmp = { |dist|
	~distAmpSpec.map( ~distanceSpec.unmap( dist ) );
};

~setSynthAmplitudes = { |dists|
	var players, thisdist, thisamp;
	~quakesRunning.do{ |onoff,id|
		if ( onoff ){ // it is actually running
			players = ~getQuakePlayers.value( id );
			thisdist = dists.at( id );
			thisamp = ~getDistAmp.value( thisdist );
			players.do{ |it|
				it.synthSet( \distAmp, thisamp );
			};
		};
	};
};
);

(
// NEW PARSING ROUTINE WRITTEN FOR MARFA
// Remove multiple quake playback, increase threshhold, single quake at a time
~parseData = {arg data;
	var distances, maxQuake;
	var now = Process.elapsedTime;
	distances = data.collect{ |it| it.asInt }; // parse proximity values for all quakes
	if ( ~debugSerial, { data.size.postln; data.postcs; distances.postcs; });
	~receiverDistances = distances;

	if ( ~installationRunning ){ // only do this when the installation is running
		~checkDistances.value( distances, now );
		//~setSynthAmplitudes.value( distances ); // NOTE: this needs to be changed in favor of a simple trigger
	}{
		// The installation isn't running. Just debug the data we get in
		if ( ~currentMode == 2 ){ // in receiver testing mode only
			"Strongest quake % : %\n".postf( distances.maxIndex, distances.maxItem );
			distances.postln;
			if ( distances.maxItem > 10 ){
				~receiverTest.set( \strongestQuake, distances.maxIndex + 1 );
			}{
				~receiverTest.set( \strongestQuake, 0 );
			};
			~receiverTest.set( \distances2Amps, ~distAmpSpecRecv.map( ~distanceSpec.unmap( distances ) ) );
		}
	};
};


);
(
~stopRunningQuakes = {
	var indicesRunning = ~quakesRunning.selectIndices( { |it| it } );
	indicesRunning.do{ |id|
		~stopQuake.value( id );
		~thresholds[ \timeOn ].put( id, -1 );
		~quakesRunning.put( id, false );
	};
};
);

(


////////////
// SIMPLER CHECK DISTANCES WRITTEN FOR MARFA
////////////
~checkDistances = { |distances, now|
	var maxIndex = -1, maxProximity = -1;
	var indicesRunning, strongestRunning, lasttime;

	// Check if a quake is currently playing, and needs to be stopped.
	if(~currentlyPlaying > -1) { // we have a quake currently playing
		// Is the currently playing quake below our shutoff threshhold and been playing for longer than loopdur? If so, shut it down.

		if(((now - ~currentlyPlayingSince) > ~thresholds[\loopTime]) && (distances[~currentlyPlaying] < ~thresholds[\off])) {
			~log.value("Stopping Quake"+ ~currentlyPlaying + "proximity:" + distances[~currentlyPlaying]);
			~stopQuake.value(~currentlyPlaying); // found in earthquake_waves.scd
			~currentlyPlaying = -1;
			~currentlyPlayingSince = -1;
		};
	};

	// 1: see if any proximity values are higher than our turn-on threshhold
	// if so, and if no other quake is already playing, trigger a new quake as the current one
	//~thresholds[ \onIfOther ]; ~thresholds[ \onIfNone ];
	if(~currentlyPlaying == -1) { // if nothing is playing, go through the proximity values to see one should be triggered
		distances.do{ |dist, id| // go through all distance values, see if one is higher than our threshhold
			if(dist > ~thresholds[\onIfNone]) {
				if(dist > maxProximity) {
					maxIndex = id;
					maxProximity = dist;
				};
			};
		};
		if(maxIndex > -1) { // Check this against maybePlay and maybePlaySince
			~log.value("Maybe playing quake:"+maxIndex);
			if(~maybePlay != maxIndex) {
				~maybePlay = maxIndex;
				~maybePlaySince = now;
			};
		} { // there was no index above threshhold, erase maybeplay values
			~maybePlay = -1;
			~maybePlaySince = -1;
		};

	};

	if((~maybePlay > -1) && ((now - ~maybePlaySince) > ~thresholds[ \timeBeforeTrigger ])) {
		~log.value("Playing quake:"+maxIndex);
		~playQuake.value(~maybePlay);
		~currentlyPlaying = ~maybePlay;
		~currentlyPlayingSince = now;
		~maybePlay = -1;
		~maybePlaySince = -1;
	};

	// If the currentlyPlaying quake has been playing for longer than ~thresholds[\loopTime], retrigger it
	if(~currentlyPlaying > -1) {
		if((now - ~currentlyPlayingSince) > ~thresholds[\loopTime]) { // Quake has been playing longer than loop time
			~log.value("Restarting quake:" + ~currentlyPlaying);
			~stopQuake.value(~currentlyPlaying); // NOTE: maybe not necessary if synths all autofree themselves
			~playQuake.value(~currentlyPlaying);
			~currentlyPlayingSince = now;
		};
	};

};


);