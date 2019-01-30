"""
GOAL:
this script will optain a random youtube video id.
then download 1 min of that videos audio and then notify sclang via OSC message.

steps:
1. send osc message
2. optain random youtube video id
3. download 1 min audio
4. send osc message
5. wrap to whole thing in a 1 min loop

"""
import json
import urllib.request
import string
import random
import os
import argparse
import time

from pythonosc import osc_message_builder
from pythonosc import udp_client

# random video id
count = 1
API_KEY = 'AIzaSyDjFs6JULeueFkFPUZli9K5kDjsg2VN4Rk'
while(True):
  randomYt = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(3))
  urlData = "https://www.googleapis.com/youtube/v3/search?key={}&maxResults={}&part=snippet&type=video&q={}".format(API_KEY,count,randomYt)
  webURL = urllib.request.urlopen(urlData)
  data = webURL.read()
  encoding = webURL.info().get_content_charset('utf-8')
  results = json.loads(data.decode(encoding))

  for data in results['items']:
    videoId = (data['id']['videoId'])
  print(videoId)
  # get youtube video duration
  ytUrl = 'https://www.youtube.com/watch?v=' + videoId
  videoDur = os.popen('youtube-dl --get-duration ' + ytUrl).read()
  # audio stream of video
  # [:-1] removes the new line the os.popen returns
  audioStr = os.popen('youtube-dl -f \'bestaudio[ext=m4a]\' -g ' + ytUrl).read()[:-1]
  # if video length is smaller than 1 minute then download the whole length else
  # download the first minute
  if(len(videoDur)==3):
    os.system('ffmpeg -i \''+ audioStr +'\' -ac 1 -f wav ./noise.wav -y')
  else:
    os.system('ffmpeg -i \''+ audioStr +'\' -ss 00:00:00 -t 00:01:00 -ac 1 -f wav ./noise.wav -y')
  # OSC
  client = udp_client.SimpleUDPClient("127.0.0.1", 52170)
  client.send_message("/reloadSample", videoId)
  time.sleep(15)
