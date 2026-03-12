//
//  NaverMapInitializer.swift
//  Home
//
//  Created by Claude on 3/12/26.
//

import Foundation
import NMapsMap

public final class NaverMapInitializer {
    public static let shared = NaverMapInitializer()

    private init() {}

    public func initialize() {
        let clientId = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientId") as? String ?? ""
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientSecret") as? String ?? ""
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"

        print("🔴 [CRITICAL] 실제 Bundle ID: \(bundleId)")
        print("🔴 [CRITICAL] 실제 Client ID: \(clientId)")
        print("🔴 [CRITICAL] Client Secret: \(clientSecret.prefix(10))...")

        // Bundle ID 검증
        if bundleId != "io.TimeSpot.co" {
            print("🚨 [ERROR] Bundle ID 불일치!")
            print("🚨 [ERROR] 예상: io.TimeSpot.co")
            print("🚨 [ERROR] 실제: \(bundleId)")
        } else {
            print("✅ [SUCCESS] Bundle ID 일치: io.TimeSpot.co")
        }

        // 네이버 공식 iOS 지도 SDK 초기화
      NMFAuthManager.shared().ncpKeyId = "dt5ybexksb"


        print("✅ [네이버맵] 공식 SDK 초기화 완료")

        if !clientSecret.isEmpty {
            // 네이버 클라우드 플랫폼 API 사용 시 Client Secret 설정
            print("🗺️ [네이버맵] Client Secret 설정됨")
            // NMFAuthManager.shared().ncpClientSecret = clientSecret // API에 따라 필요시 추가
        }
    }
}
