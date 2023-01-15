##capture camera footage and move mp4 files
##1~5分おきに実行

##動画を保存
##python3 /home/zemi/start/python_code/savePicture.py
python3 /home/zemi/start/python_code/saveVideo.py
##上記のコード内で，アップロード用プログラムを呼び出す

##常にPHPでwebページに出力するファイルは30個に設定しておく
sudo find /var/www/html/camera/video/*  -maxdepth 0 | sort | head -n -30 | xargs rm -rf
