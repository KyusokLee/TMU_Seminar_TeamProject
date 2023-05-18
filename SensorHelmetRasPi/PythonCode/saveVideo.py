##/ home/zemi/start/python_code/saveVideo.py
## webカメラから30秒の動画を保存するコード

import socket
import os.path
import cv2
import time
import datetime
import urllib.request
import subprocess


def get_video(video):
    now = datetime.datetime.now()
    # 動画ファイル保存用の設定
    save_dir = "FOLDER FOR STORING VIDEO"
    f_name = now.strftime("%Y年%m月%d日%H時%M分") + ".mp4"
    f_name = os.path.join("/home/zemi/start/python_code/video/",f_name)
    digit_num = len(str(int(video.get(cv2.CAP_PROP_FRAME_COUNT))))
    #nowifn = now.strftime('%Y%m%d_%H%M%S') + '.mp4'
    fps = int(video.get(cv2.CAP_PROP_FPS))                    # カメラのFPSを取得
    w = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))              # カメラの横幅を取得
    h = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))             # カメラの縦幅を取得
    fourcc = cv2.VideoWriter_fourcc(*'avc1')                  # 動画保存時のfourcc設定
    writer = cv2.VideoWriter(f_name, fourcc, fps, (w, h))  # 動画の仕様（ファイル名、fourcc, FPS, サイズ）
    cycle = fps*30
    # 撮影＝ループ中にフレームを1枚ずつ取得（qキーで撮影終了）
    n = 0
    while True:
        ret, frame = video.read()
        #edges = cv2.Canny(frame,100,200)
        #cv2.imshow("Test", frame)
        writer.write(frame)
        
        if(n >= cycle):
            break
        n += 1
    
    writer.release()
    video.release()
    cv2.destroyAllWindows()

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
    #ipアドレスが取得できない＝ネットに繋がっていないかつ，次につながったときはIPアドレスが変更される可能性が高い
    except (OSError, cv2.error) as e:
        t = e.__class__.__name__
        print(t)
        #mjpg-streamerを停止
        print("stop_mjpg-streamer")
        subprocess.run(["Shell Script Paths to stop mjpg-streamer", "arguments"], shell=True)
        video_ = cv2.VideoCapture(0)
        flg = True
    #mjpg-streamerが起動していない場合
    except (URLError, urlib.error.URLError, ConnectionError, ConnectionRefusedError) as e:
        t = e.__class__.__name__
        print(t)
        print("no url")
        #get_video(video_2)
        subprocess.run(["Shell Script Paths to stop mjpg-streamer", "arguments"], shell=True)
        time.sleep(1)
        video_ = cv2.VideoCapture(0)
        subprocess.run(["Shell Script Paths to start mjpg-streamer", "arguments"], shell=True)
        flg = True
    finally:
        get_video(video_)
        time.sleep(0.5)
        if (flg == True):
            subprocess.run(["Shell Script Paths to start mjpg-streamer", "arguments"], shell=True)
            
            
if __name__ == '__main__':
    try:
        main()
        #保存完了後，アップロード
        subprocess.run(["Shell Script Paths to upload video to Firebase", "arguments"], shell=True)
    except KeyboardInterrupt:
        print("error with main!")
