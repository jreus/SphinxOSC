#!/usr/bin/env python

#   Jonathan Reus (c) 2018 GPLv3
#	Time-synchronized speech to text OSC utility using CMU's Pocketsphinx
#
#   See the corresponding SphinxOSC class in SuperCollider for a client implementation.
#
#	Inspired by a PocketSphinx Python class written by Sophie Li, 2016
#	http://blog.justsophie.com/python-speech-to-text-with-pocketsphinx/
#
#   For an overview of the speech analysis algorithms used by CMUSphinx
#   see: https://cmusphinx.github.io/wiki/tutorialconcepts/
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License https://www.gnu.org/licenses/ for more details.

import sounddevice as sd
import numpy as np
import wave
import audioop
import os
import time
from math import ceil
from collections import deque

# see: https://cmusphinx.github.io/doc/python/
from pocketsphinx.pocketsphinx import Decoder


from pythonosc import osc_message_builder
from pythonosc import osc_bundle_builder
from pythonosc import udp_client

class SphinxOSC(object):
    def __init__(self):
        self.SILENCE_THRESH = 500   # RMS threshhold for 'silence', used for utterance segmenting
                                    # when RMS peaks above this value utterance recording starts
        self.SILENCE_LIMIT = 0.3  # silence limit in seconds for utterance segmenting
                                # RMS level below the SILENCE_THRESH for this many seconds ends an utterance
        self.RECORD_PREVIOUS = 0.2  # Previous audio (in seconds) to prepend. When noise
                                    # is detected, how much of previously recorded audio is
                                    # prepended. This helps to prevent chopping the beginning
                                    # of the phrase.
        self.SEND_ADDR = "127.0.0.1"
        self.SEND_PORT = 57120
        self.OSC_CLIENT = None
        self.PWD = os.path.dirname(os.path.abspath(__file__))
        self.MODELDIR = os.path.normpath(self.PWD + "/models/")
        self.DATADIR = os.path.normpath(self.PWD + "/../corpus/")
        self.ECHO = False
        self.DECODER = None

    def run(self, runtime, input_device, num_utterances=None, output_device=None):
        #open the OSC port
        osc_client = udp_client.SimpleUDPClient(self.SEND_ADDR, self.SEND_PORT)

        # Configure & instantiate a pocketsphinx decoder
        config = Decoder.default_config()
        config.set_string('-hmm', os.path.join(self.MODELDIR, 'en-us/en-us'))
        config.set_string('-lm', os.path.join(self.MODELDIR, 'en-us/en-us.lm.bin'))
        config.set_string('-dict', os.path.join(self.MODELDIR, 'en-us/cmudict-en-us.dict'))
        self.DECODER = Decoder(config)
        decoder = self.DECODER

        SR = 16000.0
        BLOCKSIZE = 512
        DTYPE = 'int16'
        NUMCHANS = 1
        LATENCY = ('low','high') # see https://python-sounddevice.readthedocs.io/en/0.3.12/api.html#sounddevice.default.dtype
        LATENCY = 0.1

        # TODO: listen until this many utterances have been decoded
        if num_utterances != None:
            pass

        # Open a blocking audiostream
        # See: https://python-sounddevice.readthedocs.io/en/0.3.12/api.html#sounddevice.Stream.read
        stream = sd.InputStream(device=input_device, samplerate=SR, latency=LATENCY, blocksize=BLOCKSIZE, dtype=DTYPE, channels=NUMCHANS)
        stream.start()

        GO = 0
        STARTED = False
        audio2send = [] # expanding list of numpy arrays, each a block of audio to be processed
        cur_data = ''  # current chunk of audio data
        ratio = SR / BLOCKSIZE
        # sliding window stores 1s worth of blocks' RMS values, used as a moving RMS window to detect silence / end of utterance
        slid_win = deque(maxlen=ceil(self.SILENCE_LIMIT * ratio))
        # a deque of blocks, stores 0.5 seconds of audio before the threshhold is triggered for. Used to prevent chopping at the beginning of an utterance.
        prev_audio = deque(maxlen=ceil(self.RECORD_PREVIOUS * ratio))
        started = False
        lost_data = False

        print("Listening ...")
        starttime = time.time()
        osc_client.send_message("/sphinxOSC/sync", [time.time() - starttime, self.RECORD_PREVIOUS])

        while GO < (runtime * ratio):
            # get some data as a bytes-like object from the mic
            # sd.read returns a numpy.ndarray with one column per channel (frames, channels)
            cur_data,overflow = stream.read(BLOCKSIZE)

            # get rms over all samples in the fragment, add RMS value to sliding window (1s worth of blocks)
            # audioop provides simple operations on sound fragments stored as python strings
            # see: https://docs.python.org/2/library/audioop.html
            slid_win.append(audioop.rms(cur_data[:,0], 2))
            thesum = sum([x > self.SILENCE_THRESH for x in slid_win]) # number of blocks whose RMS is above a given threshhold
            if thesum > 0: # more than one block has sqrt(avg) over threshhold, so we haven't hit silence yet
                if STARTED == False:
                    print("Starting recording of utterance ...")
                    osc_client.send_message("/sphinxOSC/utterance", [time.time()-starttime, 1])
                    STARTED = True
                audio2send.append(cur_data[:,0]) # append current data block to what will be sent for analysis
            elif STARTED:
                # the silence time threshhold has been reached while recording an utterance
                print("Utterance end. Decoding... ")
                # concat previous audio + recorded blocks into a single buffer
                buffer = np.concatenate(list(prev_audio) + audio2send)

                # Optionally echo the phrase out the speaker
                #if self.ECHO == True:
                #    sd.play(buffer, samplerate=SR, blocking=False, device=output_device)

                # Save audio utterance as file
                #filename = save_speech(list(prev_audio) + audio2send, p)


                # Decode utterance
                decoder.start_utt() # begin processing utterance
                decoder.process_raw(buffer, False, False)
                #decoder.process_cep(buffer, False, False) # process cepstrum data
                decoder.end_utt()

                utterance = [time.time()-starttime, 0, decoder.hyp().hypstr];
                print(utterance[2],'\n')

                #for seg in decoder.seg():
                #    utterance.append([seg.word, decoder.lookup_word(seg.word), seg.ascore, seg.lscore, seg.prob, seg.start_frame, seg.end_frame, seg.lback])

                for seg in decoder.seg():
                    utterance.append(seg.word)
                    utterance.append(decoder.lookup_word(seg.word))
                    utterance.append(seg.ascore)
                    utterance.append(seg.lscore)
                    utterance.append(seg.prob)
                    utterance.append(seg.start_frame)
                    utterance.append(seg.end_frame)
                    utterance.append(seg.lback)


                osc_client.send_message("/sphinxOSC/utterance", utterance)

                # Get ready for the next audio block.
                STARTED = False
                slid_win = deque(maxlen=ceil(self.SILENCE_LIMIT * ratio))
                prev_audio = deque(maxlen=ceil(self.RECORD_PREVIOUS * ratio))
                audio2send = []
                print("Listening ...")
            else:
                # There is silence and we are not yet in the middle of recording an utterance..
                prev_audio.append(cur_data[:,0])

            GO += 1

        # Close the audio stream
        stream.stop()
        stream.close()


def decoderfun(decoder):
    # Decoder hypothesis...
    hypothesis = decoder.hyp()
    print("Last Hypothesis:", hypothesis.hypstr, " score:", hypothesis.best_score, " prob:", hypothesis.prob)
    # lback
    # see: https://cmusphinx.github.io/doc/pocketsphinx/pocketsphinx_8h.html#adfd45d93c3fc9de6b7be89d5417f6abb
    # number of words used in calculating the linguistic score
    #for seg in decoder.seg():
    #    print("WORD:",seg.word, "Acoustic-score:", seg.ascore, " Language-score:", seg.lscore, "Log Posterior Probability:", seg.prob)
    #    print("START FRAME:",seg.start_frame, "END FRAME:",seg.end_frame, "LBACK:", seg.lback)
    # Find pronounciations in phoneme->word dictionary
    #print(decoder.lookup_word("hello"))
    #print(decoder.lookup_word("hello(2)"))
    #print(decoder.lookup_word("love"))
    #print(decoder.lookup_word("you"))
    #feat = decoder.get_feat()
    #print("Feat:", feat)
    #logmath = decoder.get_logmath()
    #print ('Best hypothesis: ', hypothesis.hypstr, " model score: ", hypothesis.best_score, " confidence: ", logmath.exp(hypothesis.prob))
    #print ('Best hypothesis segments: ', [seg.word for seg in decoder.seg()])
    # Access N best decodings.
    #print ('Best 10 hypothesis: ')
    #for best, i in zip(decoder.nbest(), range(10)):
    #    print("Hyp:",best.hypstr, " score:",best.score)


if __name__ == '__main__':
    import argparse
    import sys
    argp = argparse.ArgumentParser(description="A time-synchronized speech-to-text OSC utility using CMU Pocketsphinx.")
    argp.add_argument('-T', default=10, type=float, help="time to run ASR, after which program exits (seconds)")
    argp.add_argument('-SLIMIT', default=0.3, type=float, help="silence period separating utterances (seconds)")
    argp.add_argument('-RPREV', default=0.2, type=float, help="amount of audio included before detecting an utterance, avoids cutting the beginnings of words (seconds)") # run for dur seconds
    argp.add_argument('-STHRESH', default=500, type=int, help="rms silence threshhold (integer)") # run for dur seconds
    argp.add_argument('--ip', default="127.0.0.1", help="OSC send address")
    argp.add_argument('--port', default=57120, type=int, help="OSC send port")
    argp.add_argument('--devices', action='store_true', help="query available audio devices and show default device")
    argp.add_argument('--indev', type=int, help="input audio device, use --devices to see available devices")
    argp.add_argument('--outdev', type=int, help="output audio device, use --devices to see available devices")


    args = argp.parse_args()
    print(args)

    if args.devices:
        print(sd.query_devices())
        print("Default: ",sd.default.device, " dtype:", sd.default.dtype) # sd.default.device is a property that can be set
    else:
        if args.indev == None:
            args.indev = sd.default.device[0]
        if args.outdev == None:
            args.outdev = sd.default.device[1]
        s = SphinxOSC()
        s.ECHO = True
        s.SILENCE_LIMIT = args.SLIMIT
        s.SILENCE_THRESH = args.STHRESH
        s.RECORD_PREVIOUS = args.RPREV
        s.SEND_ADDR = args.ip
        s.SEND_PORT = args.port
        s.run(args.T, args.indev, output_device=args.outdev)
        decoderfun(s.DECODER)

    sys.exit()
