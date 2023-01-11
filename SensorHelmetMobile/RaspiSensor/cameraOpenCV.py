import cv2
import datetime
import requests
import os
import numpy as np
import schedule
import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage

cred = credentials.Certificate("raspi.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': "raspi-sensorhelmet.appspot.com"
})

# Clientとしてのアクセス
storageClient = storage.Client()
#バケットはバイナリオブジェクトの上位コンテナである。バケットはStorageでデータを保管する基本コンテナ
bucket = storageClient.bucket()

videoCapture = cv2.VideoCapture(0)
path = "/home/zemi/start/python_code/video/"

# Upload video File to Firebase Storage
def fileUpload(pathName):
    fileName = pathName.lstrip(path)
    blob = bucket.blob('videos/'+fileName)
    blob.upload_from_filename(filename=pathName, content_type='video/mp4')
    print(blob.public_url)
    
def getVideo(video):
    now = datetime.datetime.now()
    # 動画ファイル保存用の設定
    save_dir = "/home/zemi/start/python_code/video/"
    f_name = now.strftime("%Y年%m月%d日%H時%M分") + ".avi"
    f_name = os.path.join("/home/zemi/start/python_code/video/", f_name)
    digit_num = len(str(int(video.get(cv2.CAP_PROP_FRAME_COUNT))))
    #nowifn = now.strftime('%Y%m%d_%H%M%S') + '.mp4' #mp4の場合
    fps = int(video.get(cv2.CAP_PROP_FPS))                    # カメラのFPSを取得
    w = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))              # カメラの横幅を取得
    h = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))             # カメラの縦幅を取得
    fourcc = cv2.VideoWriter_fourcc(*'XVID')        # 動画保存時のfourcc設定（avi用）
    writer = cv2.VideoWriter(f_name, fourcc, fps, (w, h))  # 動画の仕様（ファイル名、fourcc, FPS, サイズ）
    cycle = fps*3000
    
    # 撮影＝ループ中にフレームを1枚ずつ取得（qキーで撮影終了）
    n = 0
    while True:
        ret, frame = video.read()
        #edges = cv2.Canny(frame,100,200)
        cv2.imshow("Test", frame)
        writer.write(frame)
        
        if(n >= 100):
            break
        n += 1
    
    writer.release()
    video.release()
    cv2.destroyAllWindows()
    
    # 上で作成したfileNameをパラメータに渡す
    fileUpload(f_name)

def main():
    getVideo(videoCapture)



if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("error with main!")