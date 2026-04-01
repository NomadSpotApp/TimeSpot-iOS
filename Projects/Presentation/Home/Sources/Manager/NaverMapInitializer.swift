//
//  NaverMapInitializer.swift
//  Home
//
//  Created by Wonji Suh on 3/12/26.
//

import Foundation
import NMapsMap
import LogMacro

// MARK: - 네이버 지도 SDK 초기화 (Namespace)
public enum NaverMapInitializer {

  /// 네이버 지도 SDK 초기화 (앱 시작 시 한 번만 호출)
  public static func initialize() {
    let clientId = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientId") as? String ?? ""

    guard !clientId.isEmpty else {
      fatalError("🚨 [네이버맵] NMFGovClientId가 설정되지 않았습니다")
    }

    NMFAuthManager.shared().ncpKeyId = clientId
    #logDebug("✅ [네이버맵] 공식 SDK 초기화 완료 (ClientID: \(clientId.prefix(8))...)")
  }
}
