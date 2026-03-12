//
//  HomeReducer.swift
//  Home
//
//  Created by Roy on 2026-03-11
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import UIKit
import ComposableArchitecture
import CoreLocation

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
    }

    public enum InnerAction: Equatable {
        case locationPermissionStatusChanged(CLAuthorizationStatus)
        case locationUpdated(CLLocation)
        case locationUpdateFailed(String)
    }

    public enum AsyncAction: Equatable {
        case requestLocationPermission
        case requestFullAccuracy
        case startLocationUpdates
        case stopLocationUpdates
    }

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
          // 앱이 나타날 때 위치 권한 상태 확인
          let currentStatus = CLLocationManager().authorizationStatus
          state.locationPermissionStatus = currentStatus

          switch currentStatus {
          case .notDetermined:
              // 권한 미결정 시 바로 팝업 표시
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
          case .authorizedWhenInUse, .authorizedAlways:
              return .send(.async(.startLocationUpdates))
          case .denied, .restricted:
              state.isLocationPermissionDenied = true
              // 권한 거부 시 안내 팝업 표시
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
              return .none
          @unknown default:
              return .none
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
      }
  }

  private func handleAsyncAction(
      state: inout State,
      action: AsyncAction
  ) -> Effect<Action> {
      switch action {
      case .requestLocationPermission:
          return .run { send in
              await MainActor.run {
                  let locationManager = LocationPermissionManager()
                  locationManager.requestLocationPermission()

                  // 권한 상태 변화 감지
                  Task {
                      try await Task.sleep(for: .seconds(1))
                      await send(.inner(.locationPermissionStatusChanged(locationManager.authorizationStatus)))

                      if let location = locationManager.currentLocation {
                          await send(.inner(.locationUpdated(location)))
                      }

                      if let error = locationManager.locationError {
                          await send(.inner(.locationUpdateFailed(error)))
                      }
                  }
              }
          }

      case .requestFullAccuracy:
          return .run { send in
              await MainActor.run {
                  let locationManager = LocationPermissionManager()
                  locationManager.requestFullAccuracy()

                  Task {
                      try await Task.sleep(for: .seconds(1))
                      await send(.async(.startLocationUpdates))
                  }
              }
          }

      case .startLocationUpdates:
          return .run { send in
              await MainActor.run {
                  let locationManager = LocationPermissionManager()
                  locationManager.requestCurrentLocation()

                  Task {
                      try await Task.sleep(for: .seconds(2))

                      if let location = locationManager.currentLocation {
                          await send(.inner(.locationUpdated(location)))
                      }

                      if let error = locationManager.locationError {
                          await send(.inner(.locationUpdateFailed(error)))
                      }
                  }
              }
          }

      case .stopLocationUpdates:
          return .run { send in
              await MainActor.run {
                  let locationManager = LocationPermissionManager()
                  locationManager.stopLocationUpdates()
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
}
