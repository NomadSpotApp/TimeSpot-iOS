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
import LogMacro


final class AppDelegate: UIResponder, UIApplicationDelegate, @MainActor UNUserNotificationCenterDelegate {
  @Dependency(\.deeplinkRouter) var deeplinkRouter
  @Dependency(\.authUseCase) var authUseCase

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

    let center = UNUserNotificationCenter.current()
    center.delegate = self

    // iOS 17+ 호환 배지 초기화
//    if #available(iOS 17.0, *) {
//      center.setBadgeCount(0) { error in
//        if let error = error {
//          #logDebug("🔔 Failed to set badge count: \(error)")
//        }
//      }
//    } else {
//      application.applicationIconBadgeNumber = 0
//    }

    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        #logDebug("🔔 Notification auth error:", error)
        return
      }

      guard granted else {
        #logDebug("🔔 Notification permission not granted")
        return
      }

      Task { @MainActor in
        UIApplication.shared.registerForRemoteNotifications()
      }
    }

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

extension AppDelegate {
  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return false
  }

  // APNs 토큰 성공
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set(tokenString, forKey: "Token")


    Task.detached(priority: .utility) {
      do {
        try await Task.sleep(for: .seconds(0.3))
        _ = try await self.authUseCase.registerNotification(with: tokenString)
      } catch {
        #logDebug("🔔 Failed to register device token: \(error.localizedDescription)")
      }
    }
  }

  // APNs 토큰 실패
  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {

  }

  // 포그라운드 알림 표시
  @MainActor
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }

  // 알림 터치 처리
  @MainActor
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    if let urlString = self.deeplinkRouter.extractDeepLink(from: userInfo) {
      #logDebug("🔗 Processing push notification deep link: \(urlString)")

      // UserDefaults에도 저장 (앱이 종료된 상태에서 푸시 알림을 탭한 경우 대비)
      UserDefaults.standard.set(urlString, forKey: UserDefaultsKey.pendingPushDeepLink.rawValue)

      NotificationCenter.default.post(
        name: .pushNotificationDeepLink,
        object: nil,
        userInfo: [
          "url": urlString,
          "deeplink_type": "push"
        ]
      )
    }

    completionHandler()
  }
}

extension Notification.Name {
  static let pushNotificationDeepLink = Notification.Name("pushNotificationDeepLink")
}

enum UserDefaultsKey: String {
  case pendingPushDeepLink
}
