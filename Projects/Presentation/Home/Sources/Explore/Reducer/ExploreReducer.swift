//
//  ExploreReducer.swift
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
public struct ExploreReducer: Sendable {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    public var currentLocation: CLLocation?
    public var isLocationPermissionDenied: Bool = false
    public var locationError: String?
    public var searchText: String = ""
    @Presents public var alert: AlertState<Alert>?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    // 길찾기 관련 상태
    public var selectedDestination: Destination?
    public var routeInfo: RouteInfo?
    public var isLoadingRoute: Bool = false
    public var routeError: String?

    // 지도 카메라 제어
    public var shouldReturnToCurrentLocation: Bool = false
    public var selectedCategory: ExploreCategory = .all

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
    case searchTextChanged(String)
    case categoryTapped(ExploreCategory)
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

extension ExploreReducer {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        return .run { send in
          let locationManager = await LocationPermissionManager.shared
          let currentStatus = await locationManager.authorizationStatus
          await send(.inner(.locationPermissionStatusChanged(currentStatus)))
        }

      case .onDisappear:
        return .send(.async(.stopLocationUpdates))

      case .requestLocationPermission:
        return .none

      case .retryLocationPermission:
        state.isLocationPermissionDenied = false
        return .none

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

      case .searchTextChanged(let text):
        state.searchText = text
        return .none

      case .categoryTapped(let category):
        state.selectedCategory = category
        return .none

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
            state.alert = nil
            return .send(.async(.stopLocationUpdates))
          case .notDetermined:
            state.isLocationPermissionDenied = false
            state.alert = nil
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
        return .none

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
            return .none

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

// MARK: - ExploreReducer.State + Hashable
extension ExploreReducer.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(locationPermissionStatus)
    hasher.combine(currentLocation?.coordinate.latitude)
    hasher.combine(currentLocation?.coordinate.longitude)
    hasher.combine(isLocationPermissionDenied)
    hasher.combine(locationError)
    hasher.combine(isLoadingRoute)
    hasher.combine(routeError)
    hasher.combine(shouldReturnToCurrentLocation)
    hasher.combine(userSession)
    // Note: alert, selectedDestination, routeInfo are not hashed as they contain complex types
  }
}
