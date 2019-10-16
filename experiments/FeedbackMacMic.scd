/*
 ________ _______   _______   ________  ________  ________  ________  ___  __
|\  _____\\  ___ \ |\  ___ \ |\   ___ \|\   __  \|\   __  \|\   ____\|\  \|\  \
\ \  \__/\ \   __/|\ \   __/|\ \  \_|\ \ \  \|\ /\ \  \|\  \ \  \___|\ \  \/  /|_
 \ \   __\\ \  \_|/_\ \  \_|/_\ \  \ \\ \ \   __  \ \   __  \ \  \    \ \   ___  \
  \ \  \_| \ \  \_|\ \ \  \_|\ \ \  \_\\ \ \  \|\  \ \  \ \  \ \  \____\ \  \\ \  \
   \ \__\   \ \_______\ \_______\ \_______\ \_______\ \__\ \__\ \_______\ \__\\ \__\
    \|__|    \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|_______|\|__| \|__|



 _____ ______   ________  ________  _____ ______   ___  ________
|\   _ \  _   \|\   __  \|\   ____\|\   _ \  _   \|\  \|\   ____\
\ \  \\\__\ \  \ \  \|\  \ \  \___|\ \  \\\__\ \  \ \  \ \  \___|
 \ \  \\|__| \  \ \   __  \ \  \    \ \  \\|__| \  \ \  \ \  \
  \ \  \    \ \  \ \  \ \  \ \  \____\ \  \    \ \  \ \  \ \  \____
   \ \__\    \ \__\ \__\ \__\ \_______\ \__\    \ \__\ \__\ \_______\
    \|__|     \|__|\|__|\|__|\|_______|\|__|     \|__|\|__|\|_______|

2018 Jonathan Reus
Cafe Wolf, Graz AT

*/

(
// use built-in macbook microphone as input device
// use PA system as output device
s.options.inDevice = "Built-in Microph";
s.options.numWireBufs = 512;
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2;
s.options.memSize = 65536; s.options.blockSize = 256;
s.waitForBoot { Syn.load; w=s.meter.window; w.bounds = Rect(1200,0, 134,230) };
);



(
Ndef('mix', {|input=30|
    var mic, sig, mix, master=1.0, dt1, dt2, k1,k2;
    mic = SoundIn.ar(0) * 0.1;

	k1 = KeyState.kr(SSKey.codesByKey['comma'], 0, 1, 0);
	k2 = KeyState.kr(SSKey.codesByKey['period'], 0, 1, 0);
	dt1 = Select.kr(k1, [0.06, 0.1]);
	dt2 = Select.kr(k2, [0.05, 0.22]);


	mic = [CombL.ar(mic, 3, dt1, 0.2), CombL.ar(mic, 3, dt2, 1.5)];
    sig = InFeedback.ar(30, 2);

	mix = Mix([sig,mic]);
	//mix = sig;
	mix = Limiter.ar(mix, 0.4, 0.001);
    mix = LeakDC.ar(mix);
	mix * master * 0.6;
}).play(out: 0, numChannels: 2);
);




(
Ndef('filter_ctl', {arg amp=1.0;
    var sig;
	var k1, k2;
	var pan, amod, co, cf=260, rq=0.2;
	pan = MouseY.kr(-1.0, 1.0);
	amod = MouseY.kr(1, 200);
	co = MouseX.kr(40, 12000, -2);

	cf = MouseX.kr(60, 64, lag: 0).round(1.0).midicps;

	k1 = KeyState.kr(SSKey.codesByKey['w'], 1.0, 0.0, 1); // simple envelope

	amp = amp * k1;


	sig = Saw.ar(cf*[1,4.4,1.1,0.2,0.5,0.8,3.2,2.3,5.6]) * SinOsc.ar(amod);
	sig = (Splay.ar(sig,1,1) * amp).tanh;
	(sig * 10).tanh;
	sig = BLowPass4.ar(sig, co, rq);
	sig;
	Pan2.ar(sig.sum,pan,amp);
}).play(out: 30);
);

Ndef.clear(5);



Ndef.clear(10);
Ndef('filter_ctl').clear(10);


