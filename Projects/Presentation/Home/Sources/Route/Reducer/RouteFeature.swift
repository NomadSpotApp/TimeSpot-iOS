//
//  RouteFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/30/26.
//


import Foundation
import ComposableArchitecture
import UIKit
import Entity
import CoreLocation
import UseCase
import LogMacro


@Reducer
public struct RouteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    public var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    public var currentLocation: CLLocation?
    public var routeInfo: RouteInfo?
    public var isLoadingRoute: Bool = false
    public var routeError: String?

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case onAppear
    case searchRoute
    case startNavigation
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case startLocationUpdates
    case searchRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
    case startNavigation(mapType: ExternalMapType, destination: CLLocationCoordinate2D, destinationName: String)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case locationPermissionStatusChanged(CLAuthorizationStatus)
    case locationUpdated(CLLocation)
    case routeSearchResponse(Result<RouteInfo, DirectionError>)
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {


  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.locationUseCase) var locationUseCase


  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(_):
          return .none

        case .view(let viewAction):
          return handleViewAction(state: &state, action: viewAction)

        case .async(let asyncAction):
          return handleAsyncAction(state: &state, action: asyncAction)

        case .inner(let innerAction):
          return handleInnerAction(state: &state, action: innerAction)

        case .delegate(let delegateAction):
          return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension RouteFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        return .merge(
          .run { send in
            let currentStatus = await locationUseCase.getAuthorizationStatus()
            await send(.inner(.locationPermissionStatusChanged(currentStatus)))
          },
          .send(.async(.startLocationUpdates))
        )

      case .searchRoute:
        guard let startLat = state.userSession.routeStartLat,
              let startLng = state.userSession.routeStartLng,
              let endLat = state.userSession.routeDestinationLat,
              let endLng = state.userSession.routeDestinationLng else {
          return .none
        }

        let startCoord = CLLocationCoordinate2D(latitude: startLat, longitude: startLng)
        let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
        return .send(.async(.searchRoute(from: startCoord, to: endCoord)))

      case .startNavigation:
        guard let endLat = state.userSession.routeDestinationLat,
              let endLng = state.userSession.routeDestinationLng else {
          #logDebug("❌ [Route] 목적지 정보 없음")
          return .none
        }

        let destination = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
        let destinationName = state.userSession.routeDestinationName.isEmpty ? "목적지" : state.userSession.routeDestinationName
        let mapType = state.userSession.mapType

        return .send(.async(.startNavigation(mapType: mapType, destination: destination, destinationName: destinationName)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .startLocationUpdates:
        return .run { send in
          await locationUseCase.startLocationUpdates(
            onUpdate: { location in
              Task { @MainActor in
                send(.inner(.locationUpdated(location)))
              }
            },
            onError: { error in
              #logDebug("❌ [Route] 위치 업데이트 실패: \(error.localizedDescription)")
            }
          )

          // 초기 위치도 가져오기
          do {
            if let location = try await locationUseCase.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            }
          } catch {
            #logDebug("❌ [Route] 현재 위치 가져오기 실패: \(error.localizedDescription)")
          }
        }

      case .searchRoute(let from, let to):
        state.isLoadingRoute = true
        return .run { send in
          let result = await Result {
            try await getRouteUseCase.execute(from: from, to: to, option: .walking)
          }
          .mapError(DirectionError.from)

          await send(.inner(.routeSearchResponse(result)))
        }

      case .startNavigation(let mapType, let destination, let destinationName):
        return .run { _ in
          await getRouteUseCase.startNavigation(
            mapType: mapType,
            destination: destination,
            destinationName: destinationName
          )
        }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {

    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case .locationPermissionStatusChanged(let status):
        state.locationPermissionStatus = status
        return .none

      case .locationUpdated(let location):
        state.currentLocation = location

        // 현재 위치가 업데이트되면 UserSession에 출발지로 저장하고 자동 경로 검색
        state.$userSession.withLock {
          $0.routeStartLat = location.coordinate.latitude
          $0.routeStartLng = location.coordinate.longitude
        }

        #logDebug("📍 [Route] 현재 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // 목적지 정보가 있으면 자동으로 경로 검색
        if let endLat = state.userSession.routeDestinationLat,
           let endLng = state.userSession.routeDestinationLng {
          let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
          #logDebug("🎯 [Route] 목적지 발견, 경로 검색 시작: (\(endLat), \(endLng))")
          return .send(.async(.searchRoute(from: location.coordinate, to: endCoord)))
        } else {
          #logDebug("⚠️ [Route] 목적지 정보 없음")
        }
        return .none

      case .routeSearchResponse(let result):
        state.isLoadingRoute = false
        switch result {
        case .success(let routeInfo):
          state.routeInfo = routeInfo
          state.routeError = nil
          #logDebug("✅ [Route] 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
        case .failure(let error):
          state.routeError = error.localizedDescription
          #logDebug("❌ [Route] 경로 검색 실패: \(error.localizedDescription)")
        }
        return .none
    }
  }
}

extension RouteFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(locationPermissionStatus)
    hasher.combine(currentLocation?.coordinate.latitude)
    hasher.combine(currentLocation?.coordinate.longitude)
    hasher.combine(routeInfo?.distance)
    hasher.combine(routeInfo?.duration)
    hasher.combine(isLoadingRoute)
    hasher.combine(routeError)
    hasher.combine(userSession)
  }
}

// MARK: - Equatable Extensions

extension RouteFeature.AsyncAction {
  public static func == (lhs: RouteFeature.AsyncAction, rhs: RouteFeature.AsyncAction) -> Bool {
    switch (lhs, rhs) {
    case (.startLocationUpdates, .startLocationUpdates):
      return true
    case (.searchRoute(let lhsFrom, let lhsTo), .searchRoute(let rhsFrom, let rhsTo)):
      let fromLatEqual = lhsFrom.latitude == rhsFrom.latitude
      let fromLngEqual = lhsFrom.longitude == rhsFrom.longitude
      let toLatEqual = lhsTo.latitude == rhsTo.latitude
      let toLngEqual = lhsTo.longitude == rhsTo.longitude
      return fromLatEqual && fromLngEqual && toLatEqual && toLngEqual
    case (.startNavigation(let lhsType, let lhsDestination, let lhsName),
          .startNavigation(let rhsType, let rhsDestination, let rhsName)):
      let typeEqual = lhsType == rhsType
      let latEqual = lhsDestination.latitude == rhsDestination.latitude
      let lngEqual = lhsDestination.longitude == rhsDestination.longitude
      let nameEqual = lhsName == rhsName
      return typeEqual && latEqual && lngEqual && nameEqual
    default:
      return false
    }
  }
}

extension RouteFeature.InnerAction {
  public static func == (lhs: RouteFeature.InnerAction, rhs: RouteFeature.InnerAction) -> Bool {
    switch (lhs, rhs) {
    case (.locationPermissionStatusChanged(let lhsStatus), .locationPermissionStatusChanged(let rhsStatus)):
      return lhsStatus == rhsStatus
    case (.locationUpdated(let lhsLocation), .locationUpdated(let rhsLocation)):
      let latEqual = lhsLocation.coordinate.latitude == rhsLocation.coordinate.latitude
      let lngEqual = lhsLocation.coordinate.longitude == rhsLocation.coordinate.longitude
      return latEqual && lngEqual
    case (.routeSearchResponse(.success(let lhsRoute)), .routeSearchResponse(.success(let rhsRoute))):
      return lhsRoute.distance == rhsRoute.distance && lhsRoute.duration == rhsRoute.duration
    case (.routeSearchResponse(.failure(let lhsError)), .routeSearchResponse(.failure(let rhsError))):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}
