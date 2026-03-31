//
//  ExploreListFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//


import Foundation
import CoreLocation
import ComposableArchitecture
import Entity
import UseCase
import Utill
import IdentifiedCollections
import LogMacro


@Reducer
public struct ExploreListFeature {
  public init() {}

  enum CancelID: Hashable {
    case fetchPlaces
  }

  @ObservableState
  public struct State: Equatable {
    public static let pageChunkSize = 50

    public var searchText: String = ""
    public var selectedCategory: ExploreCategory = .all
    public var selectedSort: ExploreListSort = .stationNearest
    public var requestSortBy: String = "distanceFromStation,ASC"
    public var spots: [ExploreMapSpot] = []
    public var bufferedSpots: [ExploreMapSpot] = []
    public var currentPage: Int = 1
    public var hasNextPage: Bool = true
    public var isLoading: Bool = false
    public var placeError: PlaceError? = nil
    public var currentLocation: CLLocationCoordinate2D?
    public var markerLat: Double?
    public var markerLon: Double?
    public var lastTriggeredLoadSpotID: String?
    public var hasLoadedInitialPage: Bool = false
    @Shared(.inMemory("UserSession")) public var userSession: UserSession = .empty


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
    case searchTextChanged(String)
    case categoryTapped(ExploreCategory)
    case sortTapped(ExploreListSort)
    case loadNextPage
    case spotCardTapped(ExploreMapSpot)
    // Explore에서 데이터 동기화
    case syncSpotsFromExplore([ExploreMapSpot], currentPage: Int, hasNextPage: Bool)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case fetchPlaces(page: Int, append: Bool, ignoreCategory: Bool = false)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case fetchPlacesResponse(PlaceSearchPageEntity, append: Bool, requestedPage: Int)
    case fetchPlacesFailed(PlaceError)
    case forceResetLoading
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
  }

  public enum DelegateAction: Equatable {
    case presentExploreMapAtCurrentLocation
    case presentExploreDetail
  }

  @Dependency(\.placeUseCase) var placeUseCase

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

extension ExploreListFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        guard !state.hasLoadedInitialPage else {
          return .none
        }
        state.hasLoadedInitialPage = true
        return .send(.async(.fetchPlaces(page: 1, append: false, ignoreCategory: true)))

      case .searchTextChanged(let text):
        state.searchText = text
        state.currentPage = 1
        state.hasNextPage = true
        state.lastTriggeredLoadSpotID = nil
        return .merge(
          .cancel(id: CancelID.fetchPlaces),
          .send(.async(.fetchPlaces(page: 1, append: false, ignoreCategory: false)))
        )

      case .categoryTapped(let category):
        state.selectedCategory = category
        state.lastTriggeredLoadSpotID = nil

        // 기존 데이터가 있으면 로컬 필터링만, 없으면 API 호출
        if !state.bufferedSpots.isEmpty {
          return .none
        } else {
          state.currentPage = 1
          state.hasNextPage = true
          return .merge(
            .cancel(id: CancelID.fetchPlaces),
            .send(.async(.fetchPlaces(page: 1, append: false, ignoreCategory: false)))
          )
        }

      case .sortTapped(let sort):
        state.selectedSort = sort
        state.requestSortBy = sort.rawValue
        state.currentPage = 1
        state.hasNextPage = true
        state.lastTriggeredLoadSpotID = nil
        return .merge(
          .cancel(id: CancelID.fetchPlaces),
          .send(.async(.fetchPlaces(page: 1, append: false, ignoreCategory: false)))
        )

      case .loadNextPage:
        #logDebug("[ExploreList loadNextPage 호출] isLoading=\(state.isLoading), hasNextPage=\(state.hasNextPage)")

        guard !state.isLoading else {
          #logDebug(" [ExploreList loadNextPage 차단] 로딩 중이므로 요청 차단")
          // 5초 후 강제 리셋 (무한 로딩 방지)
          return .run { send in
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5초
            await send(.inner(.forceResetLoading))
          }
        }

        let visibleSpots = filteredSpots(from: state.spots, state: state)
        let bufferedVisibleSpots = filteredSpots(from: state.bufferedSpots, state: state)
        let currentLastSpotID = visibleSpots.last?.id

        // 버퍼가 완전히 소진되지 않았을 때만 중복 체크
        let isBufferExhausted = visibleSpots.count >= bufferedVisibleSpots.count

        if !isBufferExhausted {
          guard state.lastTriggeredLoadSpotID != currentLastSpotID else {
            return .none
          }
        }

        if visibleSpots.count < bufferedVisibleSpots.count {
          state.lastTriggeredLoadSpotID = currentLastSpotID
          revealNextVisibleChunk(state: &state)
          return .none
        }

        guard state.hasNextPage else {
          return .none
        }

        state.lastTriggeredLoadSpotID = currentLastSpotID

        // 현재 버퍼 크기를 기준으로 다음 페이지 계산 (size=50 기준)
        let nextPage = (state.bufferedSpots.count / 50) + 1
        return .send(.async(.fetchPlaces(page: nextPage, append: true, ignoreCategory: false)))

      case .spotCardTapped(let spot):
        state.$userSession.withLock {
          $0.selectedExplorePlaceID = spot.id
        }
        return .send(.delegate(.presentExploreDetail))

      case .syncSpotsFromExplore(let spots, let currentPage, let hasNextPage):
        // Explore에서 전달받은 데이터로 동기화
        state.bufferedSpots = spots
        state.spots = []
        revealNextChunk(state: &state)
        state.currentPage = currentPage
        state.hasNextPage = hasNextPage
        state.hasLoadedInitialPage = true
        return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case let .fetchPlaces(page, append, ignoreCategory):
        guard !state.isLoading else {
          return .none
        }

        state.isLoading = true
        let userSession = state.userSession
        let fallbackLat = userSession.travelStationLat ?? 0
        let fallbackLon = userSession.travelStationLng ?? 0
        let userLat = state.currentLocation?.latitude ?? fallbackLat
        let userLon = state.currentLocation?.longitude ?? fallbackLon
        let trimmedKeyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyword = trimmedKeyword.isEmpty ? nil : trimmedKeyword

        // ignoreCategory가 true면 카테고리 조건 무시 (초기 로딩용)
        let category: ExploreCategory? = ignoreCategory ? nil : (state.selectedCategory == .all ? nil : state.selectedCategory)
        let sortBy = state.requestSortBy
        let mapLat = state.markerLat ?? userSession.travelStationLat
        let mapLon = state.markerLon ?? userSession.travelStationLng

        return .run { send in
          let result = await Result {
            try await placeUseCase.fetchPlaces(
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
          case .success(let pageEntity):
            await send(
              .inner(
                .fetchPlacesResponse(
                  pageEntity,
                  append: append,
                  requestedPage: page
                )
              )
            )
          case .failure(let error):
            await send(.inner(.fetchPlacesFailed(PlaceError.from(error))))
          }
        }
        .cancellable(id: CancelID.fetchPlaces, cancelInFlight: true)

    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentExploreMapAtCurrentLocation:
        return .none
      case .presentExploreDetail:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case let .fetchPlacesResponse(pageEntity, append, _):
        // 무조건 로딩 해제 (중복 데이터여도)
        state.isLoading = false

        #logDebug("📥 [ExploreList 응답] content.count=\(pageEntity.content.count), pageNumber=\(pageEntity.page), isLastPage=\(pageEntity.isLastPage)")

        // PlaceEntity를 ExploreMapSpot으로 변환
        let spots = makeSpots(from: pageEntity.content, userSession: state.userSession)

        #logDebug("📥 [ExploreList 변환] spots.count=\(spots.count), spots.first?.name=\(spots.first?.name ?? "nil")")

        if append {
          let existingSpotIDs = Set(state.bufferedSpots.map(\.id))
          let uniqueNewSpots = spots.filter { !existingSpotIDs.contains($0.id) }

          // 페이지 업데이트
          state.currentPage = max(pageEntity.page, 1)
          state.hasNextPage = !pageEntity.isLastPage

          #logDebug("📥 [ExploreList append] uniqueNewSpots.count=\(uniqueNewSpots.count), totalBuffered=\(state.bufferedSpots.count), currentPage=\(state.currentPage)")

          if !uniqueNewSpots.isEmpty {
            state.bufferedSpots.append(contentsOf: uniqueNewSpots)
            revealNextChunk(state: &state)
          } else {
            #logDebug("🚨 [ExploreList] 중복 데이터만 있음 - 무한 스크롤 계속 진행")
            // 중복이어도 페이지는 증가시켜서 다음 페이지를 시도
          }
        } else {
          state.bufferedSpots = spots
          state.spots = spots  // 카테고리 변경 시 모든 데이터 바로 표시
          state.currentPage = max(pageEntity.page, 1)
          state.hasNextPage = !pageEntity.isLastPage

        }

        return .none

      case .fetchPlacesFailed(let error):
        state.placeError = error
        state.isLoading = false
        return .none


      case .forceResetLoading:
        state.isLoading = false
        return .none
    }
  }
}

private extension ExploreListFeature {
  func revealNextChunk(state: inout State) {
    let nextCount = min(
      state.spots.count + State.pageChunkSize,
      state.bufferedSpots.count
    )
    state.spots = Array(state.bufferedSpots.prefix(nextCount))
  }

  func revealNextVisibleChunk(state: inout State) {
    let currentVisibleCount = filteredSpots(from: state.spots, state: state).count
    var nextCount = state.spots.count

    while nextCount < state.bufferedSpots.count {
      nextCount = min(nextCount + State.pageChunkSize, state.bufferedSpots.count)
      let nextSpots = Array(state.bufferedSpots.prefix(nextCount))
      let nextVisibleCount = filteredSpots(from: nextSpots, state: state).count

      state.spots = nextSpots

      if nextVisibleCount > currentVisibleCount || nextCount == state.bufferedSpots.count {
        return
      }
    }
  }

  func filteredSpots(from spots: [ExploreMapSpot], state: State) -> [ExploreMapSpot] {
    let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    #logDebug("🔍 [필터링 시작] totalSpots=\(spots.count), query='\(query)', selectedCategory=\(state.selectedCategory)")

    let filtered = spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory

      return hasDetail && matchesQuery && matchesCategory
    }

    return filtered
  }

  func makeSpots(
    from places: [PlaceEntity],
    userSession: UserSession
  ) -> [ExploreMapSpot] {
    places.map { place in
      let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
      let closingText: String

      if let closingTime = place.closingTime, !closingTime.isEmpty {
        closingText = closingTime.formattedClosingTimeText()
      } else {
        closingText = place.address
      }

      let distanceText: String
      let walkTimeText: String

      if let stationLat = userSession.travelStationLat,
         let stationLon = userSession.travelStationLng {
        let stationLocation = CLLocation(latitude: stationLat, longitude: stationLon)
        let placeLocation = CLLocation(latitude: place.lat, longitude: place.lon)
        let distanceInMeters = stationLocation.distance(from: placeLocation)
        let roundedDistance = Int((distanceInMeters / 10).rounded() * 10)
        let walkingMinutes = max(Int(ceil(distanceInMeters / 67)), 1)

        distanceText = "\(roundedDistance)m"
        walkTimeText = "\(userSession.travelStationName)역에서 약 \(walkingMinutes)분"
      } else {
        distanceText = ""
        walkTimeText = ""
      }

      return ExploreMapSpot(
        id: String(place.placeId),
        name: place.name,
        category: place.category,
        coordinate: coordinate,
        hasDetail: true,
        imageURL: place.imageURL,
        badgeText: place.stayableMinutes > 0 ? "\(place.stayableMinutes)분 체류 가능" : "",
        subtitle: place.category.title,
        statusText: place.visitable ? "영업 중" : "영업 종료",
        closingText: closingText,
        distanceText: distanceText,
        walkTimeText: walkTimeText,
        address: place.address,
        visitable: place.visitable
      )
    }
  }
}

extension ExploreListFeature.State {
  var shouldShowInitialSkeleton: Bool {
    spots.isEmpty && (!hasLoadedInitialPage || isLoading)
  }

  var isFilteringLocally: Bool {
    !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var shouldShowLoadMore: Bool {
    !isFilteringLocally && (spots.count < bufferedSpots.count || hasNextPage)
  }

  var filteredMapSpots: [ExploreMapSpot] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let sourceSpots = isFilteringLocally ? bufferedSpots : spots

    return sourceSpots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      let matchesCategory = selectedCategory == .all || spot.category == selectedCategory

      return hasDetail && matchesQuery && matchesCategory
    }
  }

  var shouldShowEmptyState: Bool {
    !isLoading && !spots.isEmpty && filteredMapSpots.isEmpty
  }
}

extension ExploreListFeature.State: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.searchText == rhs.searchText
    && lhs.selectedCategory == rhs.selectedCategory
    && lhs.selectedSort == rhs.selectedSort
    && lhs.spots == rhs.spots
    && lhs.placeError == rhs.placeError
    && lhs.currentLocation?.latitude == rhs.currentLocation?.latitude
    && lhs.currentLocation?.longitude == rhs.currentLocation?.longitude
    && lhs.userSession == rhs.userSession
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(searchText)
    hasher.combine(selectedCategory)
    hasher.combine(selectedSort)
    hasher.combine(spots)
    hasher.combine(placeError)
    hasher.combine(currentLocation?.latitude)
    hasher.combine(currentLocation?.longitude)
    hasher.combine(userSession)
  }
}
