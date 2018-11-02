#!/usr/local/bin/python2.7
from __future__ import unicode_literals
import request
import requests
import subprocess
import json
import OSC
import csv
import datetime
import time, random
import threading
import shutil

counter = 0
t2n = 60;
vidIDlist = [];
client = OSC.OSCClient()
client.connect( ( '127.0.0.1', 57120 ) )
msg = OSC.OSCMessage()
msg.setAddress("/newsample")
msg.append(45)

url = "https://randomyoutube.net/api/getvid?api_token=JHhvy16oOiSmQwB27eTmNaASvsduVUx2bCmCvBYpkbtGg5Tp9AyLGjKbK71t"

def handler(addr, tags, data, client_address):
    txt = "OSCMessage '%s' from %s: " % (addr, client_address)
    txt += str(data)
    if data[0] == 'saveSamplePlz':
        lastRow = open('idList.csv', 'r').readlines()[-1]
        shutil.copyfile('abc.wav','selected/'+lastRow+'.wav')
    # elif data[0] == 't2n':
    #     t2n = data[1]
    print(txt)

def audioReq():
    vidIDlist = []
    r = requests.get(url)
    vidResp = json.loads(r.content)
    print (vidResp['vid'])
    vidIDlist.append(datetime.datetime.now())
    vidIDlist.append(vidResp['vid'])
    with open('idList.csv', 'a') as f:
        writer = csv.writer(f)
        writer.writerow(vidIDlist)
        ytUrl = 'https://www.youtube.com/watch?v='+ vidResp['vid']
        print(ytUrl)
        audioStr0 = 'youtube-dl --get-duration '+ ytUrl
        process = subprocess.Popen(audioStr0.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        durArr = output.split(':')
        print(len(durArr))
        audioStr = 'youtube-dl -f bestaudio[ext=m4a] -g '+ ytUrl
        process = subprocess.Popen(audioStr.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        audioStream = output[:-1]
        print(audioStream)
    if len(durArr) == 1:
        downBash = 'ffmpeg -i \''+ audioStream +'\' -ac 1 -f wav ~/randSynth/abc.wav -y'
        process2 = subprocess.call(downBash, stdout=subprocess.PIPE, shell=True)
        # output2, error2 = process.communicate()
        # print(output2)
        print(downBash)
    else:
        downBash = 'ffmpeg -i \''+ audioStream +'\' -ss 00:00:00 -t 00:01:00 -ac 1 -f wav ~/randSynth/abc.wav -y'
        process2 = subprocess.call(downBash, stdout=subprocess.PIPE, shell=True)
        # output2, error2 = process.communicate()
        # print(output2)
        print(downBash)

def downLoop():
    while True:
        global counter
        global t2n
        counter += 1
        print("counter", counter)
        audioReq()
        client.send(msg)
        time.sleep(t2n)
def saveSample():
        s = OSC.OSCServer(('127.0.0.1', 50010))  # listen on localhost, port 57120
        s.addMsgHandler('/newsample', handler)     # call handler() for OSC messages received with the /startup address
        s.serve_forever()
thread1 = threading.Thread(target=downLoop)
thread1.start()

thread2 = threading.Thread(target=saveSample)
thread2.start()
