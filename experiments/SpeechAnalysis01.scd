(
s.options.device = "Fireface UCX (23590637)";
s.options.numInputBusChannels = 10;
s.options.numOutputBusChannels = 10;
s.options.memSize = 8192 * 2 * 2 * 2;
s.waitForBoot {
};
);


// Working with MFCC coefficients..

b = Bus.control(s, 13);

(
Ndef(\mfcc, {arg freq=400;
	var in, fft, mfcc, sig;
	in = SoundIn.ar(0);
	fft = FFT(LocalBuf(1024), in); // works with sampling rates 44100/48000 - should be 2048 for higher sr

	mfcc = MFCC.kr(fft);

	mfcc.size.postln;

	sig = LFTri.ar(freq * Array.geom(12, 100, 1.01) * mfcc[6] * mfcc[9] / 2) * mfcc / 1.7;
	sig = SplayAz.ar(4, sig);
	Out.kr(b, mfcc);
	sig * mfcc[1] * mfcc[4];
}).play(out: 0, numChannels: 4);

);

Ndef(\mfcc).clear(1);

b.getnSynchronous(13);

s.scope(13, b.index, rate: \control);

(
Tdef(\post, {
	inf.do {arg i;
		b.getnSynchronous(13).postln;
		0.1.wait;
	};
});
);

Tdef(\post).play;
Tdef(\post).stop;



// Receiving OSC from an external analyser..
NetAddr.localAddr; // 57120
(
OSCdef(\sr, {arg msg;
	msg.postln;

}, "/sr");
);





