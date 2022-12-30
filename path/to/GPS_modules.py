import serial
import micropyGPS
import threading
import time
import datetime
import csv
import requests
import gspread

#Google Spread Sheet
try:
    gc = gspread.service_account(filename='/home/zemi/iot-project-for-b3-bb3ffe230d41.json')
    ss = gc.open("sheet2gmap")
    sheet_name = 'sheet1'
except:
    pass
row = 2
collumn = 1

gps = micropyGPS.MicropyGPS(9, 'dd') # MicroGPSオブジェクトを生成する。
                                     # 引数はタイムゾーンの時差と出力フォーマット

def rungps(): # GPSモジュールを読み、GPSオブジェクトを更新する
    s = serial.Serial('/dev/serial0', 9600, timeout=10)
    s.readline() # 最初の1行は中途半端なデーターが読めることがあるので、捨てる
    while True:
        sentence = s.readline().decode('utf-8') #GPSデーターを読み、文字列に変換する
        if sentence[0] != '$': # 先頭が'$'でなければ捨てる
            continue
        for x in sentence: # 読んだ文字列を解析してGPSオブジェクトにデーターを追加、更新する
            gps.update(x)

gpsthread = threading.Thread(target=rungps, args=()) # 上の関数を実行するスレッドを生成
gpsthread.daemon = True
gpsthread.start() # スレッドを起動
flg = True
while (flg == True):
    if gps.clean_sentences > 20: # ちゃんとしたデーターがある程度たまったら出力する
        h = gps.timestamp[0] if gps.timestamp[0] < 24 else gps.timestamp[0] - 24

        flg = False
        
        with open('/home/zemi/start/python_code/gps_log.csv', 'r') as f:
            alltxt = f.readlines()
            endrow = len(alltxt) + 1
            print(endrow)
        #csvファイルを書き込み
        i = 1
        f = open('/home/zemi/start/python_code/gps_log.csv', mode="a", newline="")
        writer = csv.writer(f, lineterminator='\n')
        now = datetime.datetime.now()
        time = now.strftime("%Y%m%d%H%M%S")
        writer.writerow([time, gps.latitude[0], gps.longitude[0]])
        f.close()
        #GSS
        try:
            ss.sheet1.update_cell(row,collumn, time)
            ss.sheet1.update_cell(row, (collumn+2), gps.latitude[0])
            ss.sheet1.update_cell(row, (collumn+3), gps.longitude[0])
        except:
            pass
        
        print('%2d:%02d:%04.1f' % (h, gps.timestamp[1], gps.timestamp[2]))
        print('緯度経度: %2.8f. %2.8f' % (gps.latitude[0], gps.longitude[0]))
        print('海抜: %f' % gps.altitude)
        print(gps.satellites_used)
        print('衛星番号: (仰角, 方位角, SN比)')
        for k, v in gps.satellite_data.items():
            print('%d: %s' % (k, v))
        print('')
