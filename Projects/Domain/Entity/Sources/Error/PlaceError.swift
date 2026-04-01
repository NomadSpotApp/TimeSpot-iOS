//
//  PlaceError.swift
//  Entity
//
//  Created by Codex on 3/29/26.
//

import Foundation

public enum PlaceError: Error, LocalizedError, Equatable, Hashable {
  case placeNotFound
  case placeAccessDenied
  case placeDataCorrupted
  case unknownError(String)
  case userCancelled
  case missingRequiredField(String)

  public var errorDescription: String? {
    switch self {
    case .placeNotFound:
      return "장소를 찾을 수 없습니다"
    case .placeAccessDenied:
      return "장소 접근이 거부되었습니다"
    case .placeDataCorrupted:
      return "장소 데이터가 손상되었습니다"
    case .unknownError(let message):
      return "알 수 없는 오류가 발생했습니다: \(message)"
    case .userCancelled:
      return "사용자가 취소했습니다"
    case .missingRequiredField(let field):
      return "\(field)은(는) 필수 입력 항목입니다"
    }
  }

  public var failureReason: String? {
    switch self {
    case .placeNotFound:
      return "장소 조회 실패"
    case .placeAccessDenied:
      return "장소 접근 권한 부족"
    default:
      return nil
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .placeNotFound:
      return "장소를 다시 선택하거나 잠시 후 다시 시도해주세요"
    case .placeAccessDenied:
      return "권한 상태를 확인하거나 다시 로그인해주세요"
    default:
      return "문제가 지속되면 고객센터에 문의해주세요"
    }
  }
}

public extension PlaceError {
  static func from(_ error: Error) -> PlaceError {
    if let placeError = error as? PlaceError {
      return placeError
    }
    return .unknownError(error.localizedDescription)
  }

  var shouldPresentAuth: Bool {
    switch self {
    case .placeAccessDenied:
      return true

    case .unknownError(let message):
      return message.contains("잘못된 AccessToken")
      || message.contains("유효하지 않은 토큰")
      || message.contains("해당 회원을 찾을 수 없습니다")
      || message.contains("statusCodeError(401)")
      || message.contains("401")

    default:
      return false
    }
  }
}
