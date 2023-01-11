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
    #save_dir = "/var/www/html/camera/pictures"
    save_dir = "/home/zemi/start/python_code/picture/"
    f_name = now.strftime("%Y年%m月%d日%H時%M分") + ".jpg"
    f_name = os.path.join("/home/zemi/start/python_code/picture/",f_name)
    rr, img = capture.read()
    cv2.imwrite(f_name, img)
    capture.release()
    # 撮影＝ループ中にフレームを1枚ずつ取得（qキーで撮影終了）
   

def main():
    #url = "http://192.168.151.126:8080/?action=stream"
    #url = "http://192.168.0.37:8080/?action=stream"
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
        subprocess.run(["/home/zemi/start/stop_mjpg-streamer.sh", "arguments"], shell=True)
        video_ = cv2.VideoCapture(0)
        flg = True
    #mjpg-streamerが起動していない場合
    except (URLError, urlib.error.URLError, ConnectionError, ConnectionRefusedError) as e:
        t = e.__class__.__name__
        print(t)
        print("no url")
        #get_video(video_2)
        #subprocess.run(["/home/zemi/start/stop_mjpg-streamer.sh", "arguments"], shell=True)
        time.sleep(1)
        video_ = cv2.VideoCapture(0)
        #subprocess.run(["/home/zemi/start/autostart.sh", "arguments"], shell=True)
        flg = True
    finally:
        get_jpg(video_)
        time.sleep(3)
        #if (flg == True):
            #subprocess.run(["/home/zemi/start/autostart.sh", "arguments"], shell=True)
            
            
if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("error with main!")
