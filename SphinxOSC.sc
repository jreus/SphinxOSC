/****************************************************
2018 (C) Jonathan Reus, Algorithms that Matter, IEM Graz

This software is available via the GPLv3 license.

*****************************************************/


/******USAGE**************************
// Default responder just prints out what was received

l.action = {|e, word, phonemes, isSil, ascore, lscore, prob, sframe, eframe, lback|
[word,phonemes,isSil,ascore,lscore,prob,sframe,eframe,lback].postln;
};

TODO: Buffer synchronization between spoken text & recorded audio. For segmentation in SC.
See: experiments/SpeechRecognition_Synthesis.scd

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


*****/


SphinxOSC {
	classvar <pytime, <osctime, <sctime, <tslice, <ustart, <uend; // synchronization variables
	classvar <osc_sync, <osc_tts; // osc listeners from Sphinx
	classvar <>action;
	classvar <>server;
	classvar <writeActive=false, <targetDoc, <writeAt=0, <>writeAction; // rewrite variables

	*initClass {
		action = {|utterance, segments|
			utterance.postln;
			utterance.say("Alex");
			segments.postln;
		};
	}

	// Run SphinxOSC for a given number of seconds
	*run {|run=10, silence_limit=0.3, silence_thresh=500, record_previous=0.2|
		var argstr;
		SphinxOSC.initOSC();
		argstr = "-T" + run;
		argstr = argstr + "-SLIMIT" + silence_limit;
		argstr = argstr + "-STHRESH" + silence_thresh;
		argstr = argstr + "-RPREV" + record_previous;
		("python /Volumes/Store/Drive/DEV/almat/SphinxOSC/sphinxosc.py"+argstr).runInTerminal;
	}

	/*** OSC LISTENERS ***/
	*initOSC {
		if(server.isNil) { server = Server.default };

		// synchronization messages
		osc_sync = OSCdef('sphinxSync', {|msg,time|
			msg.postln;
			pytime = msg[1];
			osctime = time;
			sctime = Process.elapsedTime;
			//tslice = (server.sampleRate * msg[2]).asInt; // previous time slice in seconds, used for buffer sync
		}, '/sphinxOSC/sync');

		// utterance recording & decoding messages
		osc_tts = OSCdef('sphinxData', {|msg,time|
			var ts, start;
			ts = msg[1]; start=msg[2];
			//msg.postln;
			//"Pytime: %".format(ts - pytime).postln;
			//"OSCtime: %".format(time - osctime).postln;
			//"SCtime: %".format(Process.elapsedTime - sctime).postln;

			if(start == 1) { // Utterance started
				//ustart = t.getSynchronous;
			} { // Utterance ended
				var word, phonemes, ascore, lscore, prob, sframe, eframe, lback, isSil = false;
				var utterance = msg[3].asString, rest = msg[4..], segments = List.new, phonetic="";
				(rest.size / 8).do {|i|
					var st = (i*8).asInt;
					segments.add(rest[st..(st+7)]);
					phonetic = phonetic + rest[st].asString;
				};
				action.(utterance, segments);
				if(writeActive) {
					var toprint = utterance.asString;
					targetDoc.string_(toprint, writeAt, 0);
					writeAt = writeAt + toprint.size + 1;
					/*
					segments.do {|seg,i|
						var towrite;
						word = seg[0].asString;
						phonemes = seg[1].asString;
						isSil = (word == "<s>") || (word == "</s>") || (word == "<sil>");
						towrite = writeAction.(word, phonemes, isSil);
						if(towrite[1]) {
							var toprint = towrite[0];
							toprint.postln;
							targetDoc.string_(toprint, writeAt, 0);
							writeAt = writeAt + toprint.size + 1;
						}
					};
					*/
				};
				//uend = t.getSynchronous;
				// Copy utterance into b buffer
				//c.copyData(b, 0, ustart - tslice, tslice + (uend - ustart));
				//[ustart, uend, tslice].postln;

				// TODO: PARSE WORD DATA FROM msg
				//#word, senones, ascore, lscore, prob, sframe, eframe, lback = msg[1..];
				//word = word.asString();
				//isSil = (word == "<s>") || (word == "</s>") || (word == "<sil>");
				//l.action(word,senones,isSil,ascore,lscore,prob,sframe,eframe,lback);
			};
		}, '/sphinxOSC/utterance');

	}

	*writeToDoc {|active=true, startline=0, doc=nil, action=nil|
		writeActive = active;
		if(doc.notNil) { targetDoc = doc };
		if(active) {
			var lrange = targetDoc.getLineRange(startline);
			writeAt = lrange[0];
			if(action.notNil) {
				writeAction = action;
			};
			if(action.isNil && writeAction.isNil) {
				writeAction = {|word, phonemes, isSil| // returns an array with what to print and a bool if to print it
						["AT %: % (%) ".format(writeAt, phonemes, word), true];
				};
			};
		};
	}

}








/****************************************************************************
END SPHINX LINK
END SPHINX LINK
END SPHINX LINK
*****************************************************************************/
