// Special Commands
/* 1. wordweaving...
* recollection / repeated retrieval
* open system / the kind of writing that enables creativity and thought
* palimpsest
* memory & forgetting
* speech, voice and storytelling / voice analysis & recognition

Developing a compositional system, a toolkit, and an artistic method for live performance.
*/

// 2. tape machine & destabilizing learning processes

// 3. storytelling through livecoding, erasing, writing, rewriting, multistability


(
Macro.addMacro('zeno',">>closer",{
{
		var sig = Resonz.ar(Saw.ar([400,5000,300, 760]/3).sum, [400,500,800] * XLine.ar(1,2,0.5), 0.1, mul: 1.0);
		Splay.ar(sig) * EnvGen.ar(Env.linen(0.5,0.5), doneAction: 2, timeScale: 2);
}.play;
});

Macro.addMacro('closer',">>and",{
{
		var sig = Resonz.ar(Saw.ar([400,5000,300, 560]/4).sum, [400,500,800] * XLine.ar(1,2,0.5), 0.1, mul: 1.0);
		Splay.ar(sig) * EnvGen.ar(Env.linen(0.5,0.5), doneAction: 2, timeScale: 2);
}.play;
});

Macro.addMacro('and',">>closer.",{
{
		var sig = Resonz.ar(Saw.ar([400,5000,300, 1200]/3.5).sum, [400,500,800] * XLine.ar(1,2,0.5), 0.1, mul: 1.0);
		Splay.ar(sig) * EnvGen.ar(Env.linen(0.5,0.5), doneAction: 2, timeScale: 2);
}.play;
});

Macro.addMacro('closer.',">>zeno",{
{
		var sig = Resonz.ar(Saw.ar([230,400,3000,300]/3.75).sum, [400,500,1800] * XLine.ar(1,1,0.5), 0.1, mul: 1.0);
		Splay.ar(sig) * EnvGen.ar(Env.linen(0.5,0.5), doneAction: 2, timeScale: 2);
}.play;
});

Macro.addMacro('distance',">>tortoise",{
{
	var sig = Saw.ar(Saw.ar([30,40,500,170]).range(30,400));
	Splay.ar(sig) * EnvGen.ar(Env.perc, timeScale: 2, doneAction: 2) * 0.6;
}.play;
});


Macro.addMacro('tortoise',">>distance",{
{
	var sig = Saw.ar(Saw.ar([3,40,50,17]/2).range(50,2000));
	Splay.ar(sig) * EnvGen.ar(Env.perc, timeScale: 5, doneAction: 2) * 0.6;
}.play;
});

Macro.addMacro('what',">>pop",{
{
	var sig = Saw.ar(Saw.ar([30,40,500,170]).range(30,400));
	Splay.ar(sig) * EnvGen.ar(Env.perc, timeScale: 0.3, doneAction: 2) * 0.6;
}.play;
});

Macro.addMacro('language',">>what",{
{
	var sig = Saw.ar(Saw.ar([3,40,50,17]/2).range(50,2000));
	Splay.ar(sig) * EnvGen.ar(Env.perc, timeScale: 0.3, doneAction: 2) * 0.6;
}.play;
});



Macro.addMacro('tock', ">>tick", {
{
	var sig = Resonz.ar(Impulse.ar(0.1), [209,388,399,400,1211,800,6000,8200,9000] / 2.211, 0.1, mul: 300.0);
	Splay.ar(sig) * EnvGen.ar(Env.perc(0.001,0.05), doneAction: 2);
}.play;
});

Macro.addMacro('tick', ">>tock", {
{
	var sig = Resonz.ar(Impulse.ar(0.1), [209,388,399,400,1211,800,6000,8200,9000] / 1.2, 0.1, mul: 300.0);
	Splay.ar(sig) * EnvGen.ar(Env.perc(0.001,0.05), doneAction: 2);
}.play;
});

Macro.addMacro('click', ">>pop", {
{arg out, pan=0, amp=1.0;
	var sig = Resonz.ar(PinkNoise.ar, [209,388,399,400,1211,800] * 10, 0.1, mul: 100.0);
	sig = sig.sum * EnvGen.ar(Env.perc(0.001,0.001), doneAction: 2);
	Pan2.ar(sig, pan, amp);
}.play;
});

Macro.addMacro('pop', ">>click", {
{arg out, pan=0, amp=1.0;
	var sig = Resonz.ar(Impulse.ar(0.1), [209,388,399,400,1211,800,6000,8200,9000] / 10, 0.5, mul: 300.0);
	sig = sig.sum * EnvGen.ar(Env.perc(0.0001,0.005), doneAction: 2);
	Pan2.ar(sig, pan, amp);
}.play;
});

Macro.addMacro('littlebird', nil, {
	s.scope(2);
});


);




