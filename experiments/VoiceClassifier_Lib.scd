/************************
VOICE CLASSIFIER
VOICE CLASSIFIER
VOICE CLASSIFIER
*************************/

/************************************ NOTES ON FEATURES ****************************

Most speech analysis systems use 13 coefficients + dynamic features.
See:

http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/
https://www.cs.cmu.edu/~robust/Papers/KumarKimSternICA11.pdf
https://www.mathworks.com/help/audio/ref/mfcc.html
https://www.researchgate.net/post/What_would_be_better_features_MFCC_or_MFCC_delta_deltadelta_in_speaker_recogntion

Hanson, Brian, and Ted Applebaum. "Robust speaker-independent word recognition using static, dynamic and acceleration features: Experiments with Lombard and noisy speech." Acoustics, Speech, and Signal Processing, 1990. ICASSP-90., 1990 International Conference on. IEEE, 1990.

Furui, Sadaoki. "Speaker-independent isolated word recognition using dynamic features of speech spectrum." Acoustics, Speech and Signal Processing, IEEE Transactions on 34.1 (1986): 52-59.


************************ NOTES ON DIMENSIONALITY REDUCTION ************************

TODO:: Implement smarter dimensionality reduction such as PCA
ftp://statgen.ncsu.edu/pub/thorne/molevoclass/AtchleyOct19.pdf
https://www.cs.ubc.ca/~nickhar/W12/Lecture6Notes.pdf
https://en.wikipedia.org/wiki/Principal_component_analysis

see also the pc1 method in MathLib

Dimensionality Rediction Methods.

1. Dimensionality reduction by principal component analysis
a.asPoints2 = {};

2. Dimensionality reduction by Gramm-Schmidt method
a.asPoints3 = {};

3. Dimensionaliy reduction using a neural network / autoencoder
a.asPoints4 = {};



**********************************************************************************/



/***************************************
// VOICE CLASSIFIER TODO:
// OPTION 1: Create training set by training and labelling in short batches
// OPTION 2: Continuous, realtime training and labelling.
// OPTION 3: Use librosa to generate a spectral image over a certain window & feed that into a CNN
// OPTION 4: Use difference features of MFCC and Spectrum
// OPTION 5: Use RNN or other time-series analysis
// OPTION 6: Better dimensionality reduction
// 7: window the features into sets / look at dynamic features
This linear classifier has no concept of temporal relationship between features
* try windowing the features into sets
* and feed those into a convolutional NN
* look at dynamic features like MFCC deltas & delta^2

****************************************/

( // RUN ME!
a = ();
a.numfeats = 13;
a.bus.free;

a.init = {
	a.bus = Bus.control(s, a.numfeats);
	"FEATURE VECTOR SEND ON CONTROLBUS %".format(a.bus.index).postln;

	a.mir_synth = Ndef('features', {
		var in, fft, array;
		//in = PlayBuf.ar(1, d, BufRateScale.kr(d), 1, 0, 1);
		in = SoundIn.ar(0);
		fft = FFT(LocalBuf(1024), in);  // for sampling rates 44100 and 48000
		//fft = FFT(LocalBuf(2048), in);  // for sampling rates 88200 and 96000
		array = MFCC.kr(fft, a.numfeats);
		//array.size.postln;
		Out.kr(a.bus, array); // control bus out
		//Out.ar(0, Pan2.ar(in)); // audio bus out
		DC.ar(0);
	}).play(out: 100);

	// View ctrl bus with realtime feature data on it
	a.scope = {
		a.scp = s.scope(numChannels: a.numfeats, index: a.bus.index, rate: \control);
		a.scp.window.name = "RT Features";
	};

	a.initData();
};

a.initData = {|e|
	~t_data = Matrix.newClear(0,a.numfeats);
	~t_labels = List.new;
	~label = 1;
};

// use to capture a number of frames of audio and give it a specific label
// this data is added to the training set ~t_data & ~t_labels
a.captureTraining = {|e, numframes=100, label|
	a.r_trainingDataCapture = Routine({
		var features, st, blocktime;
		blocktime = a.blockTime.();
		st = Process.elapsedTime;
		numframes.do {|i|
			features = a.bus.getnSynchronous(a.numfeats);
			~t_data = ~t_data.addRow(features);
			~t_labels.add(label);
			blocktime.wait;
		};
		"CAPTURED % SAMPLES IN % SECONDS".format(numframes, Process.elapsedTime - st).postln;
	});
	a.r_trainingDataCapture.play(SystemClock);
};

// Capture data samples for arbitrary use. Usually to be classified.
// @param callback is a function that is called when the desired number of samples has been collected
// Returns a Matrix with rows as samples and cols as features
a.captureNSamples = {|e, numsamples=100, callback|
	a.t_collect = Tdef('datacollect', {
		var features, st, blocktime, data;
		blocktime = a.blockTime.();
		data = Matrix.newClear(numsamples, a.numfeats);
		st = Process.elapsedTime;
		numsamples.do {|i|
			features = a.bus.getnSynchronous(a.numfeats);
			data.putRow(i, features);
			blocktime.wait;
		};
		"CAPTURED % SAMPLES IN % SECONDS %".format(numsamples, Process.elapsedTime - st,callback).postln;
		callback.value(data, numsamples);
	});
	a.t_collect.play(SystemClock);
};

// report data and labels
a.report = {|e, data, labels|
	"DATA (%):::\n%".format(data.size, data).postln;
	"LABELS (%):::\n%".format(labels.size, labels).postln;
	e;
};

a.blockTime = { s.options.blockSize / s.sampleRate };

// data array and labels as points, only selects data of a given label
// uses reduce to reduce dimensionality
a.asPoints = {|e, data, labels, label, idx1=0, idx2=1|
	var select;
	select = Matrix.with(data.select({|v,i| labels[i] == label }));
	a.reduce(select, [idx1, idx2]);
};

// dimensionality reduction by simple elimination
a.reduce = {|e, data, indexes|
	data.collectRows {|v,i| v[indexes] };
};


/**** Real-time Training Gui ****/
a.buttonStyle = {|e, char, state|
	var res = [[char, Color.gray, Color.gray(0.2)],[char, Color.gray, Color.gray(0.8)]];
	if(state.notNil) {
		res = [res[state]];
	};
	res;
};

a.makeGui = {|e|
	if(a.win.notNil) { a.win.close };
	a.buts = Array.newClear(2);
	a.win = Window.new("Classifier/Collector/Labeler", Rect(0,0,400,400));
	v = a.win.view;
	v.decorator = FlowLayout(v.bounds, 5@5, 2@2);
	a.buts[0] = Button.new(v, 100@100).states_(a.buttonStyle.($-)).font_(Font("Helvetica",24))
	.mouseDownAction_({|but,x,y| [but,x,y].postln });
	a.buts[1] = Button.new(v, 100@100).states_(a.buttonStyle.($+)).font_(Font("Helvetica",24))
	.mouseDownAction_({|but,x,y| [but,x,y].postln });
	v.keyDownAction_({|but,ch|
		switch(ch,
			$-, { a.buts[0].mouseDown; a.buts[0].states = a.buttonStyle.($-,1) },
			$=, { a.buts[1].mouseDown; a.buts[1].states = a.buttonStyle.($+,1) },
		);
	});
	v.keyUpAction_({|but,ch|
		switch(ch,
			$-, { a.buts[0].mouseUp; a.buts[0].states = a.buttonStyle.($-,0) },
			$=, { a.buts[1].mouseUp; a.buts[1].states = a.buttonStyle.($+,0) },
		);
	});

	a.win.front;
};

);


/************************
END VOICE CLASSIFIER
END VOICE CLASSIFIER
END VOICE CLASSIFIER
*************************/



