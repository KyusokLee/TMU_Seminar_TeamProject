##新しくCSVファイルを作成し，初期値入力
import csv
import os

os.remove('input path to csv file')
f = open('input path to csv file', mode="a", newline="")
writer = csv.writer(f, lineterminator='\n')
writer.writerow(["時間", "緯度", "経度"])
f.close()
