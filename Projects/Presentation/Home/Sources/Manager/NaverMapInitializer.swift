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

        // 네이버 공식 iOS 지도 SDK 초기화
      let clientId = Bundle.main.object(forInfoDictionaryKey: "NMFGovClientId") as? String ?? ""
      NMFAuthManager.shared().ncpKeyId = clientId


        print("✅ [네이버맵] 공식 SDK 초기화 완료")

    }
}
