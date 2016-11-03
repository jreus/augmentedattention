/***************************************************************************************

Serial Parsing

Reads incoming serial packets from a reciever unit on UART5. The serial packets are formatted:
0.001,0.001,0.001\n
with each number representing an XYZ euler angle from an IMU unit
The serial packet is sent as plain ascii and is \n terminated.


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

"Serial Port Devices: %".format(SerialPort.devices).postln;

~ser = SerialPort.new(~dev, baudrate: 115200, databits: 8, stopbit: 1, parity: nil, crtscts: true); // BeagleBoneBlack default UART settings
~ser.doneAction = { "Serial Port Got Closed".postln; ~ser_r.stop; };


(
"Starting Serial Parsing Thread on ".post; ~dev.postln;

// The default parseData function just posts the incoming data. 
// Overwrite this function to do something more interesting
~parseData = {|data|
	var result = "";
	3.do {|i|
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
		while { byte = ~ser.next; byte.isNil; } { // wait for the next byte
			0.025.wait; // this is a very slow serial parsing speed, but should be ok since the RX unit only sends value packets 4 times per second
		};
		lost = false;
		lastdata = Process.elapsedTime; // set this each time we have read data

		if(byte != 10) { // Until reaching \n
			str = str ++ byte.asAscii;
		} { // \n found, end of packet
			if(str.size < 62) { // ignore lines that are unusually long due to parsing errors
				data = str.split($,);
				(data.size == 3).if {
					~parseData.value(data);
				};
			};
			//str.postln; // uncomment to view incoming serial packets
			str = ""; // reset str for next data packet
			//~ser_pause.wait; // uncomment this line to slow down serial reading
		};
		0.001.wait; // just a little wait here between bytes
	};
}.fork;

);

/*
~ser_r.stop;
~ser.close;
*/

