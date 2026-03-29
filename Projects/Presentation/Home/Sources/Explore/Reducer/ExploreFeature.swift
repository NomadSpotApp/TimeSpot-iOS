//
//  ExploreFeature.swift
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
import Utill
import IdentifiedCollections

@Reducer
public struct ExploreFeature: Sendable {
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
    public var isLoadingPlaces: Bool = false
    public var hasRequestedPlaces: Bool = false
    public var hasFetchedPlacesWithCurrentLocation: Bool = false
    public var currentPage: Int = 0
    public var hasNextPage: Bool = true
    public var pendingSelectFirstSpotFromNextPage: Bool = false
    public var searchMarkerLat: Double?
    public var searchMarkerLon: Double?
    public var mapCenterLat: Double?
    public var mapCenterLon: Double?
    @Presents public var alert: AlertState<Alert>?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    public var spots: [ExploreMapSpot] = []

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
    case detailTapped
    case spotCardChanged(String?)
    case cardDragChanged(CGFloat)
    case cardDragEnded(CGFloat)
    case loadNextSpotPage
    case mapCenterChanged(CLLocationCoordinate2D)
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
    // 네이버 이미지 검색 완료
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
    case presentExplorerDetail
  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.placeUseCase) var placeUseCase
  @Dependency(\.locationUseCase) var locationUseCase
  @Dependency(\.cameraUseCase) var cameraUseCase

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

extension ExploreFeature {

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
          ExploreHelpers.syncSelectedSpot(state: &state)
          return .run { send in
            let currentStatus = await locationUseCase.getAuthorizationStatus()
            await send(.inner(.locationPermissionStatusChanged(currentStatus)))
          }
        }

        state.isSpotCardVisible = false
        state.hasFetchedPlacesWithCurrentLocation = false
        ExploreHelpers.resetSearchContext(state: &state)
        state.spots = []
        ExploreHelpers.syncSelectedSpot(state: &state)
        return .merge(
          .run { send in
          let currentStatus = await locationUseCase.getAuthorizationStatus()
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
        ExploreHelpers.syncSelectionWithFilters(state: &state)
        return .none

      case .categoryTapped(let category):
        state.selectedCategory = category
        ExploreHelpers.syncSelectionWithFilters(state: &state)
        return .none

      case .spotTapped(let spotID):
        if state.userSession.selectedExploreSpotID == spotID, state.isSpotCardVisible {
          ExploreHelpers.clearSelectedSpot(state: &state)
          state.searchMarkerLat = nil
          state.searchMarkerLon = nil
          state.pendingSelectFirstSpotFromNextPage = false
          return .cancel(id: CancelID.searchPlaces)
        }

        state.$userSession.withLock {
          $0.selectedExploreSpotID = spotID
          $0.selectedExplorePlaceID = spotID
        }
        state.isSpotCardVisible = state.spots.contains(where: { $0.id == spotID && $0.hasDetail })
        #logDebug(" [ExploreReducer] spotTapped id=\(spotID), hasDetail=\(state.isSpotCardVisible)")
        guard !state.spots.contains(where: { $0.id == spotID && $0.hasDetail }),
              let markerSpot = state.spots.first(where: { $0.id == spotID }) else {
          return .none
        }

        state.searchMarkerLat = markerSpot.coordinate.latitude
        state.searchMarkerLon = markerSpot.coordinate.longitude
        ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)

        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.fetchPlaces))
        )

      case .detailTapped:
        guard state.remainingSelectedSpotMinutes > 0 else {
          state.alert = AlertState {
            TextState("방문 불가능해요")
          } actions: {
            ButtonState(action: .dismissAlert) {
              TextState("확인")
            }
          } message: {
            TextState("남은 체류 시간이 없어서 상세 보기를 열 수 없어요.")
          }
          return .none
        }
        return .send(.delegate(.presentExplorerDetail))

      case .spotCardChanged(let spotID):
        if let spotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = spotID
            $0.selectedExplorePlaceID = spotID
          }
          state.isSpotCardVisible = true
        } else {
          ExploreHelpers.clearSelectedSpot(state: &state)
          state.searchMarkerLat = nil
          state.searchMarkerLon = nil
          state.pendingSelectFirstSpotFromNextPage = false
          return .cancel(id: CancelID.searchPlaces)
        }
        return .none

      case .cardDragChanged(let offset):
        guard !state.isCardTransitioning else {
          return .none
        }
        let limitedOffset = max(min(offset, CardHelpers.cardTravelDistance), -CardHelpers.cardTravelDistance)
        state.cardDragOffset = limitedOffset
        return .none

      case .cardDragEnded(let translationWidth):
        guard !state.isCardTransitioning else {
          return .none
        }

        if translationWidth > CardHelpers.cardSwipeThreshold {
          return .send(.inner(.completeCardSwipe(next: false)))
        }

        if translationWidth < -CardHelpers.cardSwipeThreshold {
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

      case .mapCenterChanged(let coordinate):
        state.mapCenterLat = coordinate.latitude
        state.mapCenterLon = coordinate.longitude
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
        print("🟡 [CurrentLocationButton] CameraUseCase 사용")

        // CameraUseCase를 통한 스팟 클리어 처리
        let clearResult = cameraUseCase.clearSelectedSpotForLocationReturn(
          selectedSpotID: state.userSession.selectedExploreSpotID,
          isCardVisible: state.isSpotCardVisible
        )

        if clearResult.shouldClearSpot {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = ""
            $0.selectedExplorePlaceID = ""
          }
        }

        if clearResult.shouldDismissCard {
          ExploreHelpers.clearSelectedSpot(state: &state)
        }

        // 경로만 제거하고 역 목적지 마커는 유지
        state.routeInfo = nil

        // CameraUseCase를 통한 카메라 트리거 처리
        let cameraResult = cameraUseCase.createReturnToCurrentLocationTrigger(
          currentTrigger: state.returnToCurrentLocationTrigger,
          hasCurrentLocation: state.currentLocation != nil
        )

        if !cameraResult.shouldUpdateTrigger {
          state.shouldReturnToCurrentLocation = true
          return .send(.async(.requestCurrentLocation))
        }

        state.returnToCurrentLocationTrigger = cameraResult.newTrigger
        print("🟢 [CurrentLocationButton] CameraUseCase 처리 완료")
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

        // CameraUseCase를 통한 위치 업데이트 카메라 처리
        let cameraResult = cameraUseCase.handleLocationUpdateForCamera(
          shouldReturnToLocation: state.shouldReturnToCurrentLocation,
          currentTrigger: state.returnToCurrentLocationTrigger
        )

        if cameraResult.shouldUpdateTrigger {
          state.returnToCurrentLocationTrigger = cameraResult.newTrigger
        }

        if cameraResult.shouldResetFlag {
          state.shouldReturnToCurrentLocation = false
          return .none
        }
        if state.spots.isEmpty,
           !state.hasFetchedPlacesWithCurrentLocation,
           !state.isLoadingPlaces {
          ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)
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
        state.hasNextPage = entities.hasNextPage || ExploreHelpers.hasUnresolvedBaseSpots(entities.spots)
        state.hasFetchedPlacesWithCurrentLocation = usedCurrentLocation
        state.$userSession.withLock {
          $0.explorePlacesFetchedAt = Date()
        }
        return .none

      case .fetchPlacesFailed(let message, let usedCurrentLocation):
        state.hasRequestedPlaces = false
        ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)
        if usedCurrentLocation {
          state.hasFetchedPlacesWithCurrentLocation = false
        }
        #logDebug(" [ExploreReducer] 장소 조회 실패: \(message)")
        state.spots = []
        ExploreHelpers.clearSelectedSpot(state: &state)
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
        let currentKeyword = ExploreHelpers.currentKeyword(state: state)
        let currentCategory = ExploreHelpers.currentCategory(state: state)
        let currentMarkerLat: Double?
        let currentMarkerLon: Double?

        if ExploreHelpers.isResolvingSelectedMarkerDetail(state: state) {
          currentMarkerLat = state.searchMarkerLat
          currentMarkerLon = state.searchMarkerLon
        } else {
          currentMarkerLat = state.mapCenterLat ?? state.userSession.travelStationLat
          currentMarkerLon = state.mapCenterLon ?? state.userSession.travelStationLng
        }

        guard requestedPage == 0 || append else {
          return .none
        }

        if requestedMarkerLat != nil || requestedMarkerLon != nil {
          guard ExploreHelpers.isSameCoordinate(requestedMarkerLat, currentMarkerLat),
                ExploreHelpers.isSameCoordinate(requestedMarkerLon, currentMarkerLon) else {
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
        let newSpots = pageEntity.spots
        let mergedSpots: [ExploreMapSpot]
        if append {
          let existingSpotIDs = Set(state.spots.map(\.id))
          let uniqueNewSpots = newSpots.filter { !existingSpotIDs.contains($0.id) }
          mergedSpots = state.spots + uniqueNewSpots
        } else {
          mergedSpots = newSpots
        }
        state.currentPage = requestedPage + 1
        state.$userSession.withLock {
          $0.explorePlacesFetchedAt = Date()
        }
        let newDetailedCount = newSpots.filter(\.hasDetail).count
        let gainedMoreDetail = newDetailedCount > previousDetailedCount
        let shouldKeepBootstrappingDetails =
          requestedMarkerLat == nil
          && requestedMarkerLon == nil
          && requestedKeyword.isEmpty
          && requestedCategory == nil
          && ExploreHelpers.hasUnresolvedBaseSpots(newSpots)
          && (requestedPage == 0 || gainedMoreDetail)

        state.hasNextPage = pageEntity.hasNextPage || shouldKeepBootstrappingDetails
        let firstNewSpotID = newSpots.first(where: \.hasDetail)?.id
        let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty

        state.spots = mergedSpots
        if let selectedSpotID,
           mergedSpots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }) {
          state.isSpotCardVisible = true
        } else if state.searchMarkerLat != nil {
          state.isSpotCardVisible = false
        } else {
          ExploreHelpers.clearSelectedSpot(state: &state)
        }

        if state.pendingSelectFirstSpotFromNextPage, let firstNewSpotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = firstNewSpotID
            $0.selectedExplorePlaceID = firstNewSpotID
          }
          state.isSpotCardVisible = true
          state.pendingSelectFirstSpotFromNextPage = false
          state.cardBaseOffset = 0
          state.cardDragOffset = 0
          state.isCardTransitioning = false
          ExploreHelpers.syncSelectedSpot(state: &state)
          return .none
        }

        let wasPendingNextPage = state.pendingSelectFirstSpotFromNextPage
        state.pendingSelectFirstSpotFromNextPage = false
        ExploreHelpers.syncSelectedSpot(state: &state)

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
          ExploreHelpers.clearSelectedSpot(state: &state)
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
        let cameraResult = cameraUseCase.resetCameraFlag()
        if cameraResult.shouldResetFlag {
          state.shouldReturnToCurrentLocation = false
        }
        return .none

      case .completeCardSwipe(let next):
        let cardSpots = state.cardSpots
        guard !cardSpots.isEmpty else {
          #logDebug(" [ExploreReducer] completeCardSwipe ignored: cardSpots empty")
          return .none
        }

        let currentSelectedID = state.selectedSpot?.id ?? state.userSession.selectedExploreSpotID
        let currentIndex = cardSpots.firstIndex(where: { $0.id == currentSelectedID }) ?? 0
        let entryOffset: CGFloat = next ? CardHelpers.cardTravelDistance : -CardHelpers.cardTravelDistance
        let isAtEnd = next && currentIndex == cardSpots.count - 1
        let isAtStart = !next && currentIndex == 0

        state.isCardTransitioning = true
        state.cardDragOffset = next ? -CardHelpers.cardTravelDistance : CardHelpers.cardTravelDistance

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
            $0.selectedExplorePlaceID = cardSpots[0].id
          }
        } else if isAtStart {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = cardSpots[cardSpots.count - 1].id
            $0.selectedExplorePlaceID = cardSpots[cardSpots.count - 1].id
          }
        } else {
          let newIndex = next ? currentIndex + 1 : currentIndex - 1
          state.$userSession.withLock {
            $0.selectedExploreSpotID = cardSpots[newIndex].id
            $0.selectedExplorePlaceID = cardSpots[newIndex].id
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
          await locationUseCase.requestFullAccuracy()

          try await Task.sleep(for: .seconds(1))
          await send(.async(.startLocationUpdates))
        }

      case .startLocationUpdates:
        return .run { send in
          // UseCase를 통한 위치 업데이트 시작
          await locationUseCase.startLocationUpdates(
            onUpdate: { location in
              Task { @MainActor in
                send(.inner(.locationUpdated(location)))
              }
            },
            onError: { error in
              Task { @MainActor in
                send(.inner(.locationUpdateFailed(error.localizedDescription)))
              }
            }
          )

          // 초기 위치도 가져오기
          do {
            if let location = try await locationUseCase.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            }
          } catch {
            await send(.inner(.locationUpdateFailed(error.localizedDescription)))
          }
        }
        .cancellable(id: CancelID.startLocationUpdates, cancelInFlight: true)

      case .stopLocationUpdates:
        return .run { send in
          await locationUseCase.stopLocationUpdates()
        }

      case .requestCurrentLocation:
        return .run { send in
          do {
            if let location = try await locationUseCase.requestCurrentLocation() {
              await send(.inner(.locationUpdated(location)))
            } else {
              await send(.inner(.locationUpdateFailed("위치 정보를 가져올 수 없습니다")))
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
        let rawKeyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isResolvingSelectedMarkerDetail = ExploreHelpers.isResolvingSelectedMarkerDetail(state: state)
        let mapLat = isResolvingSelectedMarkerDetail
          ? (state.searchMarkerLat ?? state.userSession.travelStationLat ?? fallbackLat)
          : (state.mapCenterLat ?? state.userSession.travelStationLat ?? fallbackLat)
        let mapLon = isResolvingSelectedMarkerDetail
          ? (state.searchMarkerLon ?? state.userSession.travelStationLng ?? fallbackLng)
          : (state.mapCenterLon ?? state.userSession.travelStationLng ?? fallbackLng)
        let requestedMarkerLat = mapLat
        let requestedMarkerLon = mapLon
        let keyword = isResolvingSelectedMarkerDetail ? nil : rawKeyword.nilIfEmpty
        let category: ExploreCategory? = isResolvingSelectedMarkerDetail
          ? nil
          : (state.selectedCategory == .all ? nil : state.selectedCategory)
        let sortBy = "MAP_NEAREST"
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
              mapLat: mapLat,
              mapLon: mapLon,
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

      case .presentExplorerDetail:
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

private extension ExploreFeature.State {
  var remainingSelectedSpotMinutes: Int {
    guard let selectedSpot else {
      return 0
    }

    let originalMinutes = selectedSpot.originalStayableMinutes
    let elapsedMinutes = elapsedMinutesSincePlacesFetched
    return max(originalMinutes - elapsedMinutes, 0)
  }

  var elapsedMinutesSincePlacesFetched: Int {
    guard let fetchedAt = userSession.explorePlacesFetchedAt else {
      return 0
    }

    return max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
  }
}

private extension ExploreMapSpot {
  var originalStayableMinutes: Int {
    let digits = badgeText.compactMap(\.wholeNumberValue)
    guard !digits.isEmpty else { return 0 }
    return digits.reduce(0) { ($0 * 10) + $1 }
  }
}
