import socket
import time
import datetime
import requests
import gspread

#Google Spread Sheet
gc = gspread.service_account(filename='/home/zemi/iot-project-for-b3-bb3ffe230d41.json')
ss = gc.open("py-IoT")
sheet_name = 'sheet1'
row = 2
collumn = 6
t = datetime.datetime.today()
#ipアドレスを取得
connect_interface = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
connect_interface.connect(("8.8.8.8", 80))
#print(connect_interface.getsockname()[0])

ss.sheet1.update_cell(row,collumn ,connect_interface.getsockname()[0])
ss.sheet1.update_cell(row, (collumn+2), t.strftime("%Y/%m/%d,%H:%M"))
connect_interface.close()
