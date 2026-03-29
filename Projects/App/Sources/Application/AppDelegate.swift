//
//  AppDelegate.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import UIKit
import WeaveDI
import Home
import Kingfisher


class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    WeaveDI.Container.bootstrapInTask { @DIContainerActor _ in
      await AppDIManager.shared.registerDefaultDependencies()
    }

    // Kingfisher 캐시 최적화 설정
    configureImageCaching()

    // 네이버맵 초기화 (Home 모듈의 NaverMapInitializer 사용)
    NaverMapInitializer.initialize()

    return true
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
  }

  // MARK: - Image Caching Configuration
  private func configureImageCaching() {
    let cache = ImageCache.default

    // 메모리 캐시 설정 - 50MB로 제한
    cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024

    // 디스크 캐시 설정 - 200MB로 제한, 1주일 보관
    cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
    cache.diskStorage.config.expiration = .days(7)

    // 이미지 다운로드 설정 (Google Places API 최적화)
    let modifier = AnyModifier { request in
      var r = request
      r.setValue("image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
      r.setValue("TimeSpot-iOS/1.0", forHTTPHeaderField: "User-Agent")
      r.cachePolicy = .useProtocolCachePolicy
      // Google Places API 이미지는 응답이 느릴 수 있으므로 타임아웃 증가
      r.timeoutInterval = 30.0
      return r
    }

    KingfisherManager.shared.defaultOptions = [
      .requestModifier(modifier),
      .backgroundDecode,
      .diskCacheExpiration(.days(1)), // Google Places 이미지는 1일만 캐시
      .memoryCacheExpiration(.seconds(300))
    ]

    // Google Places API를 위한 네트워크 최적화
    let config = KingfisherManager.shared.downloader.sessionConfiguration
    config.httpMaximumConnectionsPerHost = 6
    config.timeoutIntervalForRequest = 30.0
    config.timeoutIntervalForResource = 60.0
    config.waitsForConnectivity = true
  }
}
