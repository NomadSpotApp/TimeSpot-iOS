//
//  StationError.swift
//  Entity
//
//  Created by Wonji Suh  on 4/15/26.
//

import Foundation

public enum StationError: Error, LocalizedError, Equatable {
  // MARK: - Station Fetch Errors
  case stationNotFound
  case invalidLocation(String)
  case outOfServiceArea

  // MARK: - Favorite Station Errors
  case favoriteStationNotFound
  case alreadyFavoriteStation
  case favoriteStationLimitExceeded
  case favoriteMutationFailed(String)

  // MARK: - Network & Server Errors
  case networkError(String)
  case serverError(String)

  // MARK: - General Errors
  case unknownError(String)
  case invalidStationID
  case stationServiceUnavailable

  public var errorDescription: String? {
    switch self {
    // Station Fetch Errors
    case .stationNotFound:
      return "역 정보를 찾을 수 없습니다"
    case .invalidLocation(let message):
      return "위치 정보가 잘못되었습니다: \(message)"
    case .outOfServiceArea:
      return "서비스 지역 밖입니다"

    // Favorite Station Errors
    case .favoriteStationNotFound:
      return "즐겨찾기 역을 찾을 수 없습니다"
    case .alreadyFavoriteStation:
      return "이미 즐겨찾기에 추가된 역입니다"
    case .favoriteStationLimitExceeded:
      return "즐겨찾기는 최대 10개까지 추가할 수 있습니다"
    case .favoriteMutationFailed(let message):
      return "즐겨찾기 변경에 실패했습니다: \(message)"

    // Network & Server Errors
    case .networkError(let message):
      return "네트워크 오류: \(message)"
    case .serverError(let message):
      return "서버 오류: \(message)"

    // General Errors
    case .unknownError(let message):
      return "알 수 없는 오류가 발생했습니다: \(message)"
    case .invalidStationID:
      return "잘못된 역 ID입니다"
    case .stationServiceUnavailable:
      return "역 서비스를 현재 이용할 수 없습니다"
    }
  }

  public var failureReason: String? {
    switch self {
    case .stationNotFound:
      return "역 정보 조회 실패"
    case .invalidLocation:
      return "위치 정보 검증 실패"
    case .outOfServiceArea:
      return "서비스 지역 확인 실패"
    case .favoriteStationNotFound:
      return "즐겨찾기 조회 실패"
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
    case .stationNotFound:
      return "다른 역을 선택하거나 새로고침해 주세요"
    case .invalidLocation:
      return "위치 권한을 확인하고 GPS를 활성화해 주세요"
    case .outOfServiceArea:
      return "서비스 지역 내의 역을 선택해 주세요"
    case .favoriteStationLimitExceeded:
      return "기존 즐겨찾기를 삭제한 후 다시 시도해 주세요"
    case .networkError:
      return "인터넷 연결을 확인하고 다시 시도해 주세요"
    case .stationServiceUnavailable:
      return "잠시 후 다시 시도해 주세요"
    default:
      return "문제가 지속되면 고객센터에 문의해 주세요"
    }
  }
}

// MARK: - Convenience Methods

public extension StationError {
  static func from(_ error: Error) -> StationError {
    if let stationError = error as? StationError {
      return stationError
    }
    return .unknownError(error.localizedDescription)
  }

  /// 즐겨찾기 관련 에러인지 확인
  var isFavoriteError: Bool {
    switch self {
    case .favoriteStationNotFound, .alreadyFavoriteStation,
         .favoriteStationLimitExceeded, .favoriteMutationFailed:
      return true
    default:
      return false
    }
  }

  /// 위치 관련 에러인지 확인
  var isLocationError: Bool {
    switch self {
    case .invalidLocation, .outOfServiceArea:
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
    case .networkError, .serverError, .stationServiceUnavailable:
      return true
    default:
      return false
    }
  }
}