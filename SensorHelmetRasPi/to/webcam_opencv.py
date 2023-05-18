##opencvを使用して，webカメラの動画を出力
import numpy as np
import cv2

cap = cv2.VideoCapture(0)

while(True):
    ret, frame = cap.read()
    cv2.imshow('frame',frame)

    key = cv2.waitKey(1)

    if key == ord('q'):
        break
    if key == ord('s'):
        path = "photo.jpg"
        cv2.imwrite(path,frame)

cap.release()
cv2.destroyAllWindows()
