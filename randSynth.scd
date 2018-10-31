MIDIClient.init;
MIDIIn.connectAll;
n = NetAddr("127.0.0.1", 50010);
TempoClock.tempo = 0.5;
// TempoClock.default.tempo = 80/60;
(
~newSample ={
        j.free;
        k.free;
        b = Buffer.read(s, Platform.userHomeDir +/+ "randSynth/abc.wav");
        c = Buffer.sendCollection(s, Env.sine(dur: 0.01).discretize);
        SynthDef(\grain, {| amp = 0.2, trigFreq = 100, graindur = 0.1, rate = 1, filepos = 0.5, pan = 0, envbuf = -1 |
        var src;
        src = GrainBuf.ar(2, Impulse.ar(trigFreq), graindur, b.bufnum, rate, SinOsc.kr(10, mul: 0.05, add: filepos), 2, pan, c.bufnum);
        Out.ar(0, src * amp);
        }).add;
        SynthDef(\grain2, {| amp = 0.5, trigFreq = 100, graindur = 0.1, rate = 1, filepos = 0.5, pan = 0, envbuf = -1|
        var src;
        src = GrainBuf.ar(2, Impulse.ar(trigFreq), graindur, b.bufnum, rate, filepos, 2, pan, c.bufnum);
        Out.ar(0, src * amp);
        }).add;
        j = Synth(\grain);
        // k = Synth(\grain,[\amp, 0]);
        // l = Synth(\grain2, [\amp, 0]);
}
)
(
OSCdef.new(\reciever,{| msg, time, addr, port|
        ~newSample.value;
        "new sample".postln;
},'/newsample');
)
// next sample
// n.sendMsg("/newsample", "t2n", "20");
s.record;
s.stopRecording;
// save sample
n.sendMsg("/newsample", "saveSamplePlz");
//////// LIVE
// akai lpd8
(
MIDIdef.cc(\noteOnTest, {
        arg vel, nn, chan, src;
        [vel, nn, chan, src].postln;
        if(chan == 0,{
                if(nn == 1,{
                        j.set(\filepos, LinLin.kr(vel,1,127,0,1));
                });
                if(nn == 2,{
                        j.set(\rate,LinLin.kr(vel,1,127,0,2));
                });
                if(nn == 3,{
                        j.set(\graindur, LinLin.kr(vel,1,127,0,0.5));
                });
                if(nn == 4,{
                        j.set(\trigFreq, LinLin.kr(vel,1,127,1,500));
                });
                if(nn == 8,{
                        j.set(\amp, LinLin.kr(vel, 1, 127, 0, 0.9));
                });
        });
        if(chan == 2,{
                if(nn == 1,{
                        k.set(\filepos, LinLin.kr(vel,1,127,0,1));
                });
                if(nn == 2,{
                        k.set(\rate,LinLin.kr(vel,1,127,0,2));
                });
                if(nn == 3,{
                        k.set(\graindur, LinLin.kr(vel,1,127,0,0.5));
                });
                if(nn == 4,{
                        k.set(\trigFreq, LinLin.kr(vel,1,127,1,500));
                });
                if(nn == 8,{
                        k.set(\amp, LinLin.kr(vel, 1, 127, 0, 0.9));
                });
        });
        if(chan == 3,{
                if(nn == 1,{
                        l.set(\filepos, LinLin.kr(vel,1,127,0,1));
                });
                if(nn == 2,{
                        l.set(\rate,LinLin.kr(vel,1,127,0,2));
                });
                if(nn == 3,{
                        l.set(\graindur, LinLin.kr(vel,1,127,0,0.5));
                });
                if(nn == 4,{
                        l.set(\trigFreq, LinLin.kr(vel,1,127,1,500));
                });
                if(nn == 8,{
                        l.set(\amp, LinLin.kr(vel, 1, 127, 0, 0.9));
                });
        });
});
)
//FEEDBACK
(
z = Buffer.alloc(s, 44100 * 10, 2);
SynthDef(\rec, {| in|
        RecordBuf.ar(In.ar(in,2), z, doneAction:2, loop: 0);
}).add;
SynthDef(\play, {| amp = 0.8|
        var env = EnvGen.kr(Env.sine(z.duration), gate: 1, doneAction: 2);
        Out.ar(0, PlayBuf.ar(2, z.bufnum, doneAction: 2) * amp * env);
}).add;
fork{
        inf.do({
                // 3.wait;
        "recording".postln;
			x = Synth(\rec, [\in, 0], j, \addAfter);
        10.wait;
        "playing".postln;
        y = Synth(\play);
        });
}
)
s.plotTree;
(
SynthDef(\synth, {| freq = 53, amp = 0.2, dur|
	var env = EnvGen.kr(Env.sine(dur), gate:1, doneAction:2);
	var src = SinOsc.ar(freq.midicps, mul: amp)!2;
	Out.ar(0, src * env);
}).add;
)
(
Pdef(\seq, Pbind(\instrument, \synth,
	\dur, Prand([10, 20 ,30], inf),
	\freq, Prand([53, 60, 64], inf)
)).stop
)
(
Pdef(\seq2, Pbind(\instrument, \synth,
	\dur, Prand([0.1, 0.2 ,0.3], inf),
	\freq, Prand([53, 60, 64], inf)
)).stop;
)
(
SynthDef(\noise, {| freq = 53, amp = 0.2, dur|
	var env = EnvGen.kr(Env.sine(dur), gate:1, doneAction:2);
	var src = LFNoise2.ar(freq.midicps, mul: amp)!2;
	Out.ar(0, src * env);
}).add;
)
(
Pdef(\seq3, Pbind(\instrument, \noise,
	\dur, 100,
	\freq, Prand([53, 60, 64], inf),
	\amp, 0.5
)).stop
)