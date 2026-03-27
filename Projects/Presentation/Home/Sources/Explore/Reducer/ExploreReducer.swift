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
import LogMacro

@Reducer
public struct ExploreReducer: Sendable {
  public init() {}

  enum CancelID: Hashable {
    case startLocationUpdates
    case fetchPlaces
    case searchPlaces
    case searchRoute
  }

  @ObservableState
  public struct State: Equatable {
    public var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    public var currentLocation: CLLocation?
    public var isLocationPermissionDenied: Bool = false
    public var locationError: String?
    public var searchText: String = ""
    public var spots: [ExploreMapSpot] = []
    public var isLoadingPlaces: Bool = false
    public var hasRequestedPlaces: Bool = false
    public var hasFetchedPlacesWithCurrentLocation: Bool = false
    public var currentPage: Int = 0
    public var hasNextPage: Bool = true
    public var pendingSelectFirstSpotFromNextPage: Bool = false
    public var searchMarkerLat: Double?
    public var searchMarkerLon: Double?
    @Presents public var alert: AlertState<Alert>?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    // 길찾기 관련 상태
    public var selectedDestination: Destination?
    public var routeInfo: RouteInfo?
    public var isLoadingRoute: Bool = false
    public var routeError: String?

    // 지도 카메라 제어
    public var shouldReturnToCurrentLocation: Bool = false
    public var returnToCurrentLocationTrigger: Int = 0
    public var selectedCategory: ExploreCategory = .all
    public var isSpotCardVisible: Bool = false
    public var cardDragOffset: CGFloat = 0
    public var cardBaseOffset: CGFloat = 0
    public var isCardTransitioning: Bool = false

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case async(AsyncAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
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
    case spotTapped(String)
    case spotCardChanged(String?)
    case cardDragChanged(CGFloat)
    case cardDragEnded(CGFloat)
    case loadNextSpotPage
    // 길찾기 관련 액션
    case searchRouteToGangnam
    case clearRoute
    case returnToCurrentLocation
  }

  public enum InnerAction: Equatable {
    case locationPermissionStatusChanged(CLAuthorizationStatus)
    case locationUpdated(CLLocation)
    case locationUpdateFailed(String)
    case fetchPlacesResponse(ExploreSpotPageEntity, usedCurrentLocation: Bool)
    case fetchPlacesFailed(String, usedCurrentLocation: Bool)
    case searchPlacesResponse(
      ExploreSpotPageEntity,
      append: Bool,
      requestedPage: Int,
      requestedKeyword: String,
      requestedCategory: ExploreCategory?,
      requestedMarkerLat: Double?,
      requestedMarkerLon: Double?,
      usedCurrentLocation: Bool
    )
    case searchPlacesFailed(String)
    // 길찾기 관련 액션
    case routeSearchStarted(Destination)
    case routeSearchResponse(Result<RouteInfo, DirectionError>)
    // 지도 카메라 제어
    case resetCameraFlag
    case completeCardSwipe(next: Bool)
    case finishCardTransition
  }

  public enum AsyncAction: Equatable {
    case requestLocationPermission
    case requestFullAccuracy
    case startLocationUpdates
    case stopLocationUpdates
    case requestCurrentLocation
    case fetchPlaces
    case searchPlaces(page: Int, append: Bool)
    // 길찾기 관련 액션
    case searchRoute(from: CLLocationCoordinate2D, to: Destination)
  }


  public enum DelegateAction: Equatable {
    case presentExploreList
  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.placeUseCase) var placeUseCase

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

        case .delegate(let delegateAction):
          return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$alert, action: \.scope.alert)
  }
}

extension ExploreReducer {
  private var cardTravelDistance: CGFloat {
    UIScreen.main.bounds.width - 8
  }

  private var cardSwipeThreshold: CGFloat {
    (UIScreen.main.bounds.width - 32) / 2
  }

  private func resetPagination(state: inout State) {
    state.currentPage = 0
    state.hasNextPage = true
    state.pendingSelectFirstSpotFromNextPage = false
  }

  private func resetSearchContext(state: inout State, clearMarker: Bool = true) {
    state.isLoadingPlaces = false
    state.hasRequestedPlaces = false
    resetPagination(state: &state)
    if clearMarker {
      state.searchMarkerLat = nil
      state.searchMarkerLon = nil
    }
  }

  private func clearSelectedSpot(state: inout State) {
    state.isSpotCardVisible = false
    state.$userSession.withLock {
      $0.selectedExploreSpotID = ""
    }
    state.cardDragOffset = 0
    state.cardBaseOffset = 0
    state.isCardTransitioning = false
  }

  private func currentKeyword(state: State) -> String {
    state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func currentCategory(state: State) -> ExploreCategory? {
    state.selectedCategory == .all ? nil : state.selectedCategory
  }

  private func isSameCoordinate(_ lhs: Double?, _ rhs: Double?, tolerance: Double = 0.000001) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
      return true
    case let (lhs?, rhs?):
      return abs(lhs - rhs) < tolerance
    default:
      return false
    }
  }

  private func isResolvingSelectedMarkerDetail(state: State) -> Bool {
    guard state.searchMarkerLat != nil,
          state.searchMarkerLon != nil,
          let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty else {
      return false
    }

    return !state.spots.contains(where: { $0.id == selectedSpotID && $0.hasDetail })
  }

  private func hasUnresolvedBaseSpots(_ spots: [ExploreMapSpot]) -> Bool {
    spots.contains(where: { !$0.hasDetail })
  }

  private func filteredSpots(state: State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)

    let filtered = state.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.currentLocation else {
      return filtered
    }

    return filtered.sorted { lhs, rhs in
      let lhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: lhs.coordinate.latitude,
          longitude: lhs.coordinate.longitude
        )
      )
      let rhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: rhs.coordinate.latitude,
          longitude: rhs.coordinate.longitude
        )
      )

      return lhsDistance < rhsDistance
    }
  }

  private func syncSelectedSpot(state: inout State) {
    guard let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty else {
      return
    }

    guard state.spots.contains(where: { $0.id == selectedSpotID }) else {
      clearSelectedSpot(state: &state)
      return
    }
  }

  private func filteredCardSpots(state: State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)

    let filtered = state.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.currentLocation else {
      return filtered
    }

    return filtered.sorted { lhs, rhs in
      let lhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: lhs.coordinate.latitude,
          longitude: lhs.coordinate.longitude
        )
      )
      let rhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: rhs.coordinate.latitude,
          longitude: rhs.coordinate.longitude
        )
      )

      return lhsDistance < rhsDistance
    }
  }

  private func currentCardSpots(state: State) -> [ExploreMapSpot] {
    let filteredSpots = filteredCardSpots(state: state)
    let selectedSpotID = state.userSession.selectedExploreSpotID

    guard !selectedSpotID.isEmpty else {
      return filteredSpots
    }

    if filteredSpots.contains(where: { $0.id == selectedSpotID }) {
      return filteredSpots
    }

    if let selectedSearchSpot = state.spots.first(where: { $0.id == selectedSpotID && $0.hasDetail }) {
      return [selectedSearchSpot] + filteredSpots
    }

    return filteredSpots
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        let shouldBootstrap = state.spots.isEmpty && !state.hasRequestedPlaces

        if let lat = state.userSession.travelStationLat,
           let lng = state.userSession.travelStationLng {
          state.selectedDestination = Destination(
            name: state.userSession.travelStationName,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
          )
        }

        guard shouldBootstrap else {
          syncSelectedSpot(state: &state)
          return .run { send in
            let locationManager = await LocationPermissionManager.shared
            let currentStatus = await locationManager.authorizationStatus
            await send(.inner(.locationPermissionStatusChanged(currentStatus)))
          }
        }

        state.isSpotCardVisible = false
        state.hasFetchedPlacesWithCurrentLocation = false
        resetSearchContext(state: &state)
        state.spots = []
        syncSelectedSpot(state: &state)
        return .merge(
          .run { send in
          let locationManager = await LocationPermissionManager.shared
          let currentStatus = await locationManager.authorizationStatus
          await send(.inner(.locationPermissionStatusChanged(currentStatus)))
          },
          .send(.async(.fetchPlaces))
        )

      case .onDisappear:
        return .none

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
        resetSearchContext(state: &state)
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.fetchPlaces))
        )

      case .categoryTapped(let category):
        state.selectedCategory = category
        resetSearchContext(state: &state)
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.fetchPlaces))
        )

      case .spotTapped(let spotID):
        if state.userSession.selectedExploreSpotID == spotID, state.isSpotCardVisible {
          clearSelectedSpot(state: &state)
          state.searchMarkerLat = nil
          state.searchMarkerLon = nil
          state.pendingSelectFirstSpotFromNextPage = false
          return .cancel(id: CancelID.searchPlaces)
        }

        state.$userSession.withLock {
          $0.selectedExploreSpotID = spotID
        }
        state.isSpotCardVisible = state.spots.contains(where: { $0.id == spotID && $0.hasDetail })
        #logDebug(" [ExploreReducer] spotTapped id=\(spotID), hasDetail=\(state.isSpotCardVisible)")
        guard !state.spots.contains(where: { $0.id == spotID && $0.hasDetail }),
              let markerSpot = state.spots.first(where: { $0.id == spotID }) else {
          return .none
        }

        state.searchMarkerLat = markerSpot.coordinate.latitude
        state.searchMarkerLon = markerSpot.coordinate.longitude
        resetSearchContext(state: &state, clearMarker: false)

        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.fetchPlaces))
        )

      case .spotCardChanged(let spotID):
        if let spotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = spotID
          }
          state.isSpotCardVisible = true
        } else {
          state.isSpotCardVisible = false
        }
        return .none

      case .cardDragChanged(let offset):
        guard !state.isCardTransitioning else {
          return .none
        }
        let limitedOffset = max(min(offset, cardTravelDistance), -cardTravelDistance)
        state.cardDragOffset = limitedOffset
        return .none

      case .cardDragEnded(let translationWidth):
        guard !state.isCardTransitioning else {
          return .none
        }

        if translationWidth > cardSwipeThreshold {
          return .send(.inner(.completeCardSwipe(next: false)))
        }

        if translationWidth < -cardSwipeThreshold {
          return .send(.inner(.completeCardSwipe(next: true)))
        }

        state.cardDragOffset = 0
        return .none

      case .loadNextSpotPage:
        guard state.hasNextPage, !state.isLoadingPlaces else {
          return .none
        }
        state.pendingSelectFirstSpotFromNextPage = true
        return .send(.async(.searchPlaces(page: state.currentPage, append: true)))

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
        #logDebug(
          " [ExploreReducer] returnToCurrentLocation current=\(String(describing: state.currentLocation?.coordinate))"
        )
        guard state.currentLocation != nil else {
          state.shouldReturnToCurrentLocation = true
          return .send(.async(.requestCurrentLocation))
        }
        state.returnToCurrentLocationTrigger += 1
        return .none
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
        if state.shouldReturnToCurrentLocation {
          state.shouldReturnToCurrentLocation = false
          state.returnToCurrentLocationTrigger += 1
          return .none
        }
        if !state.hasFetchedPlacesWithCurrentLocation,
           !state.isLoadingPlaces {
          resetSearchContext(state: &state, clearMarker: false)
          return .merge(
            .cancel(id: CancelID.fetchPlaces),
            .cancel(id: CancelID.searchPlaces),
            .send(.async(.fetchPlaces))
          )
        }
        return .none

      case .locationUpdateFailed(let error):
        #logDebug(" [ExploreReducer] 위치 업데이트 실패: \(error)")
        return .none

      case .fetchPlacesResponse(let entities, let usedCurrentLocation):
        state.isLoadingPlaces = false
        state.hasRequestedPlaces = false
        state.spots = entities.spots
        state.currentPage = entities.currentPage
        state.hasNextPage = entities.hasNextPage || hasUnresolvedBaseSpots(entities.spots)
        state.hasFetchedPlacesWithCurrentLocation = usedCurrentLocation
        if state.currentLocation != nil
            && !usedCurrentLocation
            && !state.hasFetchedPlacesWithCurrentLocation {
          return .send(.async(.fetchPlaces))
        }
        return .none

      case .fetchPlacesFailed(let message, let usedCurrentLocation):
        state.hasRequestedPlaces = false
        resetSearchContext(state: &state, clearMarker: false)
        if usedCurrentLocation {
          state.hasFetchedPlacesWithCurrentLocation = false
        }
        #logDebug(" [ExploreReducer] 장소 조회 실패: \(message)")
        state.spots = []
        clearSelectedSpot(state: &state)
        return .none

      case .searchPlacesResponse(
        let pageEntity,
        let append,
        let requestedPage,
        let requestedKeyword,
        let requestedCategory,
        let requestedMarkerLat,
        let requestedMarkerLon,
        let usedCurrentLocation
      ):
        state.isLoadingPlaces = false
        state.hasRequestedPlaces = false
        let previousDetailedCount = state.spots.filter(\.hasDetail).count
        let currentKeyword = currentKeyword(state: state)
        let currentCategory = currentCategory(state: state)
        let currentMarkerLat = state.searchMarkerLat
        let currentMarkerLon = state.searchMarkerLon

        guard requestedPage == 0 || append else {
          return .none
        }

        if requestedMarkerLat != nil || requestedMarkerLon != nil {
          guard isSameCoordinate(requestedMarkerLat, currentMarkerLat),
                isSameCoordinate(requestedMarkerLon, currentMarkerLon) else {
            return .none
          }
        } else {
          guard requestedKeyword == currentKeyword,
                requestedCategory == currentCategory,
                requestedMarkerLat == currentMarkerLat,
                requestedMarkerLon == currentMarkerLon else {
            return .none
          }
        }

        state.hasFetchedPlacesWithCurrentLocation = usedCurrentLocation
        state.currentPage = pageEntity.currentPage
        let newSpots = pageEntity.spots
        let newDetailedCount = newSpots.filter(\.hasDetail).count
        let gainedMoreDetail = newDetailedCount > previousDetailedCount
        let shouldKeepBootstrappingDetails =
          requestedMarkerLat == nil
          && requestedMarkerLon == nil
          && requestedKeyword.isEmpty
          && requestedCategory == nil
          && hasUnresolvedBaseSpots(newSpots)
          && (requestedPage == 0 || gainedMoreDetail)

        state.hasNextPage = pageEntity.hasNextPage || shouldKeepBootstrappingDetails
        let firstNewSpotID = newSpots.first(where: \.hasDetail)?.id
        let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty

        state.spots = newSpots
        if let selectedSpotID,
           newSpots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }) {
          state.isSpotCardVisible = true
        } else if state.searchMarkerLat != nil {
          state.isSpotCardVisible = false
        } else {
          clearSelectedSpot(state: &state)
        }

        if state.pendingSelectFirstSpotFromNextPage, let firstNewSpotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = firstNewSpotID
          }
          state.isSpotCardVisible = true
          state.pendingSelectFirstSpotFromNextPage = false
          state.cardBaseOffset = 0
          state.cardDragOffset = 0
          state.isCardTransitioning = false
          syncSelectedSpot(state: &state)
          return .none
        }

        let wasPendingNextPage = state.pendingSelectFirstSpotFromNextPage
        state.pendingSelectFirstSpotFromNextPage = false
        syncSelectedSpot(state: &state)

        if let selectedSpotID,
           state.searchMarkerLat != nil,
           !state.spots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }),
           state.hasNextPage {
          return .send(.async(.searchPlaces(page: state.currentPage, append: true)))
        }

        if let selectedSpotID,
           state.searchMarkerLat != nil,
           !state.spots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }),
           !state.hasNextPage {
          clearSelectedSpot(state: &state)
        }

        if wasPendingNextPage {
          return .send(.inner(.finishCardTransition))
        }

        return .none

      case .searchPlacesFailed(let message):
        state.isLoadingPlaces = false
        state.hasRequestedPlaces = false
        let wasPendingNextPage = state.pendingSelectFirstSpotFromNextPage
        state.pendingSelectFirstSpotFromNextPage = false
        #logDebug(" [ExploreReducer] 장소 검색 실패: \(message)")
        if wasPendingNextPage {
          return .send(.inner(.finishCardTransition))
        }
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
          #logDebug(" [ExploreReducer] 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
        case .failure(let error):
          state.routeError = error.localizedDescription
          #logDebug(" [ExploreReducer] 경로 검색 실패: \(error.localizedDescription)")
        }
        return .none

      case .resetCameraFlag:
        state.shouldReturnToCurrentLocation = false
        return .none

      case .completeCardSwipe(let next):
        let cardSpots = state.cardSpots
        guard !cardSpots.isEmpty else {
          #logDebug(" [ExploreReducer] completeCardSwipe ignored: cardSpots empty")
          return .none
        }

        let currentSelectedID = state.selectedSpot?.id ?? state.userSession.selectedExploreSpotID
        let currentIndex = cardSpots.firstIndex(where: { $0.id == currentSelectedID }) ?? 0
        let entryOffset: CGFloat = next ? cardTravelDistance : -cardTravelDistance
        let isAtEnd = next && currentIndex == cardSpots.count - 1
        let isAtStart = !next && currentIndex == 0

        state.isCardTransitioning = true
        state.cardDragOffset = next ? -cardTravelDistance : cardTravelDistance

        if isAtEnd {
          if state.hasNextPage {
            state.isSpotCardVisible = true
            state.cardDragOffset = 0
            state.cardBaseOffset = 0
            state.isCardTransitioning = true
            return .send(.view(.loadNextSpotPage))
          }

          state.$userSession.withLock {
            $0.selectedExploreSpotID = cardSpots[0].id
          }
        } else if isAtStart {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = cardSpots[cardSpots.count - 1].id
          }
        } else {
          let newIndex = next ? currentIndex + 1 : currentIndex - 1
          state.$userSession.withLock {
            $0.selectedExploreSpotID = cardSpots[newIndex].id
          }
        }

        state.isSpotCardVisible = true
        state.cardBaseOffset = entryOffset
        state.cardDragOffset = 0

        return .run { send in
          try await Task.sleep(for: .milliseconds(240))
          await send(.inner(.finishCardTransition))
        }

      case .finishCardTransition:
        state.cardBaseOffset = 0
        state.cardDragOffset = 0
        state.isCardTransitioning = false
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
               send(.async(.startLocationUpdates))
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
                 send(.inner(.locationUpdated(location)))
              }
            }

            locationManager.onLocationError = { error in
              Task { @MainActor in
                 send(.inner(.locationUpdateFailed(error.localizedDescription)))
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
        .cancellable(id: CancelID.startLocationUpdates, cancelInFlight: true)

      case .stopLocationUpdates:
        return .run { send in
          await MainActor.run {
            let locationManager = LocationPermissionManager.shared
            locationManager.stopLocationUpdates()
          }
        }

      case .requestCurrentLocation:
        return .run { send in
          let locationManager = await LocationPermissionManager.shared

          do {
            if let location = try await locationManager.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            } else {
              await send(.inner(.locationUpdateFailed(LocationError.locationUnavailable.localizedDescription)))
            }
          } catch {
            await send(.inner(.locationUpdateFailed(error.localizedDescription)))
          }
        }

      case .fetchPlaces:
        guard Int(state.userSession.travelID) != nil,
              state.userSession.travelStationLat != nil,
              state.userSession.travelStationLng != nil,
              !state.isLoadingPlaces,
              !state.hasRequestedPlaces else {
          return .none
        }

        state.isLoadingPlaces = true
        state.hasRequestedPlaces = true
        let userSession = state.userSession
        let fallbackLat = state.userSession.travelStationLat ?? 0
        let fallbackLng = state.userSession.travelStationLng ?? 0
        let usedCurrentLocation = state.currentLocation != nil
        let userLat = state.currentLocation?.coordinate.latitude ?? fallbackLat
        let userLon = state.currentLocation?.coordinate.longitude ?? fallbackLng

        return .run { send in
          let result = await Result {
            try await placeUseCase.fetchInitialExploreSpots(
              userSession: userSession,
              userLat: userLat,
              userLon: userLon
            )
          }

          switch result {
          case .success(let entities):
            await send(.inner(.fetchPlacesResponse(entities, usedCurrentLocation: usedCurrentLocation)))
          case .failure(let error):
            await send(.inner(.fetchPlacesFailed(error.localizedDescription, usedCurrentLocation: usedCurrentLocation)))
          }
        }
        .cancellable(id: CancelID.fetchPlaces, cancelInFlight: true)

      case .searchPlaces(let page, let append):
        guard Int(state.userSession.travelID) != nil,
              !state.isLoadingPlaces,
              !state.hasRequestedPlaces else {
          return .none
        }

        state.isLoadingPlaces = true
        state.hasRequestedPlaces = true
        let userSession = state.userSession
        let fallbackLat = state.userSession.travelStationLat ?? 0
        let fallbackLng = state.userSession.travelStationLng ?? 0
        let userLat = state.currentLocation?.coordinate.latitude ?? fallbackLat
        let userLon = state.currentLocation?.coordinate.longitude ?? fallbackLng
        let markerLat = state.searchMarkerLat ?? state.userSession.travelStationLat ?? fallbackLat
        let markerLon = state.searchMarkerLon ?? state.userSession.travelStationLng ?? fallbackLng
        let requestedMarkerLat = state.searchMarkerLat
        let requestedMarkerLon = state.searchMarkerLon
        let rawKeyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isResolvingSelectedMarkerDetail = isResolvingSelectedMarkerDetail(state: state)
        let keyword = isResolvingSelectedMarkerDetail ? nil : rawKeyword.nilIfEmpty
        let category: ExploreCategory? = isResolvingSelectedMarkerDetail
          ? nil
          : (state.selectedCategory == .all ? nil : state.selectedCategory)
        let sortBy = isResolvingSelectedMarkerDetail ? "MARKER_NEAREST" : "STATION_NEAREST"
        let usedCurrentLocation = state.currentLocation != nil
        let baseSpots = state.spots

        return .run { send in
          let result = await Result {
            try await placeUseCase.searchExploreSpots(
              baseSpots: baseSpots,
              userSession: userSession,
              userLat: userLat,
              userLon: userLon,
              keyword: keyword,
              category: category,
              sortBy: sortBy,
              markerLat: markerLat,
              markerLon: markerLon,
              page: page
            )
          }

          switch result {
          case .success(let entity):
            await send(
              .inner(
                .searchPlacesResponse(
                  entity,
                  append: append,
                  requestedPage: page,
                  requestedKeyword: rawKeyword,
                  requestedCategory: category,
                  requestedMarkerLat: requestedMarkerLat,
                  requestedMarkerLon: requestedMarkerLon,
                  usedCurrentLocation: usedCurrentLocation
                )
              )
            )
          case .failure(let error):
            await send(.inner(.searchPlacesFailed(error.localizedDescription)))
          }
        }
        .cancellable(id: CancelID.searchPlaces, cancelInFlight: true)

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
        .cancellable(id: CancelID.searchRoute, cancelInFlight: true)
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

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentExploreList:
        return .none
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

extension ExploreReducer.State {
  var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func hasVisibleMarkerContent(_ spot: ExploreMapSpot) -> Bool {
    spot.hasDetail
      || !spot.name.isEmpty
      || !spot.badgeText.isEmpty
      || !spot.statusText.isEmpty
      || !spot.closingText.isEmpty
      || !spot.distanceText.isEmpty
      || !spot.walkTimeText.isEmpty
  }

  func matchesCurrentFilters(_ spot: ExploreMapSpot) -> Bool {
    let matchesCategory = selectedCategory == .all || spot.category == selectedCategory
    let matchesQuery = trimmedSearchText.isEmpty || spot.name.localizedCaseInsensitiveContains(trimmedSearchText)
    return matchesCategory && matchesQuery
  }

  var filteredMapSpots: [ExploreMapSpot] {
    spots.filter { spot in
      hasVisibleMarkerContent(spot)
        && (selectedCategory == .all || spot.category == selectedCategory)
    }
  }

  var filteredSpots: [ExploreMapSpot] {
    spots.filter { spot in
      spot.hasDetail && matchesCurrentFilters(spot)
    }
  }

  func mergedSpot(for spotID: String) -> ExploreMapSpot? {
    spots.first(where: { $0.id == spotID && $0.hasDetail })
  }

  var cardSpots: [ExploreMapSpot] {
    let selectedSpotID = userSession.selectedExploreSpotID

    guard !selectedSpotID.isEmpty else {
      return filteredSpots
    }

    if filteredSpots.contains(where: { $0.id == selectedSpotID }) {
      return filteredSpots
    }

    if let selectedSearchSpot = mergedSpot(for: selectedSpotID) {
      return [selectedSearchSpot] + filteredSpots
    }

    return filteredSpots
  }

  var selectedSpot: ExploreMapSpot? {
    guard isSpotCardVisible else { return nil }

    let selectedSpotID = userSession.selectedExploreSpotID

    if !selectedSpotID.isEmpty,
       let selectedSpot = mergedSpot(for: selectedSpotID) {
      return selectedSpot
    }

    return nil
  }

  func adjacentSpot(cardTravelDistance: CGFloat) -> ExploreMapSpot? {
    let currentSelectedID = selectedSpot?.id ?? userSession.selectedExploreSpotID
    guard let currentIndex = cardSpots.firstIndex(where: { $0.id == currentSelectedID }) else {
      return nil
    }
    guard abs(cardDragOffset) > 0 else {
      return nil
    }

    let adjacentIndex: Int
    if cardDragOffset < 0 {
      adjacentIndex = (currentIndex + 1) % cardSpots.count
    } else {
      adjacentIndex = (currentIndex - 1 + cardSpots.count) % cardSpots.count
    }
    return cardSpots[adjacentIndex]
  }

  func adjacentCardOffset(cardTravelDistance: CGFloat) -> CGFloat? {
    guard adjacentSpot(cardTravelDistance: cardTravelDistance) != nil else { return nil }
    let baseOffset = cardDragOffset >= 0 ? -cardTravelDistance : cardTravelDistance
    return baseOffset + cardDragOffset
  }

  func cardOpacity(cardTravelDistance: CGFloat) -> Double {
    let progress = min(abs(cardBaseOffset + cardDragOffset) / cardTravelDistance, 1)
    return 1 - (progress * 0.02)
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
    hasher.combine(spots)
    hasher.combine(isLoadingRoute)
    hasher.combine(routeError)
    hasher.combine(shouldReturnToCurrentLocation)
    hasher.combine(userSession)
  }
}


private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}

extension ExploreReducer.AsyncAction {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.requestLocationPermission, .requestLocationPermission),
         (.requestFullAccuracy, .requestFullAccuracy),
         (.startLocationUpdates, .startLocationUpdates),
         (.stopLocationUpdates, .stopLocationUpdates),
         (.requestCurrentLocation, .requestCurrentLocation),
         (.fetchPlaces, .fetchPlaces):
      return true
    case (.searchPlaces(let lhsPage, let lhsAppend), .searchPlaces(let rhsPage, let rhsAppend)):
      return lhsPage == rhsPage && lhsAppend == rhsAppend
    case (.searchRoute(let lhsFrom, let lhsTo), .searchRoute(let rhsFrom, let rhsTo)):
      return lhsFrom.latitude == rhsFrom.latitude
      && lhsFrom.longitude == rhsFrom.longitude
      && lhsTo == rhsTo
    default:
      return false
    }
  }
}
