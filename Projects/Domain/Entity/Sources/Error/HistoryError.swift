//
//  HistoryError.swift
//  Entity
//
//  Created by Wonji Suh  on 4/15/26.
//

import Foundation

public enum HistoryError: Error, LocalizedError, Equatable {
  // MARK: - History Fetch Errors
  case historyNotFound
  case invalidPageRequest(String)
  case historyDataCorrupted

  // MARK: - Journey Management Errors
  case journeyNotFound
  case journeyAlreadyStarted
  case journeyAlreadyEnded
  case journeyCreationFailed(String)
  case journeyUpdateFailed(String)
  case invalidJourneyInput(String)
  case journeyInProgress

  // MARK: - Permission Errors
  case unauthorizedAccess
  case journeyNotOwnedByUser

  // MARK: - Network & Server Errors
  case networkError(String)
  case serverError(String)

  // MARK: - General Errors
  case unknownError(String)
  case historyServiceUnavailable
  case invalidHistorySort

  public var errorDescription: String? {
    switch self {
    // History Fetch Errors
    case .historyNotFound:
      return "여행 기록을 찾을 수 없습니다"
    case .invalidPageRequest(let message):
      return "잘못된 페이지 요청입니다: \(message)"
    case .historyDataCorrupted:
      return "여행 기록 데이터가 손상되었습니다"

    // Journey Management Errors
    case .journeyNotFound:
      return "여정을 찾을 수 없습니다"
    case .journeyAlreadyStarted:
      return "이미 시작된 여정입니다"
    case .journeyAlreadyEnded:
      return "이미 종료된 여정입니다"
    case .journeyCreationFailed(let message):
      return "여정 생성에 실패했습니다: \(message)"
    case .journeyUpdateFailed(let message):
      return "여정 업데이트에 실패했습니다: \(message)"
    case .invalidJourneyInput(let message):
      return "잘못된 여정 정보입니다: \(message)"
    case .journeyInProgress:
      return "진행 중인 여정이 있습니다"

    // Permission Errors
    case .unauthorizedAccess:
      return "접근 권한이 없습니다"
    case .journeyNotOwnedByUser:
      return "다른 사용자의 여정입니다"

    // Network & Server Errors
    case .networkError(let message):
      return "네트워크 오류: \(message)"
    case .serverError(let message):
      return "서버 오류: \(message)"

    // General Errors
    case .unknownError(let message):
      return "알 수 없는 오류가 발생했습니다: \(message)"
    case .historyServiceUnavailable:
      return "여행 기록 서비스를 현재 이용할 수 없습니다"
    case .invalidHistorySort:
      return "잘못된 정렬 옵션입니다"
    }
  }

  public var failureReason: String? {
    switch self {
    case .historyNotFound:
      return "여행 기록 조회 실패"
    case .journeyNotFound:
      return "여정 조회 실패"
    case .journeyCreationFailed:
      return "여정 생성 실패"
    case .journeyUpdateFailed:
      return "여정 업데이트 실패"
    case .unauthorizedAccess:
      return "권한 검증 실패"
    case .networkError:
      return "네트워크 연결 실패"
    case .serverError:
      return "서버 처리 실패"
    default:
      return nil
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .historyNotFound:
      return "새로고침하거나 여행을 시작해 보세요"
    case .journeyAlreadyStarted:
      return "이전 여정을 종료한 후 새로운 여정을 시작해 주세요"
    case .journeyInProgress:
      return "현재 진행 중인 여정을 먼저 완료해 주세요"
    case .unauthorizedAccess, .journeyNotOwnedByUser:
      return "로그인을 다시 시도해 주세요"
    case .networkError:
      return "인터넷 연결을 확인하고 다시 시도해 주세요"
    case .historyServiceUnavailable:
      return "잠시 후 다시 시도해 주세요"
    default:
      return "문제가 지속되면 고객센터에 문의해 주세요"
    }
  }
}

// MARK: - Convenience Methods

public extension HistoryError {
  static func from(_ error: Error) -> HistoryError {
    if let historyError = error as? HistoryError {
      return historyError
    }
    return .unknownError(error.localizedDescription)
  }

  /// 여정 관련 에러인지 확인
  var isJourneyError: Bool {
    switch self {
    case .journeyNotFound, .journeyAlreadyStarted, .journeyAlreadyEnded,
         .journeyCreationFailed, .journeyUpdateFailed, .invalidJourneyInput,
         .journeyInProgress:
      return true
    default:
      return false
    }
  }

  /// 권한 관련 에러인지 확인
  var isPermissionError: Bool {
    switch self {
    case .unauthorizedAccess, .journeyNotOwnedByUser:
      return true
    default:
      return false
    }
  }

  /// 네트워크 관련 에러인지 확인
  var isNetworkError: Bool {
    switch self {
    case .networkError:
      return true
    default:
      return false
    }
  }

  /// 재시도 가능한 에러인지 확인
  var isRetryable: Bool {
    switch self {
    case .networkError, .serverError, .historyServiceUnavailable:
      return true
    default:
      return false
    }
  }

  /// 여정 상태 충돌 에러인지 확인
  var isJourneyStateConflict: Bool {
    switch self {
    case .journeyAlreadyStarted, .journeyAlreadyEnded, .journeyInProgress:
      return true
    default:
      return false
    }
  }
}