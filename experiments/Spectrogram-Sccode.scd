//
// Spectrum and Spetrogram of a sound
//
// Based on the material taught in: Audio Signal Processing for Music Applications
// by Prof Xavier Serra, Prof Julius O Smith, III
// https://www.coursera.org/course/audio
//
// jcc
//
// Select all code and evaluate

(
s.waitForBoot({
// vars for fft
var sfBuf, soundFile, sfPath, sfview, spectrum, win, selectionSpec, openButton, sfselDisp,
zoButton,ziButton,srButton,slButton,cursorFrame, sfDispArray, sfDispButton,loadDisp, hwin,real,imag,cosTable,fftsize,makefft,fftDisp, makefftB, sfSampleRate ;

//vars for spetrogram
var sgrmBuf,sonogramButton, sfSelection, windowsize, overlap, winStepArray, stepsNum;
var sfSliceArray, shwin, sreal, simag, sCosTable, sonSpectrum, spectrumArray;
var minmax, minSpectrumAmp,maxSpectrumAmp ,spctrgrm, cspctrgrm;
var readSlice, analyzeSlice, getMinMaxVals, makeSonogram, displaySonogram,clrspctrgrm; //function names

// init fft vars
fftsize= 2**11;
sfSampleRate = 44100; //temporary sr
sfDispArray=FloatArray.newClear(512);
hwin = Signal.hanningWindow(512);
real = Signal.newClear(fftsize);
imag = Signal.newClear(fftsize);
cosTable = Signal.fftCosTable(fftsize);
//"sfSampleRate; ".post;sfSampleRate.postln;

//init sonogram vars
windowsize = 512;
overlap= windowsize/2;
//init the next 3 variables when making a selection
//winStepArray=Array.series((~sfBuf.numFrames - windowsize).div(overlap), 0,  ~overlap);
//stepsNum=winStepArray.size;
//spectrumArray=DoubleArray.newClear(fftsize/2)!(stepsNum);
sfSliceArray=DoubleArray.newClear(512);
shwin = Signal.hanningWindow(512);
sreal = Signal.newClear(fftsize);
simag = Signal.newClear(fftsize);
sCosTable = Signal.fftCosTable(fftsize);

// fft functions
loadDisp={arg f;
	sfBuf.loadToFloatArray( f, 512,{arg a; sfDispArray = a});
	sfDispArray = sfDispArray;
	//	sfselDisp.refresh
};
makefft = {arg signalToAnalize;
	hwin = Signal.hanningWindow(512);
	signalToAnalize = signalToAnalize * hwin;  // window signal
	real=real.waveFill({arg x; // extend signal for higher FFT definition
		if((signalToAnalize.size) < x,
			{0},
			{signalToAnalize[x]})}, 0, fftsize-1);
	spectrum = fft(real, imag, cosTable) // do FFT
};
~loadFFT=Routine({

	// display 512 sound file samples from cursor
	// bug somewhere here, always requires two mouse clicks to work...
	// why??

	sfselDisp.value = loadDisp.value(cursorFrame);
	0.0001.wait;
	sfselDisp.refresh;
	// make fft and plot spectrum
	fftDisp.value = makefft.value(sfDispArray).magnitude[0..1024]; //plot only positive frecuencies
	fftDisp.domainSpecs = [0, (sfSampleRate / 2), \lin,0,0,"Hz"].asSpec;
	fftDisp.refresh;
});

// sonogram functions

(readSlice={arg f,n;
	sgrmBuf.loadToFloatArray( f, 512,{arg a; sfSliceArray = a});
	 sfSliceArray = sfSliceArray;
	"Reading spectrum slice number: ".post;(n+1).postln;
});

(
analyzeSlice = {arg signalToAnalize;
	signalToAnalize = signalToAnalize * shwin;  // window signal
	sreal=sreal.waveFill({arg x; // extend signal for higher FFT definition
		if((signalToAnalize.size) < x,
			{0},
			{signalToAnalize[x]})}, 0, fftsize-1);
	fft(sreal, simag, sCosTable) ;// do FFT
});

(
getMinMaxVals={
minmax=spectrumArray.size.collectAs({|i,n|
	[spectrumArray[i][spectrumArray[i].minIndex], spectrumArray[i][spectrumArray[i].maxIndex]];
},Array).flop;
minSpectrumAmp=minmax[0][minmax[0].minIndex];
"Min amp value :".post;minSpectrumAmp.postln;
maxSpectrumAmp=minmax[1][minmax[1].maxIndex];
"Max amp value :".post;maxSpectrumAmp.postln;
});

(
displaySonogram={
var nx= spectrumArray.size, ny= spectrumArray[0].size,
	xs = 1200, ys = 500, dx= xs/nx, dy=ys/ny, spctrgrm, stext, ttext, ftext,bcolor;

	getMinMaxVals.value;

	bcolor= Color.new(0.63915638923645, 0.61455166339874, 0.3189784526825);
	stext= StaticText(win, Rect(30, 900, 250, 20)).background_(bcolor);
	ttext = StaticText(win, Rect(280, 900, 250, 20)).background_(bcolor);
	ftext = StaticText(win, Rect(530, 900, 250, 20)).background_(bcolor);
	stext.string = " Sample range: ";
	ttext.string = " Time range: ";
	ftext.string = " Bin freq: ";
	spctrgrm = UserView(win, Rect(30, 400, xs, ys));
	spctrgrm.background = Color.black;
	spctrgrm.drawFunc = {
		nx.do{ |x|
			ny.do{ |y|
				var m = spectrumArray[x][y];
				Pen.color = Color.green(m.curvelin(minSpectrumAmp,maxSpectrumAmp,0,2,-1), 0.95);
				Pen.addRect(
					Rect(x*dx, ys-(y * dy), dx, dy)
				);
				Pen.fill
			}
		}
	};
	spctrgrm.mouseDownAction = {arg v, x, y;
		var binf, nextbinf, sampleNum;
		sampleNum =winStepArray[x.linlin(0, xs, 0, stepsNum)];
		sampleNum= sampleNum + sfSelection[0];
		//"Yval: ".post;y.postln;
		binf =((ys-y)/ys*2048)*sfSampleRate/4096;
		nextbinf = ((ys-y + 1)/ys*2048)*sfSampleRate/4096;
		stext.string = " Sample range: "++sampleNum++" - "++(sampleNum+512);
		ttext.string = " Time range: "++(sampleNum/sfSampleRate).round(0.001)++" - "
		++((sampleNum+512)/sfSampleRate).round(0.001)++" secs";
		ftext.string = " Bin freq: "++binf.round(0.001)++" - "++nextbinf.round(0.001)++" Hz";
	};
	spctrgrm.mouseMoveAction = spctrgrm.mouseDownAction;
}
);

(
~loadSpectrogram= Routine({
	var half = Array.series(fftsize /2);
	clrspctrgrm.value;
	spectrumArray.size.do{|n|
		readSlice.value(winStepArray[n],n);
		0.0001.wait;
		spectrumArray.put(n, analyzeSlice.value(sfSliceArray).abs.at(half).abs);
		0.0001.wait;
	};
	"Done".postln;

	displaySonogram.value;
})
);

Buffer.freeAll;
Window.closeAll;

////////////
//
// GUI
//
///////////

//Window
win = Window("Spectrum and Spectrogram", Rect(20, 4000, 1260, 960), false).front;
win.view.background_(Color.new(0.52692360877991, 0.46053557395935, 0.30619597434998));
win.alpha_(0.98);
win.onClose = {Buffer.freeAll; "Adiós".postln;"".postln};
//Open file to analyze
openButton = Button.new(win, Rect(30, 0, 130, 20))
.states_([["Select sound file", Color.black, Color.new(0.63915638923645, 0.61455166339874, 0.3189784526825)]])
.action_({
	Dialog.openPanel(
		okFunc: { |path|
			sfPath = path;
			soundFile = SoundFile.new;
			soundFile.openRead(path);
			sfSampleRate = soundFile.sampleRate;
			"sfSampleRate; ".post;sfSampleRate.postln;
			sfBuf = Buffer.readChannel(s, path, channels:0);
			sfview.soundfile_(soundFile);
			sfview.read(0, soundFile.numFrames);
			sfview.timeCursorOn = true;
			sfview.timeCursorPosition = 0;
			cursorFrame = 0;
			sfview.gridResolution = 1;
			sfview.mouseUpAction.value(sfview); // why this?
			//sfselDisp.value = loadDisp.value(cursorFrame);
			sfview.setSelectionStart(0,0);
			sfview.setSelectionSize(0,0)

		},
		cancelFunc: {"cancelled"}
	);
});
//sfView
sfview = SoundFileView.new(win, Rect(30, 20, 1200, 100));
sfview.mouseUpAction = {arg view;
	cursorFrame = sfview.timeCursorPosition;
	"Cursor at frame: ".post; cursorFrame.postln; "".postln;
	sfSelection = sfview.selections[sfview.currentSelection];
	"selection start, size: ".post; sfSelection.postln;
	"selection duration: ".post; (sfSelection[1] / sfSampleRate).postln;"".postln;
	sgrmBuf = Buffer.readChannel(s, sfPath, sfSelection[0], sfSelection[1], 0);
	winStepArray=Array.series((sfSelection[1] - windowsize).div(overlap), 0,  overlap);
	stepsNum=winStepArray.size;
	spectrumArray=DoubleArray.newClear(fftsize/2)!(stepsNum);

};





// zoom and scroll buttons
zoButton= Button.new(win, Rect(30, 120, 50, 30))
.states_([["-"]])
.action_({sfview.zoom(2).refresh});
ziButton= Button.new(win, Rect(80, 120, 50, 30))
.states_([["+"]])
.action_({sfview.zoom(0.75).refresh});
slButton= Button.new(win, Rect(150, 120, 50, 30))
.states_([["<-"]])
.action_({sfview.scroll(-0.1).refresh});
srButton= Button.new(win, Rect(200, 120, 50, 30))
.states_([["->"]])
.action_({sfview.scroll(0.1).refresh});
// FFT Analysis Button
sfDispButton= Button.new(win, Rect(250, 120, 250, 30))
.states_([["Analyze spectrum at cursor",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	AppClock.play(~loadFFT.reset);
});
// Sonogram Analysis Button
sonogramButton= Button.new(win, Rect(500, 120, 250, 30))
.states_([["Display Selection Sonogram",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	(sfSelection[1]!=0).if(
		{AppClock.play(~loadSpectrogram.reset)},
		{"Select a region in the Sound file View for Spectrogram display first!".postln}
	);
});
// Play SF selection
sonogramButton= Button.new(win, Rect(750, 120, 250, 30))
.states_([["Play Selection",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	(sfSelection[1]!=0).if(
		{{PlayBuf.ar(sfBuf.numChannels, sfBuf,1,1,sfSelection[0])*
			EnvGen.ar(
				Env.new([0,1,1,0],[0.001,0.998,0.001]*sfSelection[1]/sfSampleRate),
				doneAction:2)}!2
		}.play,
		{"Select a region in the Sound file View for Spectrogram display first!".postln}
	);
});


// 512 samples of sound file display
sfselDisp = Plotter.new(bounds: Rect(30, 150, 1200, 100),parent: win);
sfselDisp.value=[0];
// FFT display
fftDisp = Plotter.new(bounds: Rect(30, 280, 1200, 100),parent: win);
fftDisp.value = Array.fill(fftsize/2, {0});
fftDisp.domainSpecs = [0, (sfSampleRate / 2), \lin,0,0,"Hz"].asSpec; fftDisp.refresh;

// init spectrogram clear display
clrspctrgrm.value;

"FFT analysis of 512 samples of any sound file".postln; "".postln;
"1) select a sound file".postln;

"2) Position the cursor at the point in the soundfile you want to analyze and click 'Analyze Spectrum at cursor' button for a display of the spectrum at that instant".postln;


"3) Select a region in the sound file display and click 'Display selection sonogram' button for a spectrogam of the selection.  Be careful not to select a very long segment or it will take a VERY LONG time to compute and dispay the spectrogram (anything under 3 seconds is ok)".postln;
"".postln;
});
)