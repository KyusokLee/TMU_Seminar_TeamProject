## TMU 朝香ラボのゼミ研究（自由研究）_IoT防災ヘルメットの実装

<img src="https://user-images.githubusercontent.com/89962765/227458410-631e8762-2d23-452a-9664-006371b29e2f.png" width="150" height="150"/>

## 💻 開発者紹介

|Kyusok|Takumi|
|:-:|:-:|
|<img src="https://avatars.githubusercontent.com/u/89962765?v=4" width="200">|<img src="https://avatars.githubusercontent.com/u/117294735?v=4" width="200">|


### 🎥デモ動画
- YouTube 上(限定公開)で，機能を簡潔にまとめた動画を視聴可能
https://youtu.be/i7PPeif4L5I

#### ~ 細かい機能の説明 ~
- Raspberry Piを用いて収集した現地情報を提供し、ヘルメットの現在位置をMapで表示

![SensorHelmet_demo_takeSensorData_and_presentLocation](https://user-images.githubusercontent.com/89962765/227456583-0cb47d3f-cfc3-427e-85b2-5f9af4ef8698.gif)

- ヘルメットの位置に近づいたら(100m)、装着可能にする

![SensorHelmet_demo_takeHelmetAndPresentPlaceToEscape](https://user-images.githubusercontent.com/89962765/227457552-a540821b-e2c0-465f-b08e-189fa149479a.gif)

- ヘルメットに装着したカメラモジュールから保存した映像データを閲覧

![SensorHelmet_demo_watchVideoList_certainVideo](https://user-images.githubusercontent.com/89962765/227791354-328d15c8-9f11-44bd-bec6-e0dca8588dff.gif)

- 災害発生時、通知を送り、ユーザの迅速な対応をサポートする

![SensorHelmet_demo_notRealAlarmPush](https://user-images.githubusercontent.com/89962765/227791551-c95c11a4-c853-41e3-b0c6-92aef2f56f42.gif)






## 📮 概要

本プロジェクトは朝香ラボのゼミ研究（自由研究の形式）であり、ラズベリーパイとiOSモバイルアプリ、そして、Firebaseを用いて災害地と避難所の共有を目的としたプロジェクトである

## 📌 目的

災害地や避難所といった情報を災害時にリアルタイムで提供することで、現地の人々の防災のための判断を促す新たな選択肢を提供することを目的とする

## ⚒ 実装方法

ラズベリーパイに装着した温湿度センサー等のモジュールを用いて30秒ごとにデータ計測・動画の撮影を行い、更新したデータと動画をそれぞれ、FirebaseのFirestoreデータベースとStorageに書き込む。ユーザ側にデータを提供する手段としてWebサーバとiOSモバイルアプリを用い、災害発生時の現地情報を収集・閲覧することが可能とする

* Webサーバ
  * アプリだけだと利用できるユーザ層に限界があると考え、官公庁などのステークホルダーに情報を無条件に提供するために実装
  * リアルタイムストリーミング配信、移動履歴をマップ形式で確認できる

* iOSモバイルアプリ
  * 多くのユーザが使っているモバイルプラットフォームのプロダクトであると、ユーザがより簡単に情報収集・閲覧することが可能となり、災害時の迅速な対応ができると考え、実装
  * 災害の発生を想定した通知機能、ヘルメットの現在位置・避難所までの経路の表示に加え、そのヘルメットで撮影された過去の動画を閲覧することが可能

## 📚 プロジェクト仕様
### ラズベリーパイ
* 使用センサ類
  * 温湿度センサ (DHT11)
  * GPSセンサモジュール (NEO-6M GPSモジュール(NEO-6M-0-001))
  * web カメラ (EMEET C960)
### iOSモバイルアプリ
* 技術スタック
  * Swift/UIKit
  * Firebase(FireStore, Storage機能)

* 外部ライブラリの管理ツール
  * SPMを利用
