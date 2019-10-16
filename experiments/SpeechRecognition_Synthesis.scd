
/**************
// USAGE

TODO: SYNCHRONIZE AUDIO IN SC & SPHINX
Making an infinite speech loop... between the recognizer and synthesizer...
***************/
(
s.options.numInputBusChannels = 10; s.options.numOutputBusChannels = 10;
s.options.memSize = 8192 * 2 * 2 * 2 * 2; s.options.blockSize = 64 * 2 * 2 * 2;
s.waitForBoot {
	c = Buffer.alloc(s, s.sampleRate * 5, 1);
	b = Buffer.alloc(s, s.sampleRate * 3, 1);
	t = Bus.control(s, 1); };
);

(
Ndef('tape', {
	var sig, in, r_head;
	in = SoundIn.ar(0);
	//RecordBuf.ar(in, b, run: 1, trigger: \rec.tr, loop:0);
	r_head = Phasor.ar(0, BufRateScale.kr(c), 0, BufFrames.kr(c));
	Out.kr(t, r_head);
	BufWr.ar(in, c, r_head, 1);
	sig = PlayBuf.ar(1, b, 1, 1, loop: 1);
	Pan2.ar(sig, 0, \amp.kr(1.0));
}).play(out:0, numChannels: 2);
);

Ndef.clear(3);

l.runSphinx(10, 1.0, 500, 0.2);

(
"var sig, in, r_head;
	in = SoundIn.ar(0);
	sig = PlayBuf.ar(1, b, 1, 1, loop: 1);
Pan2.ar(sig, 0, \amp.kr(1.0));".say("Joana")
);


y = ~spk.("O que é uma distância? Quantas dimensões tem um movimento? A máquina está se movendo.", voice: "Joana", out: 90, rate: 1.0, wpm: 120);
y = ~spk.("What is a distance? How many dimensions does a movement have? The machine is in movement.", voice: "Luca", out: 0, rate: 1.0, wpm: 120);
y.buf; // must wait a bit for the speech to finish writing to disk & loading buf

(
Ndef('fx', {
	var in, s1,s2,s3, sig;
	var pos, buf, bdur;
	in = In.ar(90, 2);
	buf = y.buf;
	bdur = BufDur.kr(buf);
	pos = LFNoise0.ar(10).range(0, bdur);
	//pos = SinOsc.ar(0.01).range(0, bdur);
	pos = LFSaw.ar(0.1).range(0,bdur);
	s1 = TGrains.ar(2, Impulse.ar(20), buf, 1, pos, 0.1, LFNoise0.ar(50).range(-1,1), 1.0);
	s1 = s1 + PitchShift.ar(s1, 0.2, 0.5, 0, 0, mul: 2.0) + PitchShift.ar(s1, 0.2, [1.5,2.0,2.5], 0, 0, mul: 0.1).sum;
	sig = in.sum + s1;
	//sig = in.sum;
	sig = GVerb.ar(sig, 4, 0.1) * 0.6;
	Limiter.ar(sig,1,0.001);
}).play(out:0, numChannels: 2);
);

s.meter
Say.voiceNames
[1,2,3,4].say("Joana")
[1,2,3,4].say("Kyoko")
[1,2,3,4].say("Kyoko")

(type:\say,text:"1 2 3 4",voice:"Alex").play
(type:\say,text:"1 2 3 4",voice:"Alex",rate:180).play



(
// TODO:
// How can I more quickly assemble sound material using my synth lib...? Rather than write this out...?
Ndef('moddro', {|ratemod=0.2|
	var sin,s1,s2,s3,sig = SinOsc.ar(SinOsc.ar(LFSaw.ar(LFNoise2.ar(0.1 * ratemod).range(0.01,30 * ratemod)).range(Scale.major.ratios * 100,Scale.minor.ratios * 6120 * ratemod)).range(Scale.major.ratios * 100,12000 * ratemod)) * SinOsc.ar(10 * ratemod);
	sig = (sig.sum*2).tanh;
	sin = SoundIn.ar([4,5]);
	sig = BLowPass4.ar(sig, 16200, 0.5) * EnvGen.ar(Env.perc, gate: Impulse.ar(8 * ratemod), timeScale: LFNoise1.ar(5).range(0.01,0.1));
	s1 = EnvGen.ar(Env.perc, gate: Impulse.ar([0.75,1.00].choose * ratemod), timeScale: 0.1) * BrownNoise.ar();
	s1 = s1 + [CombL.ar(s1, 3, 0.12, 1), CombL.ar(s1, 3, 0.13, 2)];
	sig = GVerb.ar(sig, 30, 1.0, 0.1, 0.1, 10);
	sig = sig*0.1 + s1*4;
	sig = sig.tanh;
	sig = Limiter.ar(LeakDC.ar(sig),1,0.001);
	Out.ar(0, sig*0.5);
	(sig + sin*0.8) * 0.5;
}).play(out: 4, numChannels: 2);

);


(// Voice
Ndef('vox', {
	var s1,s2,s3,s4,sig;
	s1 = SoundIn.ar(0);
	s2 = SoundIn.ar([4,5]);
	sig = s1 + (s2*0.1);
	Limiter.ar(LeakDC.ar(Pan2.ar(sig)),1,0.001);
}).play(out: 4, numChannels: 2);

);

Ndef.clear(3);



/*********************************************************
Commands as Code / Compositional Strategy
Rewriting... or moreso classifying utterances into various kinds of code commands.
> vocal transformation
> harmonic patterns
> synthesis / modulation
**********************************************************/


/*********************************************************
Voice Features
Speech Synthesis
Yaakov J Stein
Tel Aviv University
I'll limit my comments to features, as I can't recommend specific programs (although pretty much everything has open source code available nowadays). The basic features that are used for speech synthesis, having been inspired by a simple model of biological speech generation) are the LPC coefficients. They have many forms, and can be converted via linear transformations into other feature sets such as PARCORs and LSFs. These features model the state of the vocal tract. There are modified versions, such as mel or bark transformed LPCs, and various mechanisms to make the features more robust. Obviously spectral information, such as can be obtained by pitch and format tracking, can be useful. Unfortunately, it is harder to accurately obtain, and often harder to use. Once again, it is often used on a mel or bark scale.
The cepstral coefficients are a great tool for speech analysis. A particular variety - the LPC cepstrum, is known to have a useful property, namely that the Euclidean distance in LPC cepstrum space is highly correlated with the Itakura-Saito distance. LPC ceptral coefficients are frequently used in both speech and speaker recognition. There are acousto-phonetic features that are very useful in research (and perhaps out-perform other feature sets), but tend to be rather voluminous for practical application. Finally, a newer approach is not to extract arbitrary features at all, but to learn which features are optimal for a given task (e.g., using deep neural networks).
Y(J)S
**********************************************************/