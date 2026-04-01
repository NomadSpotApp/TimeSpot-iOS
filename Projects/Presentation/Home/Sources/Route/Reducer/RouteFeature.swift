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

// MARK: - Journey Error
public enum JourneyError: Error {
  case message(String)

  public var localizedDescription: String {
    switch self {
    case .message(let string):
      return string
    }
  }
}


@Reducer
public struct RouteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("selectedMapType")) var selectedMapTypeStorage: ExternalMapType = .naverMap
    @Shared(.appStorage("nearestStationLat")) var persistedStationLat: Double = 0.0
    @Shared(.appStorage("nearestStationLng")) var persistedStationLng: Double = 0.0
    @Shared(.appStorage("visitingHistoryId")) var visitingHistoryId: Int = 0
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
    case startJourney
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case startLocationUpdates
    case waitForLocationThenSearchRoute
    case searchRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
    case startNavigation(mapType: ExternalMapType, destination: CLLocationCoordinate2D, destinationName: String)
    case startJourney
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case locationPermissionStatusChanged(CLAuthorizationStatus)
    case locationUpdated(CLLocation)
    case routeSearchResponse(Result<RouteInfo, DirectionError>)
    case journeyStartResponse(Result<JourneyEntity, JourneyError>)
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {


  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.locationUseCase) var locationUseCase
  @Dependency(\.historyRepository) var historyRepository


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
        let hasDestination = state.userSession.routeDestinationLat != nil &&
                           state.userSession.routeDestinationLng != nil


        if hasDestination {
          return .merge(
            .run { send in
              let currentStatus = await locationUseCase.getAuthorizationStatus()
              await send(.inner(.locationPermissionStatusChanged(currentStatus)))
            },
            .send(.async(.startLocationUpdates)),
            .send(.async(.waitForLocationThenSearchRoute))
          )
        } else {
          return .merge(
            .run { send in
              let currentStatus = await locationUseCase.getAuthorizationStatus()
              await send(.inner(.locationPermissionStatusChanged(currentStatus)))
            },
            .send(.async(.startLocationUpdates))
          )
        }

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
          return .none
        }

        let destination = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
        let destinationName = state.userSession.routeDestinationName.isEmpty ? "목적지" : state.userSession.routeDestinationName
        let mapType = state.selectedMapTypeStorage

        return .send(.async(.startNavigation(mapType: mapType, destination: destination, destinationName: destinationName)))

      case .startJourney:
        return .send(.async(.startJourney))
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
              #logDebug(" [Route] 위치 업데이트 실패: \(error.localizedDescription)")
            }
          )

          // 초기 위치도 가져오기
          do {
            if let location = try await locationUseCase.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            }
          } catch {
            #logDebug(" [Route] 현재 위치 가져오기 실패: \(error.localizedDescription)")
          }
        }

      case .waitForLocationThenSearchRoute:
        return .run { [userSession = state.userSession] send in
          // 최대 5초 동안 현재 위치를 기다림
          var attempts = 0
          let maxAttempts = 25  // 5초 (200ms * 25)

          while attempts < maxAttempts {
            do {
              if let currentLocation = try await locationUseCase.requestCurrentLocation(),
                 let endLat = userSession.routeDestinationLat,
                 let endLng = userSession.routeDestinationLng {

                let startCoord = currentLocation.coordinate
                let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)

                await send(.async(.searchRoute(from: startCoord, to: endCoord)))
                return
              }
            }

            attempts += 1
            try? await Task.sleep(for: .milliseconds(200))
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

      case .startJourney:
        return .run { [userSession = state.userSession, currentLocation = state.currentLocation] send in
          guard let departureTime = userSession.departureTime,
                let currentLocation = currentLocation else {
            await send(.inner(.journeyStartResponse(.failure(.message("필요한 정보가 부족합니다.")))))
            return
          }

          // UserSession에서 필요한 정보 추출
          let stationIdString = userSession.travelID
          let placeIdString = userSession.selectedExplorePlaceID

          guard let stationId = Int(stationIdString),
                let placeId = Int(placeIdString),
                !stationIdString.isEmpty,
                !placeIdString.isEmpty else {
            await send(.inner(.journeyStartResponse(.failure(.message("역 정보 또는 장소 정보가 없습니다.")))))
            return
          }

          let input = StartJourneyInput(
            stationId: stationId,
            placeId: placeId,
            trainDepartureTime: departureTime,
            lat: currentLocation.coordinate.latitude,
            lng: currentLocation.coordinate.longitude
          )

          do {
            let journey = try await historyRepository.startJourney(input: input)
            await send(.inner(.journeyStartResponse(.success(journey))))
          } catch {
            await send(.inner(.journeyStartResponse(.failure(.message(error.localizedDescription)))))
          }
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

        // 목적지 정보가 있으면 자동으로 경로 검색
        if let endLat = state.userSession.routeDestinationLat,
           let endLng = state.userSession.routeDestinationLng {
          let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
          return .send(.async(.searchRoute(from: location.coordinate, to: endCoord)))
        }
        return .none

      case .routeSearchResponse(let result):
        state.isLoadingRoute = false
        switch result {
        case .success(let routeInfo):
          state.routeInfo = routeInfo
          state.routeError = nil

          // UserSession에 경로 정보 저장
          state.$userSession.withLock {
            $0.routeDistance = routeInfo.distance
            $0.routeDuration = routeInfo.duration
          }

          // 목적지를 가장 가까운 역으로 appStorage에 저장 (지속적 저장)
          if let destLat = state.userSession.routeDestinationLat,
             let destLng = state.userSession.routeDestinationLng {
            state.$persistedStationLat.withLock { $0 = destLat }
            state.$persistedStationLng.withLock { $0 = destLng }
          }

        case .failure(let error):
          state.routeError = error.localizedDescription
        }
        return .none

      case .journeyStartResponse(let result):
        switch result {
        case .success(let journey):
          #logDebug("✅ 여정 시작 성공: \(journey.id)")

          // visitingHistoryId를 appStorage에 저장
          state.$visitingHistoryId.withLock { $0 = journey.id }

          // 여정 시작 성공 시 길찾기 시작
          guard let endLat = state.userSession.routeDestinationLat,
                let endLng = state.userSession.routeDestinationLng else {
            return .none
          }

          let destination = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
          let destinationName = state.userSession.routeDestinationName.isEmpty ? "목적지" : state.userSession.routeDestinationName
          let mapType = state.selectedMapTypeStorage

          return .send(.async(.startNavigation(mapType: mapType, destination: destination, destinationName: destinationName)))

        case .failure(let error):
          #logDebug("❌ 여정 시작 실패: \(error)")
          // TODO: 에러 처리 (토스트 메시지 등)
          return .none
        }
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
    hasher.combine(visitingHistoryId)
  }
}

// MARK: - Equatable Extensions

extension RouteFeature.AsyncAction {
  public static func == (lhs: RouteFeature.AsyncAction, rhs: RouteFeature.AsyncAction) -> Bool {
    switch (lhs, rhs) {
    case (.startLocationUpdates, .startLocationUpdates):
      return true
    case (.waitForLocationThenSearchRoute, .waitForLocationThenSearchRoute):
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
    case (.startJourney, .startJourney):
      return true
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
    case (.journeyStartResponse(.success(let lhsJourney)), .journeyStartResponse(.success(let rhsJourney))):
      return lhsJourney.id == rhsJourney.id
    case (.journeyStartResponse(.failure(let lhsError)), .journeyStartResponse(.failure(let rhsError))):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}
