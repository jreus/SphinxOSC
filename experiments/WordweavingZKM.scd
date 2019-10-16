/*************************************************************

 (  (             (
 )\))(   '   (    )\ ) (  (     (    )  )  (        (  (
((_)()\ ) (  )(  (()/( )\))(   ))\( /( /(( )\  (    )\))(
_(())\_)())\(()\  ((_)|(_)()\ /((_)(_)|_))((_) )\ )((_))\
\ \((_)/ ((_)((_) _| |_(()((_|_))((_)__)((_|_)_(_/( (()(_)
 \ \/\/ / _ \ '_/ _` |\ V  V / -_) _` \ V /| | ' \)) _` |
  \_/\_/\___/_| \__,_| \_/\_/\___\__,_|\_/ |_|_||_|\__, |
                                                   |___/

Still, the rudest editor is the one that you encounter before a pen even touches the page, right? The one in your mind that says, ‘No, you can’t write that.


Jonathan Reus
Algorithms that Matter, IEM artist in residence

*************************************************************/

"Hello ZKM".say2("Kyoko",out:0,amp:1.0)
(
s.options.numInputBusChannels = 4; s.options.numOutputBusChannels = 4;
s.options.memSize = 65536; s.options.blockSize = 256;
s.waitForBoot { Syn.load; "WordweavingZKM_lang.scd".resolveRelative.load;
x = s.meter.window.alwaysOnTop_(true);
x.bounds_(Rect(1000, x.bounds.height-50 ,x.bounds.width, x.bounds.height));
};
);


("open"+"http://jonathanreus.com").unixCmd;
("open"+"../media".resolveRelative).unixCmd;
("open"+"https://playground.tensorflow.org/").unixCmd;
so are we working
also only wanting
we are careless only want
only when
we are
does he have
to those yeah
the which is as hour
so are there just are
what are you just are
what are you just are
what are you just are
what are you just are
what are you just are
what are you just are
what are you just are
sorry the misuse is easy two itself
sorry that is uses easy
new itself
sorry that it is ah i see
sorry
his heart
c
it is
it is
and
i think it's
they
three
for him
for him
for him
for him
for him
for him
for him
for him
for him
for an enormous them
for an enormous
for
or an adult
okay
or it all and
calling and
calling and








>>tick


>>closer
>>click





SphinxOSC.run(100,0.3,500,0.2);
(
SphinxOSC.writeToDoc(true, 34, Document.current, {|wd,ph,sil| Macro.eval(wd); wd; });
);

(
Tdef('tictoc', {
	var st = 82;
	inf.do {arg i;
		if(i%10 == 0) {
			Macro.evalLine(st+0);
		};
		if(i%2 == 0) {
			Macro.evalLine(st+2);
		};
		if(i%50 == 0) {
			Macro.evalLine(st+4);
		};
		0.1.wait;
	};
}).play(quant: 1, argClock: AppClock);
);




SphinxOSC.run(100,0.3,500,0.2);


SphinxOSC.action = {|utterance, segments|
	utterance = utterance.asString.toLower;
	utterance.postln;
	Macro.eval(utterance);
};





(
Ndef('voice', {
	var sig, in = SoundIn.ar(0) * 0.4;
	sig = in;
	//sig = Vocoder.ar(Saw.ar([120,238,411,802,1020]),in*5,100).sum;
	//sig = Decimator.ar(in, 441000, 16);
	//sig = in + CombL.ar(in, 2, 0.5, 2);
	//sig = sig + [CombL.ar(sig, 2, 0.5, 2),CombL.ar(sig, 2, 0.4, 2)];
	sig = BLowShelf.ar(BPeakEQ.ar(BPeakEQ.ar(BHiShelf.ar(sig, 10000, 1, 0), 4000, 1, 12), 1200, 1, 10), 200, 1, 24);
	//[sig,CombC.ar(sig,0.2,0.001,0)];
	Limiter.ar(LeakDC.ar(sig));
}).play(out:0, numChannels: 2);
);

Ndef('voice').clear(3);

