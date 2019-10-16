f = "".resolveRelative +/+ "YAML-Tests.yaml.scd";
x = f.parseYAMLFile;
x.toYAML;

x.class; // could be an array or a dict



x["boot"].keys
x["boot"]["rewritePattern"]

x["pdef"].keys


x
y = x[0]
z = y["inputPattern"]

~toYAML.(x)


// TODO:
// FIGURE THIS OUT...!
// THEN IMPLEMENT A MIXED YAML / SC format

(
// toYAML
~toYAML = {|col,depth=0|
	var result = "";
	case { col.isKindOf(Array) } {
		col.do {|val|
			result = result ++ "\n" ++ "-".padLeft(depth+1," ") ++ ~toYAML.(val, depth+1);
		};
	}
	{ col.isKindOf(Dictionary) } {
		col.keysValuesDo {|key,val|
			"% >%<".format(depth, key.asString.padLeft(depth+key.size, " ")).postln;
			result = result ++ key.asString.padLeft(depth+key.size, " ") ++ ": ";
			if(val.isKindOf(Dictionary)) { result = result ++ "\n" };
			result = result ++ ~toYAML.(val, depth+1);
		};
	}
	{ col.isKindOf(Object) } { result = result ++ "'%'\n".format(col.asString) };
	result;
};

);



	if(col.isKindOf(Array)) {
		col.do {|item|

		};
	};

	if(col.isKindOf(Dictionary)) {
		col.keysValuesDo {|key,val|

		}
	};
