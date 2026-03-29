//
//  CameraUseCase.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import CoreLocation
import Entity
import ComposableArchitecture

// MARK: - CameraUseCaseInterface Protocol

public protocol CameraUseCaseInterface: Sendable {
  /// 현재 위치로 돌아가기 트리거 생성
  func createReturnToCurrentLocationTrigger(
    currentTrigger: Int,
    hasCurrentLocation: Bool
  ) -> CameraControlResult

  /// 선택된 스팟 클리어 및 관련 상태 업데이트
  func clearSelectedSpotForLocationReturn(
    selectedSpotID: String,
    isCardVisible: Bool
  ) -> CameraControlResult

  /// 카메라 플래그 리셋
  func resetCameraFlag() -> CameraControlResult

  /// 위치 업데이트 시 카메라 트리거 처리
  func handleLocationUpdateForCamera(
    shouldReturnToLocation: Bool,
    currentTrigger: Int
  ) -> CameraControlResult
}

// MARK: - CameraUseCaseImpl

public struct CameraUseCaseImpl: CameraUseCaseInterface {
  public init() {}

  public func createReturnToCurrentLocationTrigger(
    currentTrigger: Int,
    hasCurrentLocation: Bool
  ) -> CameraControlResult {
    guard hasCurrentLocation else {
      return CameraControlResult(shouldResetFlag: false)
    }

    return CameraControlResult(
      shouldUpdateTrigger: true,
      newTrigger: currentTrigger + 1,
      shouldClearSpot: true
    )
  }

  public func clearSelectedSpotForLocationReturn(
    selectedSpotID: String,
    isCardVisible: Bool
  ) -> CameraControlResult {
    return CameraControlResult(
      shouldClearSpot: !selectedSpotID.isEmpty,
      shouldDismissCard: isCardVisible
    )
  }

  public func resetCameraFlag() -> CameraControlResult {
    return CameraControlResult(shouldResetFlag: true)
  }

  public func handleLocationUpdateForCamera(
    shouldReturnToLocation: Bool,
    currentTrigger: Int
  ) -> CameraControlResult {
    guard shouldReturnToLocation else {
      return CameraControlResult()
    }

    return CameraControlResult(
      shouldUpdateTrigger: true,
      newTrigger: currentTrigger + 1,
      shouldResetFlag: true
    )
  }
}

// MARK: - Dependency Extension

extension DependencyValues {
  public var cameraUseCase: CameraUseCaseInterface {
    get { self[CameraUseCaseKey.self] }
    set { self[CameraUseCaseKey.self] = newValue }
  }
}

private enum CameraUseCaseKey: DependencyKey {
  static let liveValue: CameraUseCaseInterface = CameraUseCaseImpl()
}
