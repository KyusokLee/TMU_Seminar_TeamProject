//
//  ErrorType.swift
//  SensorHelmetMobileApp
//
//  Created by Kyus'lee on 2023/11/28.
//

import Foundation

enum ErrorType: Error {
    case firestoreError(Error?)
    case decodedError(Error?)
}
