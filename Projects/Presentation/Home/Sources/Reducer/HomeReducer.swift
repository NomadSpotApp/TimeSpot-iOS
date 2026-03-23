//
//  HomeReducer.swift
//  Home
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture
import CoreLocation
import UseCase
import Entity

@Reducer
public struct HomeReducer: Sendable {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    public var currentLocation: CLLocation?
    public var isLocationPermissionDenied: Bool = false
    public var locationError: String?
    @Presents public var alert: AlertState<Alert>?

    // 길찾기 관련 상태
    public var selectedDestination: Destination?
    public var routeInfo: RouteInfo?
    public var isLoadingRoute: Bool = false
    public var routeError: String?

    // 지도 카메라 제어
    public var shouldReturnToCurrentLocation: Bool = false

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case async(AsyncAction)
    case scope(ScopeAction)
  }

  @CasePathable
  public enum ScopeAction {
    case alert(PresentationAction<Alert>)
  }

  public enum Alert: Equatable {
    case confirmLocationPermission
    case cancelLocationPermission
    case openSettings
    case dismissAlert
  }

  @CasePathable
  public enum View {
    case onAppear
    case onDisappear
    case requestLocationPermission
    case retryLocationPermission
    case requestFullAccuracy
    case openSettings
    // 길찾기 관련 액션
    case searchRouteToGangnam
    case clearRoute
    case returnToCurrentLocation
  }

  public enum InnerAction: Equatable {
    case locationPermissionStatusChanged(CLAuthorizationStatus)
    case locationUpdated(CLLocation)
    case locationUpdateFailed(String)
    // 길찾기 관련 액션
    case routeSearchStarted(Destination)
    case routeSearchResponse(Result<RouteInfo, DirectionError>)
    // 지도 카메라 제어
    case resetCameraFlag
  }

  public enum AsyncAction: Equatable {
    case requestLocationPermission
    case requestFullAccuracy
    case startLocationUpdates
    case stopLocationUpdates
    // 길찾기 관련 액션
    case searchRoute(from: CLLocationCoordinate2D, to: Destination)

    public static func == (lhs: AsyncAction, rhs: AsyncAction) -> Bool {
      switch (lhs, rhs) {
      case (.requestLocationPermission, .requestLocationPermission),
           (.requestFullAccuracy, .requestFullAccuracy),
           (.startLocationUpdates, .startLocationUpdates),
           (.stopLocationUpdates, .stopLocationUpdates):
        return true
      case (.searchRoute(let lhsFrom, let lhsTo), .searchRoute(let rhsFrom, let rhsTo)):
        return lhsFrom.latitude == rhsFrom.latitude &&
               lhsFrom.longitude == rhsFrom.longitude &&
               lhsTo == rhsTo
      default:
        return false
      }
    }
  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        case .view(let viewAction):
          return handleViewAction(state: &state, action: viewAction)

        case .inner(let innerAction):
          return handleInnerAction(state: &state, action: innerAction)

        case .async(let asyncAction):
          return handleAsyncAction(state: &state, action: asyncAction)

        case .scope(let scopeAction):
          return handleScopeAction(state: &state, action: scopeAction)
      }
    }
    .ifLet(\.$alert, action: \.scope.alert)
  }
}

extension HomeReducer {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        // 앱이 나타날 때 위치 권한 상태 확인 - UI 블로킹 방지
        return .run { send in
          let locationManager = await LocationPermissionManager.shared
          let currentStatus = await locationManager.authorizationStatus
          await send(.inner(.locationPermissionStatusChanged(currentStatus)))
        }

      case .onDisappear:
        return .send(.async(.stopLocationUpdates))

      case .requestLocationPermission:
        return .send(.async(.requestLocationPermission))

      case .retryLocationPermission:
        state.isLocationPermissionDenied = false
        return .send(.async(.requestLocationPermission))

      case .requestFullAccuracy:
        return .send(.async(.requestFullAccuracy))

      case .openSettings:
        return .run { send in
          await MainActor.run {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsUrl) else {
              return
            }
            UIApplication.shared.open(settingsUrl)
          }
        }

      // 길찾기 관련 액션
      case .searchRouteToGangnam:
        guard let currentLocation = state.currentLocation else {
          state.routeError = "현재 위치를 확인할 수 없습니다"
          return .none
        }

        let destination = PredefinedDestinations.gangnamStation
        return .send(.async(.searchRoute(
          from: currentLocation.coordinate,
          to: destination
        )))

      case .clearRoute:
        state.selectedDestination = nil
        state.routeInfo = nil
        state.routeError = nil
        return .none

      case .returnToCurrentLocation:
        // 현재 위치로 지도 중심 이동
        state.shouldReturnToCurrentLocation = true
        return .run { send in
          // 0.1초 후에 플래그를 리셋 (지도 업데이트 후)
          try await Task.sleep(for: .milliseconds(100))
          await send(.inner(.resetCameraFlag))
        }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case .locationPermissionStatusChanged(let status):
        state.locationPermissionStatus = status

        switch status {
          case .authorizedWhenInUse, .authorizedAlways:
            state.isLocationPermissionDenied = false
            state.alert = nil
            return .send(.async(.startLocationUpdates))
          case .denied, .restricted:
            state.isLocationPermissionDenied = true
            state.alert = AlertState {
              TextState("위치 권한이 거부되었습니다")
            } actions: {
              ButtonState(action: Alert.openSettings) {
                TextState("설정으로 이동")
              }
              ButtonState(role: .cancel, action: Alert.dismissAlert) {
                TextState("나중에")
              }
            } message: {
              TextState("위치 기반 서비스를 사용하려면 설정에서 위치 권한을 허용해주세요.")
            }
            return .send(.async(.stopLocationUpdates))
          case .notDetermined:
            state.alert = AlertState {
              TextState("위치 권한이 필요합니다")
            } actions: {
              ButtonState(action: Alert.confirmLocationPermission) {
                TextState("허용")
              }
              ButtonState(role: .cancel, action: Alert.cancelLocationPermission) {
                TextState("취소")
              }
            } message: {
              TextState("TimeSpot이 근처 장소를 찾고 지도에 현재 위치를 표시하기 위해 위치 정보가 필요합니다.")
            }
            return .none
          @unknown default:
            return .none
        }

      case .locationUpdated(let location):
        state.currentLocation = location
        return .none

      case .locationUpdateFailed(let error):
        print("위치 업데이트 실패: \(error)")
        return .none

      // 길찾기 관련 액션
      case .routeSearchStarted(let destination):
        state.selectedDestination = destination
        state.isLoadingRoute = true
        state.routeError = nil
        return .none

      case .routeSearchResponse(let result):
        state.isLoadingRoute = false
        switch result {
        case .success(let routeInfo):
          state.routeInfo = routeInfo
          state.routeError = nil
          print("✅ 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
        case .failure(let error):
          state.routeError = error.localizedDescription
          print("🚨 경로 검색 실패: \(error.localizedDescription)")
        }
        return .none

      case .resetCameraFlag:
        state.shouldReturnToCurrentLocation = false
        return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .requestLocationPermission:
        return .run { send in
          let locationManager = await LocationPermissionManager.shared
          let status = await locationManager.requestLocationPermission()

          await send(.inner(.locationPermissionStatusChanged(status)))

          // 권한이 허용되면 현재 위치 가져오기 시작
          if status == .authorizedWhenInUse || status == .authorizedAlways {
            await locationManager.startLocationUpdates()

            do {
              if let location = try await locationManager.requestCurrentLocation() {
                await send(.inner(.locationUpdated(location)))
              }
            } catch {
              await send(.inner(.locationUpdateFailed(error.localizedDescription)))
            }
          }

          if let error = await locationManager.locationError {
            await send(.inner(.locationUpdateFailed(error)))
          }
        }

      case .requestFullAccuracy:
        return .run { send in
          await MainActor.run {
            let locationManager = LocationPermissionManager.shared
            locationManager.requestFullAccuracy()

            Task {
              try await Task.sleep(for: .seconds(1))
              await send(.async(.startLocationUpdates))
            }
          }
        }

      case .startLocationUpdates:
        return .run { send in
          let locationManager = await LocationPermissionManager.shared

          // 지속적인 위치 업데이트 콜백 설정 (MainActor에서 실행)
          await MainActor.run {
            locationManager.onLocationUpdate = { location in
              Task { @MainActor in
                await send(.inner(.locationUpdated(location)))
              }
            }

            locationManager.onLocationError = { error in
              Task { @MainActor in
                await send(.inner(.locationUpdateFailed(error.localizedDescription)))
              }
            }
          }

          await locationManager.startLocationUpdates()

          // 초기 위치도 가져오기
          do {
            if let location = try await locationManager.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            }
          } catch {
            await send(.inner(.locationUpdateFailed(error.localizedDescription)))
          }
        }

      case .stopLocationUpdates:
        return .run { send in
          await MainActor.run {
            let locationManager = LocationPermissionManager.shared
            locationManager.stopLocationUpdates()
          }
        }

      // 길찾기 관련 액션
      case .searchRoute(let from, let destination):
        return .run { send in
          // 경로 검색 시작 알림
          await send(.inner(.routeSearchStarted(destination)))

          let routeResult = await Result {
            try await getRouteUseCase.execute(
              from: from,
              to: destination.coordinate,
              option: .traoptimal  // 최적 경로로 변경
            )
          }
          .mapError(DirectionError.from)

          await send(.inner(.routeSearchResponse(routeResult)))
        }
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
      case .alert(let alertAction):
        return handleAlertAction(state: &state, action: alertAction)
    }
  }

  private func handleAlertAction(
    state: inout State,
    action: PresentationAction<Alert>
  ) -> Effect<Action> {
    switch action {
      case .presented(let alertAction):
        switch alertAction {
          case .confirmLocationPermission:
            state.alert = nil
            return .send(.view(.requestLocationPermission))

          case .cancelLocationPermission:
            state.alert = nil
            return .none

          case .openSettings:
            state.alert = nil
            return .send(.view(.openSettings))

          case .dismissAlert:
            state.alert = nil
            return .none
        }

      case .dismiss:
        state.alert = nil
        return .none
    }
  }
}
