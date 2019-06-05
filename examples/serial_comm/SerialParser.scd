/***************************************************************************************

Serial Parsing

Reads incoming serial packets from a reciever unit on UART5. The serial packets are formatted:
1,1,1,1,1,1,1,1,1,1,1,1,\n
with each number representing a signal intensity value of one of the transmitters (0-1023).
The serial packet is sent as plain ascii.


(C) 2019 Jonathan Reus

********************************************

Notes:
SuperCollider's SerialPort implementation is rather slow and heavily dependent on the speed of sclang (an issue on the Bela especially).
A more reliable alternative could be to use a C++ or Python process for reading Serial Data in, cooking it, and sending it to SC.

****************************************************************************************/


"Available Serial Devices: ".postln;
SerialPort.devices.postln;

~dev = SerialPort.devices[5]; // set device here /dev/ttyS5 is UART5 on the Bela
~dev = "/dev/ttyS5";

~ser = SerialPort.new(~dev, baudrate: 115200, databits: 8, stopbit: 1, parity: nil, crtscts: true); // BeagleBoneBlack default UART settings
~ser.doneAction = { "Serial Port Got Closed".postln; ~ser_r.stop; };


(
"Starting Serial Parsing Thread on ".post; ~dev.postln;
~parseData = {|data|
	var result = "";
	12.do {|i|
		// Do something with the data here!
		result = result + i ++ ":" + data[i];
	};
	result.postln;
};

~ser_pause = 0.1;

~ser_r = {
	var byte, str, data, lost = false, lastdata = Process.elapsedTime;
	str = "";
	inf.do{|i|
	// .next is a non-blocking read; .read is a blocking read
		while { byte = ~ser.next; byte.isNil; } {
			0.025.wait; // this is a very slow serial parsing speed, but should be ok since the RX unit only sends value packets 4 times per second
			// if((lost == false) && ((Process.elapsedTime - lastdata) > 2)) {
			if( Process.elapsedTime - lastdata > 2 ) { // we need a repeat of the 0 message for the other routines
				// if radio receiver is not receiving anything because it is too far away from transmitters, it will not send data over serial, so we need to do something when nothing has been received for 2 seconds.
				~parseData.value(0!12);
				lastdata = Process.elapsedTime;
				//lost = true;
			};
		};
		lost = false;
		lastdata = Process.elapsedTime; // set this each time we have read data

		if(byte != 10) { // Until reaching \n
			str = str ++ byte.asAscii;
		} { // \n found, end of packet
			// str.postln;
			if(str.size < 62) { // ignore lines that are longer than "1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,"
				data = str.split($,);
				// data.postln;
				(data.size == 13).if {
					~parseData.value(data.copyRange(0,11));
				};
			};
			//str.postln; // uncomment to view incoming serial packets
			str = ""; // reset str for next data packet
			~ser_pause.wait; // uncomment this line to slow down serial reading
		};
		0.001.wait; // just a little wait here between bytes
	};
}.fork;

);

/*
~ser_r.stop;
~ser.close;
*/

