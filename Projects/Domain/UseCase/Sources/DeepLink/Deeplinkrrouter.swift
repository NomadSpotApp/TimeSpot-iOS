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
        case "travel":
            return parseTravelDeeplink(url: url, pathComponents: pathComponents)
        case "invite":
            return parseInviteDeeplink(url: url)
        default:
            return .success(.unknown(url: urlString))
        }
    }

    // MARK: - Private Parsing

  private func parseTravelDeeplink(
    url: URL,
    pathComponents: [String]
  ) -> DeeplinkResult {
        guard let (travelId, remainingComponents) = extractTravelId(url: url, pathComponents: pathComponents),
              !travelId.isEmpty else {
            return .invalid(url: url.absoluteString, reason: "Missing travel ID")
        }

        let travelDeeplink: TravelDeeplink = {
            switch remainingComponents.first {
            case "settings":
                return .settings(travelId: travelId)
            case "expense" where remainingComponents.count >= 2:
                return .expense(travelId: travelId, expenseId: remainingComponents[1])
            case "settlement":
                return .settlement(travelId: travelId)
            default:
                return .detail(travelId: travelId)
            }
        }()

        return .success(.travel(travelDeeplink))
    }

  private func parseInviteDeeplink(
    url: URL
  ) -> DeeplinkResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let inviteCode = components.queryItems?.first(where: { $0.name == "code" })?.value,
              !inviteCode.isEmpty else {
            return .invalid(url: url.absoluteString, reason: "Missing invite code")
        }

        return .requiresLogin(destination: .invite(code: inviteCode))
    }

  private func extractTravelId(
    url: URL,
    pathComponents: [String]
  ) -> (String, [String])? {
        if pathComponents.first == "travel" && pathComponents.count >= 2 {
            // ["travel", "123", "expense", "456"]
            let travelId = pathComponents[1]
            let remaining = Array(pathComponents.dropFirst(2))
            return (travelId, remaining)
        } else if url.host == "travel" && pathComponents.count >= 1 {
            // host="travel", path=["123", "expense", "456"]
            let travelId = pathComponents[0]
            let remaining = Array(pathComponents.dropFirst(1))
            return (travelId, remaining)
        }
        return nil
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
    case travel(TravelDeeplink)
    case invite(code: String)
    case unknown(url: String)
}

public enum TravelDeeplink: Equatable, Sendable {
    case detail(travelId: String)
    case settings(travelId: String)
    case expense(travelId: String, expenseId: String)
    case settlement(travelId: String)
}

public enum DeeplinkResult: Equatable, Sendable {
    case success(DeeplinkDestination)
    case requiresLogin(destination: DeeplinkDestination)
    case invalid(url: String, reason: String)
}
