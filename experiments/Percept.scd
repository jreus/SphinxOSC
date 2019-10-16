/******
Percept

(C) Jonathan Reus CC-SA

*******/

(
s.options.numInputBusChannels = 10; s.options.numOutputBusChannels = 10;
s.options.memSize = 65536; s.options.blockSize = 256;
s.waitForBoot { Syn.load };
);

(
r = Perceptron.new(2);
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


(
Ndef('per', {|freq=1440, fscale=1.0, foffset=0.0, dscale=1.0, amp=1.0, pulserate=0.15, co=5400,modhz=10.2|
	var sig, s2, freqs, amps, rtimes, met1;
	freqs = (Scale.major.ratios ++ Scale.minor.ratios/2) * freq;
	amps = {rrand(0.1,1.0)}.dup(freqs.size);
	rtimes = {rrand(0.1,2.0)}.dup(freqs.size);
	sig = Impulse.ar(pulserate);
	met1 = Impulse.ar(0.2);
	s2 = EnvGen.ar(Env.linen(0.01,1-0.02,0.01), met1, timeScale: 0.03) * SinOsc.ar([2000,4000,5000,6000,9000,8790, 11078, 12000, 13400], mul: 0.2).sum;
	//sig = BrownNoise.ar(0.1);
	sig = DynKlank.ar(`[freqs, amps, rtimes], sig, fscale, foffset, dscale);
	sig = BLowPass4.ar(sig, 14000, 0.8);
	//sig = sig.sigmoid;
	sig = sig.tanh;
	sig = sig + PitchShift.ar(sig, 0.2, 0.25, 0.01, 0.01);
	sig = sig * SinOsc.ar(modhz).unipolar * amp;
	s2 = GVerb.ar(s2, /*50*/50, 5, 0.5, 0.5, 25, 1, 0.6, 0.6);
	sig = GVerb.ar(sig, /*5*/4, 0.4, 0.1, 0.1, 25, 1, 0.6, 0.6) * amp;
	sig = Pan2.ar(sig[0] * SinOsc.ar(16).unipolar, SinOsc.ar(0.3)) + Pan2.ar(sig[1] * SinOsc.ar(13).unipolar, 1-SinOsc.ar(0.3));
	sig = BLowPass4.ar(sig, co, 0.5);
	sig = Mix([sig,s2]);
	amp = Line.ar(0,1.0, 5);
	sig = sig * amp;
	sig = Limiter.ar(LeakDC.ar(sig), 1.0, 0.001);
	//Pan2.ar(sig, 0, amp);
}).play(out:0, numChannels: 2);
)

Ndef('per').clear(5);


// change the callback
(
r.callback = {arg model, error;
	var slope, intercept, line;
	#slope,intercept = model.decisionBoundary();
	line = [[0.0, intercept],[1.0, slope+intercept]];
	{
		j.data_(line,2).symbolSize_((error*10)**2 + 0.5,2); // update the plot
		Ndef('per').set(\freq, (model.weights[0].abs * 500) + 50, \fscale, (model.weights.sum.abs * 0.5 + 0.1), \dscale, 0.1 + (min(7.0,error * 20)), \co, (error*4000)+1500, \pulserate, (error*100)+0.15);
	}.fork(AppClock);
};

);


r.train(a++b, l, 3000, 0.0005, 0.05);



// change the dataset
(
//n = 200; // does the scatterplot have difficulty plotting so many?

n = 50;
// make two clusters
a = Array.fill(n, {|i| [0.5.sum3rand + 0.5.rand, 0.8.sum3rand + 0.1]});
b = Array.fill(n, {|i| [0.3.sum3rand + 1, 0.8.sum3rand + 0.9]});
l = Array.fill(n*2, {|i| if(i >= n) {1} {0}}); // labels

j.data_(a, 0);
j.data_(b, 1);
r.train(a++b, l, 10000, 0.01, 0.05);
);

r.train(a++b, l, 10000, 2.5, 0.01);

r.train(a++b, l, 10000, 0.001, 0.05);
r.stop;


r.stop;
r.resume


( // change weights
r.weights = [rrand(-5.0,2.0), rrand(-2.0,4.0)];
r.bias = rrand(-20.0,20.0);
);

r.train(a++b, l, 10, 0.5, 0.01);
r.train(a++b, l, 100, 0.01, 0.01);



Ndef('per').gui

j.backgroundColor_(Color.black).drawAxes_(false);
j.symbolSize_(30,2).symbolColor_(Color.yellow,2);
j.symbolColor_(Color.new(1.0, 0.5, 0.5),0).symbolSize_(4@4,0).symbolColor_(Color.gray(0.85),1).symbolSize_(2@2,1);

Ndef.clear(10);






/********************************************************
*******************************************************
TEST: TRAINING WITH NON NORMALIZED DATASETS...
*******************************************************
*******************************************************/

(
r = Perceptron.new(2);
d = 400@400;
n = 100;
// make two clusters
a = Array.fill(n, {|i| var x = 0.8.sum3rand - 0.2;  [x, 0.3.sum3rand - 0.2]});
b = Array.fill(n, {|i| var x = 0.7.sum3rand+0.1;  [x, 0.5.sum3rand]});
l = Array.fill(n*2, {|i| if(i >= n) {1} {0}}); // labels

w = Window.new("Binary Cloud", Rect(1600, 0, d.x, d.y));
j = ScatterPlotter.new(w, (d.x)@(d.y), a, [-1.2,1.1].asSpec, [-1.01,1.32].asSpec);
j.drawMethod_(\fillOval).symbolSize_(5@5).symbolColor_(Color.green);
j.drawAxes_(true);
j.addPlot(b);
j.backgroundColor_(Color.white).axisColor_(Color.gray);
j.symbolColor_(Color.gray(0.0),1);
#p,i = r.decisionBoundary;
j.addPlot([[0, i],[1.0, p+i]]);
j.symbolColor_(Color.red,2).drawMethod_(\lineTo,2).symbolSize_(1,2);
w.front;
);


// change the callback
(
r.callback = {arg model, error;
	var slope, intercept, line;
	#slope,intercept = model.decisionBoundary();
	line = [[-2.0, -2*slope+intercept],[2.0, 2*slope+intercept]];
	{ j.data_(line,2).symbolSize_((error*10)**2 + 0.5,2);	}.fork(AppClock);
};
);


r.train(a++b, l, 300, 0.0005, 0.05);





// change the dataset
(
//n = 200; // does the scatterplot have difficulty plotting so many?

n = 50;
// make two clusters
a = Array.fill(n, {|i| [0.5.sum3rand + 0.5.rand, 0.8.sum3rand + 0.1]});
b = Array.fill(n, {|i| [0.3.sum3rand + 1, 0.8.sum3rand + 0.9]});
l = Array.fill(n*2, {|i| if(i >= n) {1} {0}}); // labels

j.data_(a, 0);
j.data_(b, 1);
r.train(a++b, l, 10000, 0.01, 0.05);
);

r.train(a++b, l, 10000, 2.5, 0.01);

r.train(a++b, l, 10000, 0.001, 0.05);
r.stop;


r.stop;
r.resume


( // change weights
r.weights = [rrand(-5.0,2.0), rrand(-2.0,4.0)];
r.bias = rrand(-20.0,20.0);
);

r.train(a++b, l, 10, 0.5, 0.01);
r.train(a++b, l, 100, 0.01, 0.01);



Ndef('per').gui

j.backgroundColor_(Color.black).drawAxes_(false);
j.symbolSize_(30,2).symbolColor_(Color.yellow,2);
j.symbolColor_(Color.new(1.0, 0.5, 0.5),0).symbolSize_(4@4,0).symbolColor_(Color.gray(0.85),1).symbolSize_(2@2,1);

Ndef.clear(10);