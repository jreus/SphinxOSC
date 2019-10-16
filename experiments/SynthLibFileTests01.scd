/****************************************
BASIC USAGE TESTS
*****************************************/

>>start
a = Synthe.load; // uses default library path to load all discovered synthdefs
a.path; // library path
a.gui; // browse file paths of various synthdefs
a.browseSynths; // uses the extensions to SynthDescLib defined in SynthDescLibPlusGUI

a.count;
a.names;
a.types;


// Todos...
// Make some nice synths. Be able to add / change in place. :-)
// make some real-time vocal synths and see how those can integrate / be tested & activated from the synth browser..


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
























/************************************
SYNTHDEF FILE PARSING EXPERIMENTS
 Most of this code can be found, cleaned up, inside the load methods of SynthLibrary / Synths
*************************************/

// Probably what I want to do is have a custom parsing of synth files that logs their filename
// as well as other metadata (examples/presets and comments?)

// How to parse the synthdef files?
~path = "~/../Drive/DEV/SC_Synthesis/".asAbsolutePath +/+ "SynthDefs"; // put your synthdef library path here
~files = List();
~allsynthfiles = ( ~path +/+ "*").pathMatch;
~allsynthfiles.do{|fp|
			// Parse each synth file...
			// Needs to do more than just compile file! But actually compile each synthdef
			// while logging additional data...
	var data, parsed;
	data = File.readAllString(fp);
	parsed = data.

			//thisProcess.interpreter.compileFile(p).value;
			~files.add(PathName.new(p).fileName)
};

(
~str1 = "
/*************************************************
@synth
@shortdesc Lowpass SyncSaw
@desc SyncSaw with Lowpass Filter
@types Subtractive, Filtered
*/
SynthDef('s1', {arg freq=400, sync=300, out, pan=0, amp=0.5, dur=1, co1=4000, co2=800, rq=0.5;
	var sig;
	sig = (SyncSaw.ar(freq + {LFNoise0.ar(10).range(-10.0,10.0)}!10, sync)*0.1).sum;
	sig = sig * EnvGen.ar(Env.perc, timeScale: dur, doneAction: 2);
	sig = BLowPass4.ar(sig, XLine.ar(co1, co2, dur / 2), rq);
	Out.ar(out, Pan2.ar(sig,pan) * amp);
}).add;

/*************************************************
@synth
@shortdesc A Simple SyncSaw
@desc Another simple Subtractive Sawtooth synth
@types Subtractive, Sawtooth
*/
SynthDef('s2', {arg freq=400, sync=300, out, pan=0, amp=0.5, dur=1, co=4000, rq=0.5;
	var sig;
	sig = SyncSaw.ar(freq, sync);
	sig = sig * EnvGen.ar(Env.perc, timeScale: dur, doneAction: 2);
	sig = RLPF.ar(sig, co, rq);
	Out.ar(out, Pan2.ar(sig,pan) * amp);
}).add;
";
);

(
r = ~str.findAll("@synth"); // find synth def locations
r.do {arg idx;
	var res;
	res = ~str.findRegexpAt("@synth[.]+@type",idx);
	[res,idx].postln;
};

);

(
~str2 = "
/*************************************************
@synth
@shortdesc s2
@desc Another simple Subtractive Sawtooth synth
@types Subtractive
*/
SynthDef('s2', {arg freq=400, sync=300, out, pan=0, amp=0.5, dur=1, co=4000, rq=0.5;
	var sig;
	sig = SyncSaw.ar(freq, sync);
	sig = sig * EnvGen.ar(Env.perc, timeScale: dur, doneAction: 2);
	sig = RLPF.ar(sig, co, rq);
	Out.ar(out, Pan2.ar(sig,pan) * amp);
}).add;
";
);

q = ~str2.findRegexp("@synth(.+)/");
q[0]; // found it, so long as there are no forward slashes in the description.


q = ~str2.findRegexp("SynthDef(.+)\.add\;");
q[0]; // found it!


// Find critical keywords
(
~str1 = "
/*************************************************
@synth
@shortdesc Lowpass SyncSaw
@desc SyncSaw with Lowpass Filter
@types Subtractive, Filtered
*/
SynthDef('s1', {arg freq=400, sync=300, out, pan=0, amp=0.5, dur=1, co1=4000, co2=800, rq=0.5;
	var sig;
	sig = (SyncSaw.ar(freq + {LFNoise0.ar(10).range(-10.0,10.0)}!10, sync)*0.1).sum;
	sig = sig * EnvGen.ar(Env.perc, timeScale: dur, doneAction: 2);
	sig = BLowPass4.ar(sig, XLine.ar(co1, co2, dur / 2), rq);
	Out.ar(out, Pan2.ar(sig,pan) * amp);
}).add;

/*************************************************
@synth
@shortdesc A Simple SyncSaw
@desc Another simple Subtractive Sawtooth synth
@types Subtractive, Sawtooth
*/
SynthDef('s2', {arg freq=400, sync=300, out, pan=0, amp=0.5, dur=1, co=4000, rq=0.5;
	var sig;
	sig = SyncSaw.ar(freq, sync);
	sig = sig * EnvGen.ar(Env.perc, timeScale: dur, doneAction: 2);
	sig = RLPF.ar(sig, co, rq);
	Out.ar(out, Pan2.ar(sig,pan) * amp);
}).add;
";




~synthinfo = Dictionary.new;

b = ~str1.findAllRegexp("@synth");
m = ~str1.findAllRegexp("SynthDef");
e = ~str1.findAllRegexp("\.add;");
e = e + 4;

// a few simple syntax error checks
r = b.size == m.size && m.size == e.size; // same number of @synth, SynthDef and .add; strings found.
// check order in text makes sequential sense
b.size.do {arg idx;
	t = true;
	if ((b[idx] > m[idx]) || (m[idx] > e[idx])) {
		t = false;
	};
};

if(r.not || t.not) {
	error("Syntax error in SynthDef, @synth tags and SynthDefs do not match.")
} { // Parse the synthdefs
	b.size.do {arg idx;
		var meta, def, name, synthdesc, info;
		meta = ~str1[b[idx]..(m[idx]-5)];
		def = ~str1[m[idx]..e[idx]];
		// Get the name
		name = def.findRegexp("SynthDef[(]['\]([A-Za-z0-9_]+)[']?")[1][1].asSymbol;
		def.interpret; // interpret Synthdef & create SynthDesc, throws an error if the server is not running
		synthdesc = SynthDescLib.global.synthDescs[name];
		info = SynthInfo.new(synthdesc);
		info.parseDocString(meta);
		~synthinfo[name] = info;
	};
};

);

~synthinfo[\s1].desc;
~synthinfo[\s1].shortdesc;
~synthinfo[\s1].name;




// EXPERIMENTS

~str1[m[0]..e[0]];

// Get the name
~str1[m[0]..e[0]].findRegexp("SynthDef[(]['\]([A-Za-z0-9_]+)[']?");


~str1[m[0]..e[0]].asCompileString;

~str1[m[0]..e[0]].newTextWindow;

~str1[m[0]..e[0]].newTextWindow;

~str1[m[0]..e[0]].interpret;
z = SynthDescLib.global.synthDescs['s1']; // there it is...

y = ~str1[b[0]..(m[0]-5)].split($\@)[2..];

y.do {arg item;
	var key, val;
	item.findRegexp("");
};

y[2].findRegexp("^([A-Za-z0-9_]+) ([A-Za-z0-9 \t\r\n!\"\#$%&`()*\-,:;<=>?\[\\\]^_{|}~]+)")