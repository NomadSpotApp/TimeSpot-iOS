//
//  ExploreFeature.swift
//  Home
//
//  Created by Wonji Suh on 2026-03-12
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
    case loadCachedSpots
    case searchRoute
  }

  // MARK: - 분리된 상태 구조체들
  @ObservableState
  public struct LocationState: Equatable {
    public var permissionStatus: CLAuthorizationStatus = .notDetermined
    public var currentLocation: CLLocation?
    public var isPermissionDenied: Bool = false
    public var error: String?

    public init() {}
  }

  @ObservableState
  public struct PlaceState: Equatable {
    public var spots: [ExploreMapSpot] = []
    public var searchText: String = ""
    public var selectedCategory: ExploreCategory = .all
    public var isLoading: Bool = false
    public var hasRequested: Bool = false
    public var hasFetchedWithCurrentLocation: Bool = false
    public var currentPage: Int = 1
    public var hasNextPage: Bool = true
    public var pendingSelectFirstSpot: Bool = false
    public var error: PlaceError?

    public init() {}
  }

  @ObservableState
  public struct RouteState: Equatable {
    public var selectedDestination: Destination?
    public var routeInfo: RouteInfo?
    public var isLoading: Bool = false
    public var error: String?

    public init() {}
  }

  @ObservableState
  public struct MapUIState: Equatable {
    public var searchMarkerLat: Double?
    public var searchMarkerLon: Double?
    public var mapCenterLat: Double?
    public var mapCenterLon: Double?
    public var shouldReturnToCurrentLocation: Bool = false
    public var returnToCurrentLocationTrigger: Int = 0
    public var isSpotCardVisible: Bool = false
    public var cardDragOffset: CGFloat = 0
    public var cardBaseOffset: CGFloat = 0
    public var isCardTransitioning: Bool = false

    public init() {}
  }

  @ObservableState
  public struct State: Equatable {
    // 분해된 상태들
    public var location = LocationState()
    public var place = PlaceState()
    public var route = RouteState()
    public var mapUI = MapUIState()

    // 공통 상태
    @Presents public var alert: AlertState<Alert>?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

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
    case returnToCurrentLocation
  }

  public enum InnerAction: Equatable {
    case locationPermissionStatusChanged(CLAuthorizationStatus)
    case locationUpdated(CLLocation)
    case locationUpdateFailed(String)
    case cachedSpotsLoaded(ExploreSpotPageEntity?)
    case fetchPlacesInitialResponse(ExploreSpotPageEntity, usedCurrentLocation: Bool)
    case fetchPlacesPageResponse(ExploreSpotPageEntity, request: FetchPlacesRequest)
    case fetchPlacesFailed(PlaceError, usedCurrentLocation: Bool)
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
    case loadCachedSpots
    case fetchPlaces(page: Int, append: Bool)
  }


  public enum DelegateAction: Equatable {
    case presentExploreList
    case presentExplorerDetail
    case presentRoute
  }

  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.placeUseCase) var placeUseCase
  @Dependency(\.locationUseCase) var locationUseCase
  @Dependency(\.cameraUseCase) var cameraUseCase
  @Dependency(\.analyticsUseCase) var analyticsUseCase

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
        let shouldBootstrap = state.place.spots.isEmpty && !state.place.hasRequested


        if let lat = state.userSession.travelStationLat,
           let lng = state.userSession.travelStationLng {
          state.route.selectedDestination = Destination(
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

        state.mapUI.isSpotCardVisible = false
        state.place.hasFetchedWithCurrentLocation = false
        ExploreHelpers.resetSearchContext(state: &state)
        ExploreHelpers.syncSelectedSpot(state: &state)
        return .merge(
          .run { send in
          let currentStatus = await locationUseCase.getAuthorizationStatus()
          await send(.inner(.locationPermissionStatusChanged(currentStatus)))
          },
          .send(.async(.loadCachedSpots)),
          .send(.async(.fetchPlaces(page: 1, append: false)))
        )

      case .onDisappear:
        return .none

      case .requestLocationPermission:
        return .none

      case .retryLocationPermission:
        state.location.isPermissionDenied = false
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
        state.place.searchText = text
        ExploreHelpers.syncSelectionWithFilters(state: &state)
        return .none

      case .categoryTapped(let category):
        state.place.selectedCategory = category
        ExploreHelpers.syncSelectionWithFilters(state: &state)
        return .none

      case .spotTapped(let spotID):
        if state.userSession.selectedExploreSpotID == spotID, state.mapUI.isSpotCardVisible {
          ExploreHelpers.clearSelectedSpot(state: &state)
          state.mapUI.searchMarkerLat = nil
          state.mapUI.searchMarkerLon = nil
          state.place.pendingSelectFirstSpot = false
          return .cancel(id: CancelID.fetchPlaces)
        }

        state.$userSession.withLock {
          $0.selectedExploreSpotID = spotID
          $0.selectedExplorePlaceID = spotID
        }
        state.mapUI.isSpotCardVisible = state.place.spots.contains(where: { $0.id == spotID && $0.hasDetail })
        if let selectedSpot = state.place.spots.first(where: { $0.id == spotID }) {
          analyticsUseCase.track(
            .place(
              .selected,
              PlaceEventData(
                placeID: selectedSpot.id,
                placeName: selectedSpot.name,
                category: selectedSpot.subtitle,
                placeType: selectedSpot.category.rawValue,
                stayableMinutes: selectedSpot.originalStayableMinutes,
                visitable: selectedSpot.visitable,
                source: "explore_map",
                stationID: state.userSession.travelID.nilIfEmpty,
                stationName: state.userSession.travelStationName.nilIfEmpty
              )
            )
          )
        }

        guard !state.place.spots.contains(where: { $0.id == spotID && $0.hasDetail }),
              let markerSpot = state.place.spots.first(where: { $0.id == spotID }) else {
          return .none
        }

        state.mapUI.searchMarkerLat = markerSpot.coordinate.latitude
        state.mapUI.searchMarkerLon = markerSpot.coordinate.longitude
        ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)

        return .merge(
          .cancel(id: CancelID.fetchPlaces),
          .send(.async(.fetchPlaces(page: 1, append: false)))
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
        if let selectedSpot = state.selectedSpot {
          analyticsUseCase.track(
            .place(
              .detailOpened,
              PlaceEventData(
                placeID: selectedSpot.id,
                placeName: selectedSpot.name,
                category: selectedSpot.subtitle,
                placeType: selectedSpot.category.rawValue,
                stayableMinutes: state.remainingSelectedSpotMinutes,
                visitable: selectedSpot.visitable,
                source: "explore_card",
                stationID: state.userSession.travelID.nilIfEmpty,
                stationName: state.userSession.travelStationName.nilIfEmpty
              )
            )
          )
        }
        return .send(.delegate(.presentExplorerDetail))

      case .spotCardChanged(let spotID):
        if let spotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = spotID
            $0.selectedExplorePlaceID = spotID
          }
          state.mapUI.isSpotCardVisible = true
        } else {
          ExploreHelpers.clearSelectedSpot(state: &state)
          state.mapUI.searchMarkerLat = nil
          state.mapUI.searchMarkerLon = nil
          state.place.pendingSelectFirstSpot = false
          return .cancel(id: CancelID.fetchPlaces)
        }
        return .none

      case .cardDragChanged(let offset):
        guard !state.mapUI.isCardTransitioning else {
          return .none
        }
        let limitedOffset = max(min(offset, UIScreen.cardTravelDistance), -UIScreen.cardTravelDistance)
        state.mapUI.cardDragOffset = limitedOffset
        return .none

      case .cardDragEnded(let translationWidth):
        guard !state.mapUI.isCardTransitioning else {
          return .none
        }

        if translationWidth > UIScreen.cardSwipeThreshold {
          return .send(.inner(.completeCardSwipe(next: false)))
        }

        if translationWidth < -UIScreen.cardSwipeThreshold {
          return .send(.inner(.completeCardSwipe(next: true)))
        }

        state.mapUI.cardDragOffset = 0
        return .none

      case .loadNextSpotPage:
        guard state.place.hasNextPage, !state.place.isLoading else {
          return .none
        }
        state.place.pendingSelectFirstSpot = true
        return .send(.async(.fetchPlaces(page: state.place.currentPage, append: true)))

      case .mapCenterChanged(let coordinate):
        state.mapUI.mapCenterLat = coordinate.latitude
        state.mapUI.mapCenterLon = coordinate.longitude
        return .none


      case .returnToCurrentLocation:


        // CameraUseCase를 통한 스팟 클리어 처리
        let clearResult = cameraUseCase.clearSelectedSpotForLocationReturn(
          selectedSpotID: state.userSession.selectedExploreSpotID,
          isCardVisible: state.mapUI.isSpotCardVisible
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
        state.route.routeInfo = nil

        // CameraUseCase를 통한 카메라 트리거 처리
        let cameraResult = cameraUseCase.createReturnToCurrentLocationTrigger(
          currentTrigger: state.mapUI.returnToCurrentLocationTrigger,
          hasCurrentLocation: state.location.currentLocation != nil
        )

        if !cameraResult.shouldUpdateTrigger {
          state.mapUI.shouldReturnToCurrentLocation = true
          return .send(.async(.requestCurrentLocation))
        }

        state.mapUI.returnToCurrentLocationTrigger = cameraResult.newTrigger

        return .none

    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case .locationPermissionStatusChanged(let status):
        state.location.permissionStatus = status

        switch status {
          case .authorizedWhenInUse, .authorizedAlways:
            state.location.isPermissionDenied = false
            state.alert = nil
            return .send(.async(.startLocationUpdates))
          case .denied, .restricted:
            state.location.isPermissionDenied = true
            state.alert = nil
            return .send(.async(.stopLocationUpdates))
          case .notDetermined:
            state.location.isPermissionDenied = false
            state.alert = nil
            return .none
          @unknown default:
            return .none
        }

      case .locationUpdated(let location):
        state.location.currentLocation = location

        // CameraUseCase를 통한 위치 업데이트 카메라 처리
        let cameraResult = cameraUseCase.handleLocationUpdateForCamera(
          shouldReturnToLocation: state.mapUI.shouldReturnToCurrentLocation,
          currentTrigger: state.mapUI.returnToCurrentLocationTrigger
        )

        if cameraResult.shouldUpdateTrigger {
          state.mapUI.returnToCurrentLocationTrigger = cameraResult.newTrigger
        }

        if cameraResult.shouldResetFlag {
          state.mapUI.shouldReturnToCurrentLocation = false
          return .none
        }
        if state.place.spots.isEmpty,
           !state.place.hasFetchedWithCurrentLocation,
           !state.place.isLoading {
          ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)
          return .merge(
            .cancel(id: CancelID.fetchPlaces),
            .cancel(id: CancelID.fetchPlaces),
            .send(.async(.fetchPlaces(page: 1, append: false)))
          )
        }
        return .none

      case .locationUpdateFailed(let error):
        #logDebug(" [ExploreReducer] 위치 업데이트 실패: \(error)")
        return .none

      case .cachedSpotsLoaded(let cached):
        // 네트워크 응답이 이미 도착해 spots가 채워진 경우 캐시 무시 (stale 방지)
        guard let cached, state.place.spots.isEmpty else { return .none }
        state.place.spots = cached.spots
        state.place.currentPage = cached.currentPage
        state.place.hasNextPage = cached.hasNextPage
        return .none

      case .fetchPlacesInitialResponse(let pageEntity, let usedCurrentLocation):

        state.place.isLoading = false
        state.place.hasRequested = false
        state.place.spots = pageEntity.spots

        state.place.currentPage = pageEntity.currentPage
        state.place.hasNextPage = pageEntity.hasNextPage || pageEntity.spots.contains { !$0.hasDetail }
        state.place.hasFetchedWithCurrentLocation = usedCurrentLocation
        state.$userSession.withLock {
          $0.explorePlacesFetchedAt = Date()
        }
        analyticsUseCase.track(
          .place(
            .listViewed,
            PlaceEventData(
              source: "explore_initial",
              resultCount: pageEntity.spots.count,
              stationID: state.userSession.travelID.nilIfEmpty,
              stationName: state.userSession.travelStationName.nilIfEmpty
            )
          )
        )
        return .none

      case .fetchPlacesPageResponse(let pageEntity, let request):
        state.place.isLoading = false
        state.place.hasRequested = false

        let previousDetailedCount = state.place.spots.filter(\.hasDetail).count
        let currentKeyword = ExploreHelpers.currentKeyword(state: state)
        let currentCategory = ExploreHelpers.currentCategory(state: state)
        let currentMarkerLat: Double?
        let currentMarkerLon: Double?

        if ExploreHelpers.isResolvingSelectedMarkerDetail(state: state) {
          currentMarkerLat = state.mapUI.searchMarkerLat
          currentMarkerLon = state.mapUI.searchMarkerLon
        } else {
          currentMarkerLat = state.mapUI.mapCenterLat ?? state.userSession.travelStationLat
          currentMarkerLon = state.mapUI.mapCenterLon ?? state.userSession.travelStationLng
        }

        guard request.page == 0 || request.append else {
          return .none
        }

        if request.markerLat != nil || request.markerLon != nil {
          guard CLLocationCoordinate2D.isSameCoordinate(request.markerLat, currentMarkerLat),
                CLLocationCoordinate2D.isSameCoordinate(request.markerLon, currentMarkerLon) else {
            return .none
          }
        } else {
          guard request.keyword == currentKeyword,
                request.category == currentCategory,
                request.markerLat == currentMarkerLat,
                request.markerLon == currentMarkerLon else {
            return .none
          }
        }

        state.place.hasFetchedWithCurrentLocation = request.usedCurrentLocation
        let newSpots = pageEntity.spots
        let mergedSpots: [ExploreMapSpot]
        if request.append {
          let existingSpotIDs = Set(state.place.spots.map(\.id))
          let uniqueNewSpots = newSpots.filter { !existingSpotIDs.contains($0.id) }
          mergedSpots = state.place.spots + uniqueNewSpots
        } else {
          mergedSpots = newSpots
        }
        state.place.currentPage = request.page + 1
        state.$userSession.withLock {
          $0.explorePlacesFetchedAt = Date()
        }
        let newDetailedCount = newSpots.filter(\.hasDetail).count
        let gainedMoreDetail = newDetailedCount > previousDetailedCount
        let shouldKeepBootstrappingDetails =
          request.markerLat == nil
          && request.markerLon == nil
          && request.keyword.isEmpty
          && request.category == nil
          && newSpots.contains { !$0.hasDetail }
          && (request.page == 0 || gainedMoreDetail)

        state.place.hasNextPage = pageEntity.hasNextPage || shouldKeepBootstrappingDetails
        let firstNewSpotID = newSpots.first(where: \.hasDetail)?.id
        let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty

        state.place.spots = mergedSpots
        if let selectedSpotID,
           mergedSpots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }) {
          state.mapUI.isSpotCardVisible = true
        } else if state.mapUI.searchMarkerLat != nil {
          state.mapUI.isSpotCardVisible = false
        } else {
          ExploreHelpers.clearSelectedSpot(state: &state)
        }

        if state.place.pendingSelectFirstSpot, let firstNewSpotID {
          state.$userSession.withLock {
            $0.selectedExploreSpotID = firstNewSpotID
            $0.selectedExplorePlaceID = firstNewSpotID
          }
          state.mapUI.isSpotCardVisible = true
          state.place.pendingSelectFirstSpot = false
          state.mapUI.cardBaseOffset = 0
          state.mapUI.cardDragOffset = 0
          state.mapUI.isCardTransitioning = false
          ExploreHelpers.syncSelectedSpot(state: &state)
          return .none
        }

        let wasPendingNextPage = state.place.pendingSelectFirstSpot
        state.place.pendingSelectFirstSpot = false
        ExploreHelpers.syncSelectedSpot(state: &state)

        if let selectedSpotID,
           state.mapUI.searchMarkerLat != nil,
           !state.place.spots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }),
           state.place.hasNextPage {
          return .send(.async(.fetchPlaces(page: state.place.currentPage, append: true)))
        }

        if let selectedSpotID,
           state.mapUI.searchMarkerLat != nil,
           !state.place.spots.contains(where: { $0.id == selectedSpotID && $0.hasDetail }),
           !state.place.hasNextPage {
          ExploreHelpers.clearSelectedSpot(state: &state)
        }

        if wasPendingNextPage {
          return .send(.inner(.finishCardTransition))
        }
        return .none

      case .fetchPlacesFailed(let error, let usedCurrentLocation):
        state.place.error = error
        state.place.hasRequested = false
        ExploreHelpers.resetSearchContext(state: &state, clearMarker: false)
        if usedCurrentLocation {
          state.place.hasFetchedWithCurrentLocation = false
        }
        state.place.spots = []
        ExploreHelpers.clearSelectedSpot(state: &state)
        return .none


      case .resetCameraFlag:
        let cameraResult = cameraUseCase.resetCameraFlag()
        if cameraResult.shouldResetFlag {
          state.mapUI.shouldReturnToCurrentLocation = false
        }
        return .none

      case .completeCardSwipe(let next):
        let cardSpots = state.cardSpots
        guard !cardSpots.isEmpty else {
          return .none
        }

        let currentSelectedID = state.selectedSpot?.id ?? state.userSession.selectedExploreSpotID
        let currentIndex = cardSpots.firstIndex(where: { $0.id == currentSelectedID }) ?? 0
        let entryOffset: CGFloat = next ? UIScreen.cardTravelDistance : -UIScreen.cardTravelDistance
        let isAtEnd = next && currentIndex == cardSpots.count - 1
        let isAtStart = !next && currentIndex == 0

        state.mapUI.isCardTransitioning = true
        state.mapUI.cardDragOffset = next ? -UIScreen.cardTravelDistance : UIScreen.cardTravelDistance

        if isAtEnd {
          if state.place.hasNextPage {
            state.mapUI.isSpotCardVisible = true
            state.mapUI.cardDragOffset = 0
            state.mapUI.cardBaseOffset = 0
            state.mapUI.isCardTransitioning = true
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

        state.mapUI.isSpotCardVisible = true
        state.mapUI.cardBaseOffset = entryOffset
        state.mapUI.cardDragOffset = 0

        return .run { send in
          try await Task.sleep(for: .milliseconds(240))
          await send(.inner(.finishCardTransition))
        }

      case .finishCardTransition:
        state.mapUI.cardBaseOffset = 0
        state.mapUI.cardDragOffset = 0
        state.mapUI.isCardTransitioning = false
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

      case .loadCachedSpots:
        let userSession = state.userSession
        let fallbackLat = state.userSession.travelStationLat ?? 0
        let fallbackLng = state.userSession.travelStationLng ?? 0
        let userLat = state.location.currentLocation?.coordinate.latitude ?? fallbackLat
        let userLon = state.location.currentLocation?.coordinate.longitude ?? fallbackLng
        return .run { send in
          let cached = try? await placeUseCase.loadCachedExploreSpots(
            userSession: userSession,
            userLat: userLat,
            userLon: userLon,
            keyword: nil,
            category: nil,
            sort: "distanceFromStation,ASC",
            mapLat: nil,
            mapLon: nil,
            page: 1
          )
          await send(.inner(.cachedSpotsLoaded(cached)))
        }
        .cancellable(id: CancelID.loadCachedSpots)

      case .fetchPlaces(let page, let append):
        // 초기 로딩인 경우와 페이지네이션인 경우를 구분
        let isInitialLoad = page == 1 && !append
        #logDebug("🔍 [fetchPlaces] page=\(page), append=\(append), isInitialLoad=\(isInitialLoad)")

        if isInitialLoad {
          // 초기 로딩 조건
          let travelIDExists = Int(state.userSession.travelID) != nil
          let stationLatExists = state.userSession.travelStationLat != nil
          let stationLngExists = state.userSession.travelStationLng != nil
          let notLoading = !state.place.isLoading
          let notRequested = !state.place.hasRequested


          guard travelIDExists, stationLatExists, stationLngExists, notLoading, notRequested else {
            return .none
          }

        } else {
          // 페이지네이션 조건
          let travelIDExists = Int(state.userSession.travelID) != nil
          let notLoading = !state.place.isLoading
          let notRequested = !state.place.hasRequested


          guard travelIDExists, notLoading, notRequested else {
            return .none
          }
        }

        state.place.isLoading = true
        state.place.hasRequested = true
        let userSession = state.userSession
        let fallbackLat = state.userSession.travelStationLat ?? 0
        let fallbackLng = state.userSession.travelStationLng ?? 0
        let usedCurrentLocation = state.location.currentLocation != nil
        let userLat = state.location.currentLocation?.coordinate.latitude ?? fallbackLat
        let userLon = state.location.currentLocation?.coordinate.longitude ?? fallbackLng

        if isInitialLoad {
          // 초기 로딩: fetchInitialExploreSpots 사용
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
              await send(.inner(.fetchPlacesInitialResponse(entities, usedCurrentLocation: usedCurrentLocation)))
            case .failure(let error):
              await send(.inner(.fetchPlacesFailed(PlaceError.from(error), usedCurrentLocation: usedCurrentLocation)))
            }
          }
          .cancellable(id: CancelID.fetchPlaces, cancelInFlight: true)
        } else {
          // 페이지네이션: searchExploreSpots 사용
          let rawKeyword = state.place.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
          let isResolvingSelectedMarkerDetail = ExploreHelpers.isResolvingSelectedMarkerDetail(state: state)
          let mapLat = isResolvingSelectedMarkerDetail
            ? (state.mapUI.searchMarkerLat ?? state.userSession.travelStationLat ?? fallbackLat)
            : (state.mapUI.mapCenterLat ?? state.userSession.travelStationLat ?? fallbackLat)
          let mapLon = isResolvingSelectedMarkerDetail
            ? (state.mapUI.searchMarkerLon ?? state.userSession.travelStationLng ?? fallbackLng)
            : (state.mapUI.mapCenterLon ?? state.userSession.travelStationLng ?? fallbackLng)
          let requestedMarkerLat = mapLat
          let requestedMarkerLon = mapLon
          let keyword = isResolvingSelectedMarkerDetail ? nil : rawKeyword.nilIfEmpty
          let category: ExploreCategory? = isResolvingSelectedMarkerDetail
            ? nil
            : (state.place.selectedCategory == .all ? nil : state.place.selectedCategory)
          let sortBy = "distanceFromStation,ASC"
          let baseSpots = state.place.spots

          return .run { send in
            let result = await Result {
              try await placeUseCase.searchExploreSpots(
                baseSpots: baseSpots,
                userSession: userSession,
                userLat: userLat,
                userLon: userLon,
                keyword: keyword,
                category: category,
                sort: sortBy,
                mapLat: mapLat,
                mapLon: mapLon,
                page: page
              )
            }

            switch result {
            case .success(let entity):
              let request = FetchPlacesRequest(
                page: page,
                keyword: rawKeyword,
                category: category,
                markerLat: requestedMarkerLat,
                markerLon: requestedMarkerLon,
                append: append,
                usedCurrentLocation: usedCurrentLocation
              )
              await send(.inner(.fetchPlacesPageResponse(entity, request: request)))
            case .failure(let error):
              await send(.inner(.fetchPlacesFailed(PlaceError.from(error), usedCurrentLocation: false)))
            }
          }
          .cancellable(id: CancelID.fetchPlaces, cancelInFlight: true)
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

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentExploreList:
        return .none

      case .presentExplorerDetail:
        return .none

      case .presentRoute:
        // 현재 선택된 스팟의 위도와 경도를 UserSession에 저장
        if let selectedSpot = state.selectedSpot {
          state.$userSession.withLock {
            // 목적지 정보 저장
            $0.routeDestinationLat = selectedSpot.coordinate.latitude
            $0.routeDestinationLng = selectedSpot.coordinate.longitude
            $0.routeDestinationName = selectedSpot.name

            // 현재 위치도 함께 저장 (출발지)
            if let currentLocation = state.location.currentLocation {
              $0.routeStartLat = currentLocation.coordinate.latitude
              $0.routeStartLng = currentLocation.coordinate.longitude
            }
          }
        }
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
