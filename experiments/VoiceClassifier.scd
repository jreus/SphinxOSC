// pseudo classes & functions
Document.open("".resolveRelative +/+ "VoiceClassifier_Lib.scd");

/**********
// USAGE
***********/
(
~libfp = "".resolveRelative +/+ "VoiceClassifier_Lib.scd";
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2;
s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { ~libfp.load; Syn.load; s.meter; a.init; a.scope; };
);

// initialize and Capture some labeled data for Training
a.captureTraining(100, 0); // capture 100 samples labled for each of two classes
a.captureTraining(100, 1);
a.report(~t_data, ~t_labels);
//a.makeGui();


// Plot the training data
( // Plot the training data
var aspoints, dim = 500@400;
var domain, range;
domain = [~t_data.collect({|vec| vec.minItem }).minItem, ~t_data.collect({|vec| vec.maxItem }).maxItem].asSpec;
domain.postln;
w = Window("Voice Features Plots", dim);
j = ScatterPlotter.new(w, dim, a.asPoints(~t_data,~t_labels,0)).setAxes(domain, domain);
j.drawAxes_(true).drawGrid_(true).drawGridValues_(true).gridResolution_(5@5).drawMethod_(\fillOval).symbolSize_(4@4);
j.addPlot(a.asPoints(~t_data,~t_labels,1));
w.front;
~xdim=0; ~ydim=0;
);


( // Change the dimensions plotted to see if any plots are linearly separable
~ydim = ~ydim + 1;
if(~ydim == a.numfeats) {
	~ydim = 0; ~xdim = ~xdim + 1;
	if(~xdim == a.numfeats) { ~xdim = 0 };
};

~xcol = ~t_data.getCol(~xdim);
~ycol = ~t_data.getCol(~ydim);
"Xdim: % [% %]\nYdim: % [% %]".format(
	~xdim, ~xcol.minItem.round(0.0001), ~xcol.maxItem.round(0.0001),
	~ydim, ~ycol.minItem.round(0.0001), ~ycol.maxItem.round(0.0001)
).postln;

j.data_(a.asPoints(~t_data, ~t_labels, 0, ~xdim, ~ydim ), 0);
j.data_(a.asPoints(~t_data, ~t_labels, 1, ~xdim, ~ydim ), 1);

j.setAxesLabels("DIM"+~xdim,"DIM"+~ydim);
);


// FEATURE SCALING & STANDARDIZATION
// TODO: Cleanup & Encapsulate this a bit...
~dReduced = a.reduce(~t_data, [~xdim, ~ydim]); // Simple Dimensionality Reduction

( // feature scaling of reduced dataset
var mean, stdev, dim, min, max;
var s1,s2,s3,s4;
var normalizeSample, denormalizeSample, standardizeSample, destandardizeSample;
~dReduced = Matrix.newFrom(~dReduced);
dim = ~dReduced.cols;
mean = Array.newClear(dim);
stdev = Array.newClear(dim);
~min = Array.newClear(dim);
~max = Array.newClear(dim);

~normalizeSample = {|v,min,max| (v - min) / (max - min) };
~denormalizeSample = {|v,min,max| (v * (max-min)) + min };
~denormalizeLine = {|line,min,max|
	var p1,p2, new_m, new_b, m=line[0], b=line[1];
	// calculate two normalized samples & denormalize them
	p1 = [-1,(-1 * m)+b]; p2 = [1,(1 * m)+b];
	p1 = ~denormalizeSample.(p1, min, max);
	p2 = ~denormalizeSample.(p2, min, max);
	// calculate denormalized decision boundary
	new_m = (p2[1]-p1[1]) / (p2[0]-p1[0]); // slope
	new_b = p1[1] - (new_m*p1[0]); // y-intercept
	[new_m,new_b];
};

~standardizeSample = {|v,mean,stddev| (v-mean) / stddev };
~destandardizeSample = {|v,mean,stddev| (v*stddev) + mean };


// TO NORMALIZE:
// find min / max of features
// normalized_value = (val - min) / (max - min)
~dNormal = Matrix.newClear(~dReduced.rows, ~Reduced.cols);

dim.do {|i|
	var col = ~dReduced.getCol(i);
	~min[i] = col.minItem;
	~max[i] = col.maxItem;
	~dNormal.putCol(i, ~normalizeSample.(col, ~min[i], ~max[i]) );
};

"MIN: %   MAX: %".format(~min, ~max).postln;


s1 = [-0.09, 1.45];
s2 = ~normalizeSample.(s1, ~min, ~max);
s3 = ~denormalizeSample.(s2, ~min, ~max);
"NEW SAMPLE: %   NORMALIZED: %  DENORMALIZED: %".format(s1,s2,s3).postln;



// TO STANDARDIZE:
// calculate mean and standard deviation of each feature
// subtract mean from each feature
// divide features by standard deviation

~dStandard = Matrix.newClear(~dReduced.rows, dim);
dim.do {|i|
	var col = ~dReduced.getCol(i);
	mean[i] = col.mean;
	stdev[i] = col.stdDev(mean[i]);
	~dStandard.putCol(i, ~standardizeSample.(col, mean[i], stdev[i]));
};
"MEAN: %   STDDEV: %".format(mean, stdev).postln;
s1 = [-0.09, 1.45];
s2 = ~standardizeSample.(s1, mean, stdev);
s3 = ~destandardizeSample.(s2, mean, stdev);
"NEW SAMPLE: %   STANDARDIZED: %  DESTANDARDIZED: %".format(s1,s2,s3).postln;

); // END SCALING & STANDARDIZATION OF FEATURES



//*********************
// TRAIN THE MODEL
//*********************
~model = Perceptron.new(2);

// add a plot for the line
~db = ~model.decisionBoundary;
~db = ~denormalizeLine.(~db, ~min, ~max);
j.addPlot([[0,~db[1]],[1,~db[0]+~db[1]]]).drawMethod_(\lineTo,2).symbolColor_(Color.red).symbolSize_(1,2);


(
~model.callback = {|model,error,ep|
	var p1,p2,db,m,b;
	db=model.decisionBoundary; // normalized [slope,intercept]
	#m,b = ~denormalizeLine.(db,~min,~max);
	p1 = [-2,(-2 * m)+b];
	p2 = [2,(2 * m)+b];
	{ j.data_([p1,p2],2).symbolSize_((error*10)**2 + 0.5,2) }.fork(AppClock);
};
);

// Train the model
~model.train(~dNormal, ~t_labels, 10000, 1.1, 0.05); // high learning rate
~model.train(~dNormal, ~t_labels, 10000, 0.001, 0.05); // low learning rate
~model.stop;
~model.randomize; // TODO: Implement this, to randomize the weights...


// TODO::: Make functionality to capture more data points
// use the classifier to classify them and place them somewhere in realtime...

// Capture an unclassified vocal blob...
a.captureNSamples(100, {|data,i| ~newdata = data });
~newdata; // full 13 features

// Dimensionality Reduce & Normalize the new data
/* TODO
encapsulate these behaviors ~ e.g. data transforms with memory: normalize, PCA..
transformations that transform/inverse-transform data based on an initial dataset
include batch normalization / denormalization of entire matrix..
and to normalize new data according to the normalizer's trained min/max and so on..
*/

~newReduced = a.reduce(~newdata, [~xdim, ~ydim]);
~newNormal = ~newReduced.collectRows {|row| ~normalizeSample.(row, ~min, ~max) };
j.addPlot(~newNormal); // plot 4, for new datapoints

/*********************************************
 CLASSIFICATIONS OF THE NEW VOCAL UTTERANCE
**********************************************/
// classify all points
~newLabels = ~newNormal.collect {|sample| ~model.classify(sample) };

// classify utterance by feature centroid
~centroid = [~newNormal.getCol(0).mean, ~newNormal.getCol(1).mean];
~model.classify(~centroid);
// calculate a classification percentage: 100%/0% -> full confidence in class 1/0
~newLabels.mean;



~utterances = List.new;
( // add a new utterance to the plot
a.captureNSamples(100, {|data,i|
	var utterance, normalized, labels, plot;
	normalized = a.reduce(data, [~xdim, ~ydim]);
	"..2 % %".format(data.shape, normalized.shape).postln;
	normalized = normalized.collectRows {|row| ~normalizeSample.(row, ~min, ~max) };
	labels = normalized.collect {|sample| ~model.classify(sample) };
	{ j.addPlot(data) }.fork(AppClock);
	utterance = [data, normalized, labels];
	~utterances.add(utterance);
});

);

// Look at the percentage classifiers of each utterance...
~utterances.collect {|utt| utt[2].mean }

( // Sonified utterance classifier
a.captureNSamples(100, {|data,i|
	var utterance, normalized, labels, mean;
	normalized = a.reduce(data, [~xdim, ~ydim]);
	normalized = normalized.collectRows {|row| ~normalizeSample.(row, ~min, ~max) };
	labels = normalized.collect {|sample| ~model.classify(sample) };
	mean = labels.mean;
	mean.postln;
	if(mean > 0.5) {
		{
			Pan2.ar(SinOsc.ar(255 * mean * SinOsc.ar(LFNoise2.ar(5).range(3,500)).range(0.5,4.0))
				* EnvGen.ar(Env.perc, timeScale:0.1, doneAction: 2) *0.4, -0.5)
		}.play;
	} {
		{
			Pan2.ar(Saw.ar(1255 * SinOsc.ar(LFNoise2.ar(5).range(3,500)).range(0.5 + mean,4.0))
				* EnvGen.ar(Env.perc, timeScale:0.1, doneAction: 2) *0.4, 0.5)
		}.play;

	};
});

);


// Full feature classifier
a.init();
~model2 = Perceptron.new(a.numfeats);
a.captureTraining(100, 0);
a.captureTraining(100, 1);
~t_data.shape;
~t_labels.size;

~tNormal = ~normalize


// ***** UNPROCESSED EXPERIMENTS ***** //



/* FEATURE SCALING / STANDARDIZATION vs SIMPLE NORMALIZATION:
https://www.datacamp.com/community/tutorials/preprocessing-in-data-science-part-2-centering-scaling-and-logistic-regression
https://en.wikipedia.org/wiki/Feature_scaling
https://machinelearningmastery.com/scale-machine-learning-data-scratch-python/
https://stats.stackexchange.com/questions/121886/when-should-i-apply-feature-scaling-for-my-data

The general method of calculation is to determine the distribution mean and standard deviation for each feature. Next we subtract the mean from each feature. Then we divide the values (mean is already subtracted) of each feature by its standard deviation.

x ′ = x − x ¯ σ {\displaystyle x'={\frac {x-{\bar {x}}}{\sigma }}} x' = \frac{x - \bar{x}}{\sigma}

Where x {\displaystyle x} x is the original feature vector, x ¯ = average ( x ) {\displaystyle {\bar {x}}={\text{average}}(x)} {\displaystyle {\bar {x}}={\text{average}}(x)} is the mean of that feature vector, and σ {\displaystyle \sigma } \sigma is its standard deviation.

While normalization simply scales all features to be in [0,1], based on some knowledge of minimum and maximum values of features. Standardization centers all values around 0 and distributes the data with a standard deviation of 1.

Standardization is a rescaling technique that refers to centering the distribution of the data on the value 0 and the standard deviation to the value 1. It requires that the mean and standard deviation of the values for each column be known prior to scaling. As with normalizing above, we can estimate these values from training data, or use domain knowledge to specify their values.

When to Standardize vs Normalize?
Standardization is a scaling technique that assumes your data conforms to a normal distribution. If a given data attribute is normal or close to normal, this is probably the scaling method to use.

It is good practice to record the summary statistics used in the standardization process, so that you can apply them when standardizing data in the future that you may want to use with your model.

Normalization is a scaling technique that does not assume any specific distribution.

If your data is not normally distributed, consider normalizing it prior to applying your machine learning algorithm.

It is good practice to record the minimum and maximum values for each column used in the normalization process, again, in case you need to normalize new data in the future to be used with your model.

*/















( // Classify new utterances
var plink = { SinOsc.ar(7440 * Scale.chromatic.ratios) * 0.1 * EnvGen.ar(Env.perc, timeScale: 0.1, doneAction: 2) };

plink.play;

Tdef('classify', {
	100.do {

	};
});

);

~model.predict([0.0,0.0])

Tdef('classify').play;






// Place vocal utterances into the cartesian graph...


(
r = SimpleLinearClassifier.new(2);
d = 800@800;
n = 100;
// make two clusters
a = Array.fill(n, {|i| var x = 0.5.sum3rand + 0.5;  [x, rrand(0.0, max(0.0,x-0.1))]});
b = Array.fill(n, {|i| var x = 0.5.sum3rand + 0.5;  [x, rrand(min(1.0,x+0.1), 1.0)]});

l = Array.fill(n*2, {|i| if(i >= n) {1} {0}}); // labels

w = Window.new("Binary Cloud", Rect(1600, 0, d.x, d.y));
j = ScatterPlotter.new(w, (d.x)@(d.y), a, [0,1.0].asSpec, [0,1.0].asSpec);
j.drawMethod_(\fillOval).symbolSize_(5@5).symbolColor_(Color.green);
j.drawAxes_(true);
j.addPlot(b);
j.backgroundColor_(Color.white).axisColor_(Color.gray);
j.symbolColor_(Color.gray(0.0),1);
#p,i = r.decisionBoundary;
j.addPlot([[0.0, i],[1.0, p+i]]);
j.symbolColor_(Color.red,2).drawMethod_(\lineTo,2).symbolSize_(1,2);
w.front;
);


c = r.train(a++b, l, 3000, 0.0005, 0.05);




