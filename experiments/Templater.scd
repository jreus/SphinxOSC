// Pattern experiments...

// can you do this?

(
Ndef('testp',
	Pbind(*[
		dur: 0.2,
		ctranspose: 0,
		midinote: Pseq([62,65,69,67] + [[0,5]],inf)
	])
);
);

(
Ndef('ahp', {
	var sig = Ndef('testp');
	sig = (sig*10).tanh * 0.4;
	sig = BBandPass.ar(sig, 5200, 1.2);
	sig = GVerb.ar(sig, 20, 0.5, 0.5);
});
);

(
Ndef('mix', {
	var mix;
	mix = Ndef('ahp');
	mix = Limiter.ar(LeakDC.ar(mix), 1, 0.001);
	mix = mix * 0.2;
}).play(out: 0, numChannels: 2);
);


Ndef('mix').clear(5);

