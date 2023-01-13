##webカメラから画像を保存するコード
import socket
import os.path
import cv2
import sys
import time
import datetime
import urllib.request
import subprocess


def get_jpg(capture):
    now = datetime.datetime.now()
    # ファイル保存用の設定
    #save_dir = ""
    save_dir = "folder for storing Image"
    f_name = now.strftime("%Y年%m月%d日%H時%M分") + ".jpg"
    f_name = os.path.join("[folder for storing Image]",f_name)
    rr, img = capture.read()
    cv2.imwrite(f_name, img)
    capture.release()
    # 撮影＝ループ中にフレームを1枚ずつ取得
   

def main():
    #url = "http://[IP ad of RasPi]/?action=stream"
    flg = False
    try:
        connect_interface = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        connect_interface.connect(("8.8.8.8", 80))
        #print(connect_interface.getsockname()[0])  
        url = "http://"+str(connect_interface.getsockname()[0])+":8080/?action=stream"
        f = urllib.request.urlopen(url)
        f.close()
        video_ = cv2.VideoCapture(url)
        #get_video(video_)
    #ipアドレスが取得できない＝ネットに繋がっていないかつ，次につながったときはIPアドレスが変更されるか脳性が高い
    except (OSError, cv2.error) as e:
        t = e.__class__.__name__
        print(t)
        #mjpg-streamerを停止
        print("stop_mjpg-streamer")
        subprocess.run(["Shell Script path to stop mjpg-streamer", "arguments"], shell=True)
        video_ = cv2.VideoCapture(0)
        flg = True
    #mjpg-streamerが起動していない場合か or なんらかのエラー
    except (URLError, urlib.error.URLError, ConnectionError, ConnectionRefusedError) as e:
        t = e.__class__.__name__
        print(t)
        print("no url")
        #get_video(video_2)
        subprocess.run(["Shell Script path to stop mjpg-streamer", "arguments"], shell=True)
        time.sleep(1)
        video_ = cv2.VideoCapture(0)
        subprocess.run(["Shell Script path to start mjpg-streamer", "arguments"], shell=True)
        flg = True
    finally:
        get_jpg(video_)
        time.sleep(3)
        if (flg == True):
            subprocess.run(["Shell Script path to start mjpg-streamer", "arguments"], shell=True)
            
            
if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("error with main!")
