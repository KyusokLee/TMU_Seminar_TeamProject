## /home/zemi/start/python_code/dataToFirebase.py
## 時間，温度・湿度，緯度・経度，IPアドレスなどをFirebaseに送信するコード

import RPi.GPIO as GPIO
import socket
import time
import datetime
import requests
import serial
import micropyGPS
import threading
import csv
import gspread
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

#DHT11 connect to BCM_GPIO14
DHTPIN = 17

GPIO.setmode(GPIO.BCM)

MAX_UNCHANGE_COUNT = 100

STATE_INIT_PULL_DOWN = 1
STATE_INIT_PULL_UP = 2
STATE_DATA_FIRST_PULL_DOWN = 3
STATE_DATA_PULL_UP = 4
STATE_DATA_PULL_DOWN = 5

cred = credentials.Certificate("raspi.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

doc_ref = db.collection(u'Raspi').document(u'Database')
gps = micropyGPS.MicropyGPS(9, 'dd') # MicroGPSオブジェクトを生成する。

def read_dht11_dat():
    GPIO.setup(DHTPIN, GPIO.OUT)
    GPIO.output(DHTPIN, GPIO.HIGH)
    time.sleep(0.05)
    GPIO.output(DHTPIN, GPIO.LOW)
    time.sleep(0.02)
    GPIO.setup(DHTPIN, GPIO.IN, GPIO.PUD_UP)

    unchanged_count = 0
    last = -1
    data = []
    while True:
        current = GPIO.input(DHTPIN)
        data.append(current)
        if last != current:
            unchanged_count = 0
            last = current
        else:
            unchanged_count += 1
            if unchanged_count > MAX_UNCHANGE_COUNT:
                break

    state = STATE_INIT_PULL_DOWN

    lengths = []
    current_length = 0

    for current in data:
        current_length += 1

        if state == STATE_INIT_PULL_DOWN:
            if current == GPIO.LOW:
                state = STATE_INIT_PULL_UP
            else:
                continue
        if state == STATE_INIT_PULL_UP:
            if current == GPIO.HIGH:
                state = STATE_DATA_FIRST_PULL_DOWN
            else:
                continue
        if state == STATE_DATA_FIRST_PULL_DOWN:
            if current == GPIO.LOW:
                state = STATE_DATA_PULL_UP
            else:
                continue
        if state == STATE_DATA_PULL_UP:
            if current == GPIO.HIGH:
                current_length = 0
                state = STATE_DATA_PULL_DOWN
            else:
                continue
        if state == STATE_DATA_PULL_DOWN:
            if current == GPIO.LOW:
                lengths.append(current_length)
                state = STATE_DATA_PULL_UP
            else:
                continue
    if len(lengths) != 40:
        #print ("Data not good, skip")
        return False

    shortest_pull_up = min(lengths)
    longest_pull_up = max(lengths)
    halfway = (longest_pull_up + shortest_pull_up) / 2
    bits = []
    the_bytes = []
    byte = 0

    for length in lengths:
        bit = 0
        if length > halfway:
            bit = 1
        bits.append(bit)
    
    for i in range(0, len(bits)):
        byte = byte << 1
        if (bits[i]):
            byte = byte | 1
        else:
            byte = byte | 0
        if ((i + 1) % 8 == 0):
            the_bytes.append(byte)
            byte = 0
    #print (the_bytes)
    checksum = (the_bytes[0] + the_bytes[1] + the_bytes[2] + the_bytes[3]) & 0xFF
    if the_bytes[4] != checksum:
        print ("Data not good, skip")
        return False

    return the_bytes[0], the_bytes[2]

def rungps(): # GPSモジュールを読み、GPSオブジェクトを更新する
    s = serial.Serial('/dev/serial0', 9600, timeout=10)
    s.readline() # 最初の1行は中途半端なデーターが読めることがあるので、捨てる
    while True:
        sentence = s.readline().decode('utf-8') #GPSデーターを読み、文字列に変換する
        if sentence[0] != '$': # 先頭が'$'でなければ捨てる
            continue
        for x in sentence: # 読んだ文字列を解析してGPSオブジェクトにデーターを追加、更新する
            gps.update(x)

def ip_addr():
    try:
        connect_interface = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        connect_interface.connect(("8.8.8.8", 80))
        return (connect_interface.getsockname()[0])
    except (OSError):
        return 0
    

def main():
    #print ("Raspberry Pi wiringPi DHT11 Temperature test program/n")                                     # 引数はタイムゾーンの時差と出力フォーマット
    gpsthread = threading.Thread(target=rungps, args=()) # 上の関数を実行するスレッドを生成
    gpsthread.daemon = True
    gpsthread.start() # スレッドを起動
    flg = True
    flg2 = True
    while (flg == True):
        result = read_dht11_dat()
        if (result):
            if gps.clean_sentences > 20:
                humidity, temperature = result
                print ("humidity: %s %%,  Temperature: %s C" % (humidity, temperature))
                #this!!!!
                message =  ("humidity:" + str(humidity) + "Temperature:" + str(temperature))
            
                t = datetime.datetime.today()
                print (t.strftime("%Y/%m/%d,%H:%M"),",%-6.2f,%6.2f" % (temperature,humidity))
            
                #ちゃんとしたデーターがある程度たまったら出力する
                h = gps.timestamp[0] if gps.timestamp[0] < 24 else gps.timestamp[0] - 24
                #ip_ad
                ip_ad = ip_addr()
                ##gps.latitude[0], gps.longitude[0]を書き込む
                f = open('/home/zemi/start/python_code/gps_log.csv', mode="a", newline="")
                writer = csv.writer(f, lineterminator='\n')
                now = datetime.datetime.now()
                time = now.strftime("%Y%m%d%H%M%S")
                writer.writerow([time, gps.latitude[0], gps.longitude[0]])
                f.close()
                ## Data Update
                doc_ref.update({
                    u'date' : t.strftime('%Y年%m月%d日'),
                    u'time' : t.strftime('%H:%M'),
                    u'temp' : str(temperature),
                    u'humid' : str(humidity),
                    u'latitude' : str(gps.latitude[0]),
                    u'longitude' : str(gps.longitude[0]),
                    u'ip' : str(ip_ad)
                })
                flg = False
            
def destroy():
    GPIO.cleanup()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        destroy()
        
## Data Read
try:
    doc = doc_ref.get()
    print(u'Document data: {}'.format(doc.to_dict()))
except google.cloud.exceptions.NotFound:
    print(u'No such document!')
