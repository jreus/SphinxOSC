// Load synthdefs from Library Directory
~path = "~/../Drive/DEV/SC_Synthesis/SynthDefs/".asAbsolutePath;
~fileNames = List();
~synthPaths = ( ~path +/+ "*").pathMatch;
~synthPaths.do{|p|
	thisProcess.interpreter.compileFile(p).value;
	~fileNames.add(PathName.new(p).fileName)
};

~fileNames; // All the names of files in the synth library that have been compiled

~synthdefNames = List();

SynthDescLib.global.synthDescs.do {arg syn;
	if( syn.name.containsStringAt(0, "system_").not) {
		~synthdefNames.add(syn.name);
	};
};

~synthdefNames; // Names of all loaded synthdefs / synthdescs

// Parsing a file for metadata
~filePath = ~path +/+ ~fileNames[0];

// Open scd file for reading.
(
~synthdefs = Dictionary.new;
f = File.use(~filePath, "r", {arg scd;
	var line, tmp, param, synthdef, types;
	while{line = scd.getLine(); line.notNil;} {
		if(line[0] == $@) {
			tmp = line.findRegexp("^@([[:word:]]+)");
			param = tmp[1][1];
			switch(param.asSymbol,
				\synth, {// A new synthdef metadata, parse this and following lines
					synthdef = Dictionary.new;

					line = scd.getLine();
					tmp = line.findRegexp("^@name ([[:word:]]+)");
					synthdef.put(\name, tmp[1][1].asSymbol);

					line = scd.getLine();
					tmp = line.findRegexp("^@desc (.+)$");
					synthdef.put(\desc, tmp[1][1]);

					line = scd.getLine();
					tmp = line.findRegexp("^@type ([[:word:]]+)((,[[:word:]]+)*)");
					types = List();
					types.add(tmp[1][1]); // item 1
					tmp = tmp[2][1]; // possible list of additional items
					if(tmp[0] == $,) {
						// Split and add
						tmp[1..].split($,).do {arg str;
							types.add(str);
						};
					};
					synthdef.put(\type, types);

					~synthdefs.put(synthdef[\name], synthdef);

				},
				\example, { "TODO: Load Example".postln; }
			);
		};
	};

});
);

~synthdefs

"@blah234_yes Foo Bar Whippity--doo dah / oh yeah!".findRegexp("^@([[:word:]]+) (.+)");
"@blah234_yes sjkhfkjw".findRegexp("^@([[:word:]]+)");


"@name Symbolic Name of the Synth".findRegexp("^@name ([A-Za-z0-9_]+)")
"@desc A short description of the synth".findRegexp("^@desc (.+)$")
"@type Granular,Additive,Spectral,Effect".findRegexp("^@type ([[:word:]]+)((,[[:word:]]+)*)")
"@type Granular".findRegexp("^@type ([[:word:]]+)((,[[:word:]]+)*)")


