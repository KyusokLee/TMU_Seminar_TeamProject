import os.path
import cv2
import time
import datetime
import urllib.request

#time.sleep(10)
#url = "http://192.168.151.126:8080/?action=stream"
url = "http://192.168.0.37:8080/?action=stream"

try:
    f = urllib.request.urlopen(url)
    f.close()
    video = cv2.VideoCapture(url)
    #get_video(video_)
    
except Exception:
    print("no url")
    video = cv2.VideoCapture(0)
    #get_video(video_2)

finally:
    now = datetime.datetime.now()
    # 動画ファイル保存用の設定
    #save_dir = "/var/www/html/camera/pictures"
    save_dir = "/home/zemi/start/python_code/video/"
    f_name = now.strftime("%Y%m%d%H%M%S") + ".avi"
    f_name = os.path.join("/home/zemi/start/python_code/video/",f_name)
    digit_num = len(str(int(video.get(cv2.CAP_PROP_FRAME_COUNT))))
    #nowifn = now.strftime('%Y%m%d_%H%M%S') + '.mp4'
    fps = int(video.get(cv2.CAP_PROP_FPS))                    # カメラのFPSを取得
    w = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))              # カメラの横幅を取得
    h = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))             # カメラの縦幅を取得
    #fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')        # 動画保存時のfourcc設定（mp4用）
    fourcc = cv2.VideoWriter_fourcc(*'XVID')        # 動画保存時のfourcc設定（mp4用）
    writer = cv2.VideoWriter(f_name, fourcc, fps, (w, h))  # 動画の仕様（ファイル名、fourcc, FPS, サイズ）
    cycle = fps*600
    # 撮影＝ループ中にフレームを1枚ずつ取得（qキーで撮影終了）
    n = 0
    while True:
        ret, frame = video.read()
        #edges = cv2.Canny(frame,100,200)
        cv2.imshow("Test", frame)
        writer.write(frame)
        
        key = cv2.waitKey(1)
        if key == 27:
            break
        if(n >= 100):
            break
        n += 1
    
    writer.release()
    cv2.destroyAllWindows()


