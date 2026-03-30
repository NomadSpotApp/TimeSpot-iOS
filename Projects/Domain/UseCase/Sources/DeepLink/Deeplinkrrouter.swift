//
//  DeeplinkRouter.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation
import Dependencies
import LogMacro

public struct DeeplinkRouter: Sendable {

    public init() {}

    // MARK: - Public Interface

  public func parse(
    _ urlString: String
  ) -> DeeplinkResult {
        guard let url = URL(string: urlString),
              url.scheme == "sseudam" else {
            return .invalid(url: urlString, reason: "Invalid scheme")
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch url.host ?? pathComponents.first {
        case "route":
            return parseRouteDeeplink(url: url)
        default:
            return .success(.unknown(url: urlString))
        }
    }

    // MARK: - Private Parsing



  private func parseRouteDeeplink(
    url: URL
  ) -> DeeplinkResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .invalid(url: url.absoluteString, reason: "Invalid URL format")
        }

        var departureTime: String?
        var notificationMinutes: [Int] = []

        // Parse query parameters
        components.queryItems?.forEach { queryItem in
            switch queryItem.name {
            case "departure-time":
                departureTime = queryItem.value
            case "notification":
                // Parse notification time values like "5-min-before", "15-min-before", "10-min-before"
                if let value = queryItem.value {
                    if let minutes = parseNotificationMinutes(from: value) {
                        notificationMinutes.append(minutes)
                    }
                }
            default:
                break
            }
        }

        let routeDeeplink = RouteDeeplink(
            departureTime: departureTime,
            notificationMinutes: notificationMinutes.isEmpty ? nil : notificationMinutes
        )

        return .success(.route(routeDeeplink))
    }

  private func parseNotificationMinutes(from value: String) -> Int? {
        // Parse values like "5-min-before", "15-min-before", "10-min-before"
        let cleanValue = value.lowercased().replacingOccurrences(of: "-min-before", with: "")
        return Int(cleanValue)
    }


  public  func extractDeepLink(from userInfo: [AnyHashable: Any]) -> String? {
    #logDebug("🔍 푸시 알림 payload 분석 시작")
    #logDebug("📱 Available keys: \(userInfo.keys)")

    // 전체 payload 내용 출력 (디버깅용)
    for (key, value) in userInfo {
      #logDebug("📋 Key: \(key), Value: \(value), Type: \(type(of: value))")
    }

    // 1) 단일 문자열 필드 우선
    let stringKeys = ["deeplink", "url"]
    for key in stringKeys {
      if let url = userInfo[key] as? String {
        #logDebug("✅ 딥링크 발견 (단일): \(url)")
        return url
      }
    }

    // 2) 중첩 객체에서 url 필드 찾기 (customPayload 추가)
    let containerKeys = ["deeplink", "data", "custom", "customPayload"]
    for key in containerKeys {
      if let container = userInfo[key] as? [String: Any] {
        #logDebug("🔍 \(key) 컨테이너 내용: \(container)")

        // url 또는 deeplink 필드 확인
        for urlKey in ["url", "deeplink", "link"] {
          if let url = container[urlKey] as? String {
            #logDebug("✅ 딥링크 발견 (\(key).\(urlKey)): \(url)")
            return url
          }
        }
      }
    }

    // 3) APS 내부도 확인해보기
    if let aps = userInfo["aps"] as? [String: Any] {
      #logDebug("🔍 aps 내용: \(aps)")
    }

    #logDebug("❌ No deep link found in push notification")
    #logDebug("Available keys: \(userInfo.keys)")
    return nil
  }
}

// MARK: - Dependencies

extension DeeplinkRouter: DependencyKey {
    public static let liveValue = DeeplinkRouter()
    public static let testValue = DeeplinkRouter()
}

extension DependencyValues {
    public var deeplinkRouter: DeeplinkRouter {
        get { self[DeeplinkRouter.self] }
        set { self[DeeplinkRouter.self] = newValue }
    }
}



public enum DeeplinkDestination: Equatable, Sendable {
    case route(RouteDeeplink)
    case unknown(url: String)
}


public struct RouteDeeplink: Equatable, Sendable {
    public let departureTime: String?
    public let notificationMinutes: [Int]?

    public init(departureTime: String?, notificationMinutes: [Int]?) {
        self.departureTime = departureTime
        self.notificationMinutes = notificationMinutes
    }
}

public enum DeeplinkResult: Equatable, Sendable {
    case success(DeeplinkDestination)
    case invalid(url: String, reason: String)
}
