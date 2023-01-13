## /home/zemi/start/python_code/uploadVideoToFirebase.py
## Firebaseのstorageにアップロードするコード（avi形式）
import datetime
import requests
import os
import time
import numpy as np
import schedule
import glob
import subprocess
import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage
from uuid import uuid4



# 初期化済みかを判定する
if not firebase_admin._apps:
    # 初期済みでない場合は初期化処理を行う
    cred = credentials.Certificate('/home/zemi/start/python_code/RaspiFirebase.json') 
    default_app = firebase_admin.initialize_app(cred, {
        'storageBucket' : "raspi-sensorhelmet.appspot.com"
    })
    
#バケットはバイナリオブジェクトの上位コンテナである。バケットはStorageでデータを保管する基本コンテナ
bucket = storage.bucket("raspi-sensorhelmet.appspot.com")

##動画ファイルが格納されているディレクトリ
directory = "/home/zemi/start/python_code/video"

# Upload video File to Firebase Storage
def fileUpload(pathName,fileName):
    #fileName = pathName.lstrip(path)
    file_type = 'video/mp4'
    # video/quicktime だと、webでは見れないが、すぐダウンロードできる
    blob = bucket.blob('videos/'+fileName)
    # Generate uuid token to download video file from url
    new_token = uuid4()
    metadata = {"firebaseStorageDownloadTokens": new_token}
    blob.metadata = metadata
    blob.upload_from_filename(filename=pathName, content_type=file_type)
    # 匿名アクセス（だれでもアクセスOK）を可能に
    blob.make_public()
    print(blob.public_url)

# 指定したディレクトリ配下のファイルを探す関数
def filesearch(dir):
    # 指定dir内の全てのファイルを取得
    path_list = glob.glob(dir + '/*')
  
    # パスリストからファイル名を抽出
    name_list = []
    for i in path_list:
        file = os.path.basename(i)          
        name, ext = os.path.splitext(file)
        name_list.append(name)
    return path_list, name_list

def main():
    #time.sleep(30)
    path_list, name_list = filesearch(directory)
    for path,name in zip(path_list,name_list):
        fileUpload(path, name)
        print(path,name)


if __name__ == '__main__':
    try:
        main()
        #subprocess.run(["/home/zemi/start/rmJpgFile.sh", "arguments"], shell=True)
        ##アップロードに成功したら，ファイルを退避
        subprocess.run(["/home/zemi/start/mvVideoFile.sh", "arguments"], shell=True)


    except KeyboardInterrupt:
        print("error with main!")
