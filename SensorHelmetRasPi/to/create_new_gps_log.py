import csv
import os

os.remove('/home/zemi/start/python_code/gps_log.csv')
f = open('/home/zemi/start/python_code/gps_log.csv', mode="a", newline="")
writer = csv.writer(f, lineterminator='\n')
writer.writerow(["時間", "緯度", "経度"])
f.close()
