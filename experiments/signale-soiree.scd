/********
/Signale Soiree/IEM
 (                               (
 )\ )                   (        )\ )
(()/((  (  (          ) )\  (   (()/(    (  (     (   (
 /(_))\ )\))( (    ( /(((_)))\   /(_)) ( )\ )(   ))\ ))\
(_))((_|(_))\ )\ ) )(_))_ /((_) (_))   )((_|()\ /((_)((_)
/ __|(_)(()(_)(_/(((_)_| (_))   / __| ((_|_)((_|_))(_))
\__ \| / _` | ' \)) _` | / -_)  \__ \/ _ \ | '_/ -_) -_)
|___/|_\__, |_||_|\__,_|_\___|  |___/\___/_|_| \___\___|
       |___/
*********/



// VoicePlot


(
Ndef('whr', {
	var s1,s2,s3,s4,sig;
	var freqs, bws;
	freqs = \fr.kr([120,400,1200,4500], 0.5);
	bws = \bw.kr([0.1,0.1,0.1,0.1], 0.5);
	//sig = BrownNoise.ar;
	sig = Saw.ar((Scale.major.ratios) * \freq.kr(300)).sum;

	sig = (sig*10).tanh * 0.5;

	s1 = BBandPass.ar(sig, freqs[0], bws[0], mul:1);
	s2 = BBandPass.ar(sig, freqs[1], bws[1], mul:1);
	s3 = BBandPass.ar(sig, freqs[2], bws[2], mul:1);
	s4 = BBandPass.ar(sig, freqs[3], bws[3], mul:1);
	sig = Mix([s1,s2,s3,s4]);
	sig = sig * 0.2;
	sig = GVerb.ar(sig, 200, 1.3, 0.4, 0.5, 40, 1, 0.2, 0.2);
	sig = Limiter.ar(LeakDC.ar(sig * \amp.kr(1.0,0.1)),1, 0.001);
	sig;
}).play(out: 0, numChannels: 2);
);



Ndef('whr').set(\fr,[230,340,560,2000],\amp,0.2);

// Simple translation into sound
(
l.action = {|e,word,phonemes,isSil|
	phonemes.postln;
	if(isSil) {
		//Ndef('whr').set(\amp,0.01);
		//word.postln;
	} {
		//var f1,b1,f2,b2,f3,b3,f4,b4;
		var freq,freqs, bws;
		freqs = List.new; bws = List.new;
		//phonemes.postln;
		phonemes = phonemes.asString.split($ );
		phonemes.do {|phon,i|
			var param = phon.ascii.sum * 10;
			if(i==0) {
				freq = phon.ascii.sum * 5;
			} {
			if(i%2 == 1) {
				freqs.add(param * (i+1))
			} {
				bws.add(param / (4000*(i+1)));
			}
			};
		};
		Ndef('whr').set(\freq, freq, \fr,freqs,\bw,bws);
	};
};
)


l.runSphinx;

"HH".ascii.sum * 2

Ndef.clear(1);

// Sonification of memory-making
("".resolveRelative ++ "VoiceClassifier_Lib.scd").load;

