#!/bin/sh
#start mjpg-streamer and renewal csv file (Run at Raspi boot)
#puts the directory in which files are locaded
bash /home/zemi/mjpg-streamer/mjpg-streamer-experimental/start.sh
#
python3 /home/zemi/start/python_code/createNewGpsLog.py
