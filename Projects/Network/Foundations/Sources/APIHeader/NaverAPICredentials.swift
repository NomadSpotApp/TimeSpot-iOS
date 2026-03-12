//
//  NaverAPICredentials.swift
//  Foundations
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

// MARK: - Naver API 자격증명 관리
public struct NaverAPICredentials {
  public let clientId: String
  public let clientSecret: String

  // MARK: - Singleton (캐시된 자격증명)
  public static let shared: NaverAPICredentials = {
    guard let id = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientId") as? String,
          let secret = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientSecret") as? String,
          !id.isEmpty, !secret.isEmpty else {
      fatalError("🚨 [NaverAPI] Missing or invalid Naver API credentials in Bundle")
    }
    return NaverAPICredentials(clientId: id, clientSecret: secret)
  }()

  // MARK: - Headers 생성
  public var headers: [String: String] {
    return [
      "X-NCP-APIGW-API-KEY-ID": clientId,
      "X-NCP-APIGW-API-KEY": clientSecret,
      "Content-Type": "application/json"
    ]
  }

  private init(clientId: String, clientSecret: String) {
    self.clientId = clientId
    self.clientSecret = clientSecret
  }
}