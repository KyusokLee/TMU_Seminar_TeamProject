//
//  Sender.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/07.
//

import MessageKit

// MARK: - 送信者の分岐
// 
struct Sender: SenderType {
    // 送信者ID
    var senderId: String
    // 送信者の表示名
    var displayName: String
}
