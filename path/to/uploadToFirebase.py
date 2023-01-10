import datetime
import requests
import os
import numpy as np
import schedule
import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage

# 初期化済みかを判定する
if not firebase_admin._apps:
    # 初期済みでない場合は初期化処理を行う
    cred = credentials.Certificate("RaspiFirebase.json") 
    default_app = firebase_admin.initialize_app(cred, {
        'storageBucket': "raspi-sensorhelmet.appspot.com"
    })
    

#バケットはバイナリオブジェクトの上位コンテナである。バケットはStorageでデータを保管する基本コンテナ
bucket = storage.bucket()

##動画ファイルが格納されているディレクトリ
directory = ""

# Upload video File to Firebase Storage
def fileUpload(pathName,fileName):
    #fileName = pathName.lstrip(path)
    blob = bucket.blob('videos/'+fileName)
    blob.upload_from_filename(pathName)
    print(blob.public_url)

# 指定したディレクトリ配下のファイルを探す関数
def filesearch(dir):
    path_list = glob.glob(dir + '/*')
    # 指定dir内の全てのファイルを取得
  
    # パスリストからファイル名を抽出
    name_list = []
    for i in path_list:
        file = os.path.basename(i)          
        name, ext = os.path.splitext(file)  
        name_list.append(name)              
    return path_list, name_list

def main():
    path_list, name_list = filesearch('video')
    for path,name in zip(path_list,name_list):
        #fileUpload(path, name)
        print(path,name)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("error with main!")
