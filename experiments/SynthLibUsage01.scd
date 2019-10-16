>>start

a = SynthLibrary.load; // uses default library path to load all discovered synthdefs

a.path; // library path

a.inspect; // browse file paths of various synthdefs

a.browseSynths; // uses the extensions to SynthDescLib defined in SynthDescLibPlusGUI

(
c = SynthDef('rez', {
		var sig = Resonz.ar(Saw.ar([400,5000,300, 560]/2).sum, [400,500,800] * XLine.ar(1,2,0.5), 0.1, mul: 1.0);
		Splay.ar(sig) * EnvGen.ar(Env.linen(0.5,0.5), doneAction: 2, timeScale: 2);
});
)


// Lots of useful info inside SynthDescLib and SynthDesc!
z = SynthDescLib.global.synthDescs['syn'];
z.name;
z.controls;
z.controlDict;
z.controlNames;
z.outputs;
z.inputs;
z.hasGate;
z.canFreeSynth;
z.outputData;
z.msgFunc.postcs;
z.makeGui; // this is especially cool

// Probably what I want to do is have a custom parsing of synth files that logs their filename
// as well as other metadata (examples/presets and comments?)

