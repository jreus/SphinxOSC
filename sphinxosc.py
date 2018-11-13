#!/usr/bin/env python

#   Jonathan Reus (c) 2018 GPLv3
#	Speech to text OSC utility
#
#	Inspired by a PocketSphinx Python class written by Sophie Li, 2016
#	http://blog.justsophie.com/python-speech-to-text-with-pocketsphinx/
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
from math import ceil
from collections import deque

# see: https://cmusphinx.github.io/doc/python/
from pocketsphinx.pocketsphinx import Decoder


from pythonosc import osc_message_builder
from pythonosc import udp_client


# Configure pocketsphinx decoder
THISDIR = os.path.dirname(os.path.abspath(__file__))
MODELDIR = os.path.normpath(THISDIR + "/models/")
DATADIR = os.path.normpath(THISDIR + "/../corpus/")
print(MODELDIR, DATADIR)

# Create a decoder with certain model
config = Decoder.default_config()
config.set_string('-hmm', os.path.join(MODELDIR, 'en-us/en-us'))
config.set_string('-lm', os.path.join(MODELDIR, 'en-us/en-us.lm.bin'))
config.set_string('-dict', os.path.join(MODELDIR, 'en-us/cmudict-en-us.dict'))

# Creates the decoder object
decoder = Decoder(config)


#DEV = sd.default.device
#INDEV = 5   # set to input device
# OUTDEV = 5  # set to output device
# sd.default.device = [INDEV,OUTDEV];
INDEV,OUTDEV = sd.default.device
print(sd.query_devices())
print(sd.default.dtype)
print("Default: ",sd.default.device) # sd.default.device is a property that can be set
RATE = 16000.0
BLOCK = 512
DTYPE = 'int16'
NUMCHANS = 1
LATENCY = ('low','high') # see https://python-sounddevice.readthedocs.io/en/0.3.12/api.html#sounddevice.default.dtype
LATENCY = 0.1
NUM_PHRASES = -1 # ???


# Open a blocking audiostream
# See: https://python-sounddevice.readthedocs.io/en/0.3.12/api.html#sounddevice.Stream.read
stream = sd.InputStream(device=INDEV, samplerate=RATE, latency=LATENCY, blocksize=BLOCK, dtype=DTYPE, channels=NUMCHANS)
stream.start()

# Open an OSC socket
scport = 57120
osc_client = udp_client.SimpleUDPClient("127.0.0.1", scport)


# Run audio analysis. Use a blocking stream!

SILENCE_LIMIT = 1 # Silence limit in seconds. The max ammount of seconds where
                           # only silence is recorded. When this time passes the
                           # recording finishes and the audio buffer is decoded
PREV_AUDIO = 0.5  # Previous audio (in seconds) to prepend. When noise
                  # is detected, how much of previously recorded audio is
                  # prepended. This helps to prevent chopping the beginning
                  # of the phrase.
GO = 0
STARTED = False
THRESHOLD = 300 # RMS value
audio2send = [] # expanding list of numpy arrays, each a block of audio to be processed
cur_data = ''  # current chunk of audio data
ratio = RATE / BLOCK
# sliding window stores 1s worth of blocks' RMS values, used as a moving RMS window to detect silence / end of utterance
slid_win = deque(maxlen=ceil(SILENCE_LIMIT * ratio))
# a deque of blocks, stores 0.5 seconds of audio before the threshhold is triggered for. Used to prevent chopping at the beginning of an utterance.
prev_audio = deque(maxlen=ceil(PREV_AUDIO * ratio))
started = False
lost_data = False

# listen to 10 seconds of audio
while GO < (10 * ratio):
    # get some data as a bytes-like object from the mic
    # sd.read returns a numpy.ndarray with one column per channel (frames, channels)
    cur_data,overflow = stream.read(BLOCK)

    # get rms over all samples in the fragment, add RMS value to sliding window (1s worth of blocks)
    # audioop provides simple operations on sound fragments stored as python strings
    # see: https://docs.python.org/2/library/audioop.html
    slid_win.append(audioop.rms(cur_data[:,0], 2))
    thesum = sum([x > THRESHOLD for x in slid_win]) # number of blocks whose RMS is above a given threshhold
    if thesum > 0: # more than one block has sqrt(avg) over threshhold, so we haven't hit silence yet
        if STARTED == False:
            print("Starting recording of utterance")
            STARTED = True
        audio2send.append(cur_data[:,0]) # append current data block to what will be sent for analysis
    elif STARTED:
        # We were recording, but there has been too much silence.
        print("Finished recording, decoding phrase.") # enough silence has passed...

        # concat previous 0.5s + recorded blocks into a single buffer
        buffer = np.concatenate(list(prev_audio) + audio2send)
        # Play phrase out the speaker
        # sd.play(buffer, samplerate=RATE, blocking=False, device=OUTDEV)

        # Decode using pocketsphinx
        decoder.start_utt() # begin processing utterance
        decoder.process_raw(buffer, False, False)
        #decoder.process_cep(buffer, False, False) # process cepstrum data
        decoder.end_utt()

        #words = []
        #[words.append(seg.word) for seg in decoder.seg()]
        for seg in decoder.seg():
            osc_client.send_message("/speak", [seg.word, seg.ascore, seg.lscore, seg.prob, seg.start_frame, seg.end_frame, seg.lback])

        # Save audio utterance as file and send to sphinx.
        #filename = save_speech(list(prev_audio) + audio2send, p)
        #r = decode_phrase(filename)
        #print("DETECTED: ", r)

        # Get ready for the next audio block.
        STARTED = False
        slid_win = deque(maxlen=ceil(SILENCE_LIMIT * ratio))
        prev_audio = deque(maxlen=ceil(0.5 * ratio))
        audio2send = []
        print("Listening ...")
    else:
        # There is silence and we are not yet in the middle of recording an utterance..
        prev_audio.append(cur_data[:,0]) # why...?
        #print("Silence ...", thesum)
    GO += 1


# Close the audio stream
stream.stop()
stream.close()


# Other things you can do with the decoder...

# Decoder hypothesis...
hypothesis = decoder.hyp()
print("Hypothesis:", hypothesis.hypstr, " score:", hypothesis.best_score, " prob:", hypothesis.prob)


# See Decoder API:
for seg in decoder.seg():
    print("WORD:",seg.word, "Acoustic-score:", seg.ascore, " Language-score:", seg.lscore, "Log Posterior Probability:", seg.prob)
    print("START FRAME:",seg.start_frame, "END FRAME:",seg.end_frame, "LBACK:", seg.lback)

# Find pronounciations in phoneme->word dictionary
#print(decoder.lookup_word("hello"))
#print(decoder.lookup_word("hello(2)"))
#print(decoder.lookup_word("love"))
#print(decoder.lookup_word("you"))

#
feat = decoder.get_feat()
print("Feat:", feat)

#logmath = decoder.get_logmath()
#print ('Best hypothesis: ', hypothesis.hypstr, " model score: ", hypothesis.best_score, " confidence: ", logmath.exp(hypothesis.prob))
#print ('Best hypothesis segments: ', [seg.word for seg in decoder.seg()])

# Access N best decodings.
print ('Best 10 hypothesis: ')
for best, i in zip(decoder.nbest(), range(10)):
    print("Hyp:",best.hypstr, " score:",best.score)
