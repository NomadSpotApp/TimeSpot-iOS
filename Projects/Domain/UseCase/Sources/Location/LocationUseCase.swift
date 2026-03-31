//
//  LocationUseCase.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import CoreLocation
import ComposableArchitecture
import DomainInterface

// MARK: - LocationUseCaseInterface Protocol

public protocol LocationUseCaseInterface: Sendable {
  /// 위치 권한 상태 확인
  func getAuthorizationStatus() async -> CLAuthorizationStatus

  /// 위치 권한 요청
  func requestLocationPermission() async -> CLAuthorizationStatus

  /// 정확도 개선 요청
  func requestFullAccuracy() async

  /// 위치 업데이트 시작 및 콜백 설정
  func startLocationUpdates(
    onUpdate: @escaping @Sendable (CLLocation) -> Void,
    onError: @escaping @Sendable (Error) -> Void
  ) async

  /// 위치 업데이트 중지
  func stopLocationUpdates() async

  /// 현재 위치 한번만 요청
  func requestCurrentLocation() async throws -> CLLocation?

  /// 위치 서비스 사용 가능 여부
  func isLocationServicesEnabled() async -> Bool
}

// MARK: - LocationUseCaseImpl

public struct LocationUseCaseImpl: LocationUseCaseInterface {
  public init() {}

  public func getAuthorizationStatus() async -> CLAuthorizationStatus {
    await MainActor.run {
      LocationPermissionManager.shared.authorizationStatus
    }
  }

  public func requestLocationPermission() async -> CLAuthorizationStatus {
    await LocationPermissionManager.shared.requestLocationPermission()
  }

  public func requestFullAccuracy() async {
    await LocationPermissionManager.shared.requestFullAccuracy()
  }

  public func startLocationUpdates(
    onUpdate: @escaping @Sendable (CLLocation) -> Void,
    onError: @escaping @Sendable (Error) -> Void
  ) async {
    await LocationPermissionManager.shared.setLocationUpdateCallback(onUpdate)
    await LocationPermissionManager.shared.setLocationErrorCallback(onError)
    await LocationPermissionManager.shared.startLocationUpdates()
  }

  public func stopLocationUpdates() async {
    await LocationPermissionManager.shared.stopLocationUpdates()
  }

  public func requestCurrentLocation() async throws -> CLLocation? {
    try await LocationPermissionManager.shared.requestCurrentLocation()
  }

  public func isLocationServicesEnabled() async -> Bool {
    await LocationPermissionManager.shared.isLocationServicesEnabled()
  }
}

// MARK: - Dependency Extension

extension DependencyValues {
  public var locationUseCase: LocationUseCaseInterface {
    get { self[LocationUseCaseKey.self] }
    set { self[LocationUseCaseKey.self] = newValue }
  }
}

private enum LocationUseCaseKey: DependencyKey {
  static let liveValue: LocationUseCaseInterface = LocationUseCaseImpl()
}
