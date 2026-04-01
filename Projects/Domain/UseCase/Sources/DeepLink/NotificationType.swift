//
//  NotificationType.swift
//  UseCase
//
//  Created by Wonji Suh  on 4/1/26.
//

import Foundation

public enum NotificationType: Equatable, CaseIterable {
  case now        // 지금 바로 출발
  case fiveMin    // 5분 전
  case tenMin     // 10분 전
  case fifteenMin // 15분 전
  case endJourney // 여정 종료

  public var title: String {
    switch self {
    case .now:
      return "지금 바로 출발해야 해요!"
    case .fiveMin:
      return "5분 뒤면 역으로 출발 일어날 채비를 할 시간이에요."
    case .tenMin:
      return "10분 뒤면 역으로 출발해야 해요!"
    case .fifteenMin:
      return "역으로 출발하기까지 15분 남았어요!"
    case .endJourney:
      return "무사히 탑승하셨나요?"
    }
  }

  public var subtitle: String {
    switch self {
    case .now:
      return "지금 바로 역으로 향해야 15분 전에 플랫폼에 도착할 수 있어요."
    case .fiveMin:
      return "잠시 후 출발할 수 있도록 미리 준비해주세요."
    case .tenMin:
      return "이제 슬슬 일어날 준비를 해볼까요?"
    case .fifteenMin:
      return "지금 하는 활동을 차분히 마무리해 주세요."
    case .endJourney:
      return "오늘 대기 시간이 맞진 여행이 되었어요.\n이제 편안한 여정 되세요!"
    }
  }

  public static func from(deepLink: String) -> NotificationType {
    guard let url = URL(string: deepLink) else {
      return .now
    }

    // URL host/path 체크 (timespot://departure_time 등)
    let pathComponents = url.pathComponents.filter { $0 != "/" }
    let hostOrPath = url.host ?? pathComponents.first ?? ""

    switch hostOrPath {
    case "departure_time":
      return .now
    case "end_journey":
      return .endJourney
    case let path where path.contains("15_min_before"):
      return .fifteenMin
    case let path where path.contains("10_min_before"):
      return .tenMin
    case let path where path.contains("5_min_before"):
      return .fiveMin
    default:
      break
    }

    // URL에서 notificationType 파라미터 추출
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let notificationTypeParam = components.queryItems?.first(where: { $0.name == "notificationType" })?.value {

      switch notificationTypeParam {
      case "BEFORE_15_MINUTES":
        return .fifteenMin
      case "BEFORE_10_MINUTES":
        return .tenMin
      case "BEFORE_5_MINUTES":
        return .fiveMin
      case "DEPARTURE_TIME":
        return .now
      case "END_JOURNEY":
        return .endJourney
      default:
        return .now
      }
    }

    // 기존 방식도 유지 (fallback)
    if deepLink.contains("15_min_before") {
      return .fifteenMin
    } else if deepLink.contains("10_min_before") {
      return .tenMin
    } else if deepLink.contains("5_min_before") {
      return .fiveMin
    } else {
      return .now
    }
  }
}

