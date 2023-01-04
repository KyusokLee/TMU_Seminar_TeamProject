import time
import datetime
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

cred = credentials.Certificate("raspi.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

doc_ref = db.collection(u'Raspi').document(u'Database')
t = datetime.datetime.today()

## Data Write
doc_ref.set({
    u'date' : t.strftime('%Y年%m月%d日'),
    u'time' : t.strftime('%H:%M'),
    u'temp' : '18.00',
    u'humid' : '67.00'
})

## Data Update
# doc_ref.update({
#     u'temp' : '20.1'
# })

## Data Read
try:
    doc = doc_ref.get()
    print(u'Document data: {}'.format(doc.to_dict()))
except google.cloud.exceptions.NotFound:
    print(u'No such document!')
