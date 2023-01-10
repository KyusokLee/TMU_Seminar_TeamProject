##capture camera footage and move mp4 files
##1~5分おきに実行

##動画を保存
python3 /home/zemi/start/python_code/webcam_to_php.py

##動画をアップロード
python3 /home/zemi/start/python_code/uploadToFirebase.py
##アップロードに成功したら実行するコマンド
##sudo mv /home/zemi/start/python_code/video/* /var/www/html/camera/video

##常にPHPでwebページに出力するファイルは30個に設定しておく
sudo find /var/www/html/camera/video/*  -maxdepth 0 | sort | head -n -30 | xargs rm -rf

