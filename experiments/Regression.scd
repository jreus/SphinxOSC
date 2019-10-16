/******
Regression

(C) Jonathan Reus CC-SA


*******/




//*****
// Linear Regression
//*****



(
r = SimpleLinearRegression.new(0.1, 0.1);

n = 100;
x = Array.series(n, 0, 1.0 / n) + Array.fill(n, {rrand(-0.15, 0.15)});
y = Array.series(n, 0, 1.0 / n) + Array.fill(n, {rrand(-0.15, 0.15)});
p = x.collect {|item,i| [item, y[i]] };
a = Array.series(n, 0, 1.0 / n) + Array.fill(n, {rrand(-0.15, 0.15)});
b = Array.series(n, 0, 1.0 / n).reverse + Array.fill(n, {rrand(-0.15, 0.15)});
q = a.collect {|item,i| [item, b[i]] };

w = Window.new("X Scatter", Rect(0,0, 800, 600));
j = ScatterPlotter.new(w, 800@600, p, [0,1.0].asSpec, [0,1.0].asSpec);
j.drawMethod_(\fillOval).symbolSize_(5@5).symbolColor_(Color.magenta);
j.addPlot(q);
j.addPlot([[-0.1, r.predict(-0.1)],[1.0, r.predict(1.0)]]);
j.backgroundColor_(Color.white).axisColor_(Color.gray);
j.symbolColor_(Color.gray(0.0),1);
j.symbolColor_(Color.red,2).drawMethod_(\lineTo,2).symbolSize_(1,2);
j.drawAxes_(true);
w.front;
);

(
r.callback = {arg model, error;
	var line = [[-0.1, model.predict(-0.1)],[1.0, model.predict(1.0)]];
	{
		j.data_(line,2); // update the plot
	}.fork(AppClock);
};
);

r.train(x, y, 1000, 0.04, 0.05);



(
Ndef('reg', {arg freq=50,  modhz=8, mult=1.02, fmodhz=1, amp=1.0;
	var sig;
	sig = Saw.ar(Array.geom(30, 1.0, mult) * freq, mul: 0.1).sum;
	sig = BLowPass4.ar(sig, LFTri.ar(SinOsc.ar(fmodhz).range(1,20)).range(500,6700), 0.5);// + (sig*0.1);
	sig = (sig*2).tanh;

	//sig = GVerb.ar(sig, 100, 2, 0.0, 0.0, 25, 1, 0.5, 0.5);
	sig = CombL.ar(sig, 1, 0.05, 2) + sig;
	sig = (sig*2).tanh;
	sig = Pan2.ar(sig,0,SinOsc.ar(modhz)) * amp * 1.0;
	sig = Limiter.ar(LeakDC.ar(sig), 1, 0.001);
}).play(out: 0, numChannels: 2);
);


Ndef.clear(5);

r.train(a, b, 5000, 0.05, 0.05);

// reset the model
(
r.m_term = rrand(-10.0, 10.0);
r.b_term = rrand(-10.0, 10.0);
);

// change the callback
(
r.callback = {arg model, error;
	var line = [[-0.1, model.predict(-0.1)],[1.0, model.predict(1.0)]];
	{
		j.data_(line,2); // update the plot
		Ndef('reg').set(\freq, (model.m_term.abs * 170) + 30, \modhz, (model.b_term.abs+0.01), \mult, 1.0 + (min(1.0,error) / 20), \fmodhz, error*3 );
	}.fork(AppClock);
};

);

// change the dataset
(
n = 100;
x = Array.series(n, 0.0, 1.0 / n) + Array.fill(n, {rrand(-0.0, 0.0)});
y = Array.series(n, 1.0, -1.0 / n) + Array.fill(n, {rrand(-0.0, 0.45)});
//~xdata = Array.fill(~dp, {rrand(0.0, 1.0)});
//~ydata = Array.fill(~dp, {rrand(0.0, 1.0)});
p = x.collect {|item,i| [item, y[i]] };
j.data_(p);
);






// TODO:
/*
Be able to change the delaytime in realtime
Be able to change the training data in realtime
XdoneX be able to start/stop a training/modelling process...

Group Perceptron & LinearRegression to extend a class for training as an interactive process..

*/


