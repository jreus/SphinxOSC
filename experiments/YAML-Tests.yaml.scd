boot:
 inputPattern: 'boot'
 rewritePattern: '
(
s.options.numInputBusChannels = 10; s.options.numOutputBusChannels = 10;
s.options.memSize = 65536; s.options.blockSize = 256; s.options.numWireBufs = 512;
s.waitForBoot { Syn.load; s.meter };
);
'
 action: '{ ServerOptions.devices.postln }'

pdef:
 inputPattern: 'pdef'
 rewritePattern: '
Pdef(\p01).play(quant: 1);
Pdef(\p01).stop;
(
Pdef(\p01, Pbind(*[
    instrument: \default,
    degree: Pseq([0,2,4,6,8],inf),
    dur: 1,
    amp: 1.0,
    pan: 0,
    out: 0
]
));
);
'
 action: ''
