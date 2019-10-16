x = Scenes.new.makeGui;
Macros.load;
// Make a Macros gui.. for editing & saving defaults globally & by project
// stored as YAML? or as plain scds

(
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2; s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { if(m.notNil) { m.window.close }; m = s.meter; m.window.alwaysOnTop=true; m.window.front; b = m.window.bounds; l = Window.screenBounds.width - b.width; m.window.bounds = Rect(l, 0, b.width, b.height);
  Syn.load;
};
);


//****************
// GOALS:::
//****************

// #1# Get Macros working
Macros.load;

// #2# Get scenes working
~sc = Scenes.new;
~sc.makeGui;

// #3# Get synthlib working
Syn.gui;

// #4# Develop Sample Library for sorting & editing samples

(
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2; s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { if(m.notNil) { m.window.close }; m = s.meter; m.window.alwaysOnTop=true; m.window.front; b = m.window.bounds; l = Window.screenBounds.width - b.width; m.window.bounds = Rect(l, 0, b.width, b.height);
	Syn.load;
};
);

SampleLib.load(verbose: true);
SampleLib.gui;

a = SampleLib.samples["long-synth-choir_D_major"];
a.load;

//// VISUALIZING A SOUND FILE /////
// See:
Document.open("".resolveRelative +/+ "SoundFile-Visualization.scd")


a = SampleLib.samples["long-synth-choir_D_major"]
a.play(s, 0, 1);
a.load;
x = a.play(s, 0, 1, 0, 1000000);



// SOUND ETUDES 1 //
Macros.load;
(
s.options.numInputBusChannels = 2; s.options.numOutputBusChannels = 2; s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { if(m.notNil) { m.window.close }; m = s.meter; m.window.alwaysOnTop=true; m.window.front; b = m.window.bounds; l = Window.screenBounds.width - b.width; m.window.bounds = Rect(l, 0, b.width, b.height);
  Syn.load;
  Macros.load;
  SampleLib.load(verbose: true);
  SampleLib.gui;

};
);


// Various gestures.... could use a macro / library system for these...
// important to think about gestures & silence... end fight scene between Ford & other guy in Bladerunner

// 1.0 Render sample to code window using trigger button in the sample browser

>>lsnd/2
Macros.parseStr = "@";
@lsnd/2
@lsnd/2*
@lsnd/1
a = { @nsnd/1 };
a.value



t=TempoClock;
t.sched(0.5, a);
b = { @lsnd/2 ; t.sched(0.8, c) };
c = { @lsnd/3 ; t.sched(0.4, a) };
a = { @lsnd/1 ; t.sched(0.7, b) };
a.value;

// NEXT: get a bit more flexible with multiple macros in a single line by discovering what combinations
// of commands are most valuable... scheduling, and other such things...

@lsnd/BassEAnodyne1
@lsnd/BassEAnodyne2

>0.5>%gesture
>0.2>&sample

