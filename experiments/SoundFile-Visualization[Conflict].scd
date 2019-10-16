(
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2; s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { if(m.notNil) { m.window.close }; m = s.meter; m.window.alwaysOnTop=true; m.window.front; b = m.window.bounds; l = Window.screenBounds.width - b.width; m.window.bounds = Rect(l, 0, b.width, b.height);
	Syn.load; SampleLib.load(verbose: true);
};
);

/**************************************
USING SC's Built-in SoundFileView
***************************************/
(
if(w.notNil) { w.close };
w = Window.new("SoundFile", Rect(500, 0, 600, 300));
v = SoundFileView.new(w, Rect(0,0,600,280));
f = SampleLib.samples["long-synth-choir_D_major"];
f.load(s, { f.prepPlayback(s, 0, 0, -1) });
v.soundfile = f;
w.alwaysOnTop = true;
v.read(0, f.numFrames);
v.timeCursorOn = true;
v.timeCursorColor = Color.white;
v.timeCursorPosition = 0;
b = Button.new(w, Rect(0, 280, 50, 20));
b.states_([["PLAY"],["PAUSE"]]).action_({|btn|
	if(btn.value == 1) {
		"Play..".postln;
		f.play(s, 0, 1, 0);
	} {
		"Pause..".postln;
		f.pause;
	};
});
a = {
	var busPos;
	loop {
		busPos = f.positionBus.getSynchronous;
		if(busPos.notNil) { v.timeCursorPosition = busPos };
		0.1.wait;
	}
}.fork(AppClock);
w.front;
);

(
Ndef(\blah, {
	var sig;
	sig = Saw.ar(Scale.major.ratios * LFNoise1.ar(1).range(1,2) * 100, mul: 0.1).sum * SinOsc.ar(LFNoise1.ar(2).range(0.01,0.1));
	sig;
}).play(out: 0, numChannels: 1);

);

v.elasticMode = true; // not sure what this does...
v.gridOn = false;
v.gridResolution = 0.01; // in seconds
v.gridColor = Color.blue;
v.gridOn = true;
v.refresh; // sometimes needed to force a redraw

// Zoom is relative
v.zoom(0.2);
v.scroll(0.1); // scroll in viewframes
v.scroll(-0.1); // scroll in viewframes
v.zoom(2.1);
v.zoomToFrac(0.5); // zoom to half file size
v.zoomAllOut; // full view
v.yZoom_(0.5);
v.yZoom_(2.5);

v.drawsWaveForm = false; // toggle drawing waveform
v.drawsWaveForm = true;

// ZOOMING USING MOUSE:
// To zoom in/out: Shift + right-click + mouse-up/down
// To scroll: right-click + mouse-left/right

// You can have multiple selections which can be locked and unlocked...
// let's just play with one for now..
(       // mouseUpAction
v.mouseUpAction = {
	var sel = v.selections[v.currentSelection];
	"selection start frame: %  size: %".format(sel[0], sel[1]).postln;
};
)




/**********************
USINGThor Magnusson's Spectrogram Class
**********************/
Spectrogram
SpectrogramWindow.new
