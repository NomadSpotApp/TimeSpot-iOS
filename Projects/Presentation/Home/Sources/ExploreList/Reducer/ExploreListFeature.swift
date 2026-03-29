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

public enum ExploreListSort: String, CaseIterable, Equatable {
  case stationNearest = "STATION_NEAREST"
  case userNearest = "USER_NEAREST"

  public var title: String {
    switch self {
    case .stationNearest:
      return "역에서 가까운 순"
    case .userNearest:
      return "현재 위치로부터 가까운 순"
    }
  }
}

@Reducer
public struct ExploreListFeature {
  public init() {}

  enum CancelID: Hashable {
    case searchPlaces
  }

  @ObservableState
  public struct State: Equatable {
    public static let pageChunkSize = 10

    public var searchText: String = ""
    public var selectedCategory: ExploreCategory = .all
    public var selectedSort: ExploreListSort = .stationNearest
    public var requestSortBy: String = "STATION_NEAREST"
    public var spots: [ExploreMapSpot] = []
    public var bufferedSpots: [ExploreMapSpot] = []
    public var currentPage: Int = 0
    public var hasNextPage: Bool = true
    public var isLoading: Bool = false
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
    // Explore에서 데이터 동기화
    case syncSpotsFromExplore([ExploreMapSpot], currentPage: Int, hasNextPage: Bool)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case searchPlaces(page: Int, append: Bool)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case searchPlacesResponse(ExploreSpotPageEntity, append: Bool, requestedPage: Int)
    case searchPlacesFailed(String)
    case forceResetLoading
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
  }

  public enum DelegateAction: Equatable {
    case presentExploreMapAtCurrentLocation
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
        return .send(.async(.searchPlaces(page: 0, append: false)))

      case .searchTextChanged(let text):
        state.searchText = text
        state.lastTriggeredLoadSpotID = nil
        return .none

      case .categoryTapped(let category):
        state.selectedCategory = category
        state.currentPage = 0
        state.hasNextPage = true
        state.lastTriggeredLoadSpotID = nil
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.searchPlaces(page: 0, append: false)))
        )

      case .sortTapped(let sort):
        state.selectedSort = sort
        state.requestSortBy = sort.rawValue
        state.currentPage = 0
        state.hasNextPage = true
        state.lastTriggeredLoadSpotID = nil
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.searchPlaces(page: 0, append: false)))
        )

      case .loadNextPage:
        guard !state.isLoading else {
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
        return .send(.async(.searchPlaces(page: state.currentPage, append: true)))


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
      case let .searchPlaces(page, append):
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
        let category: ExploreCategory? = state.selectedCategory == .all ? nil : state.selectedCategory
        let sortBy = state.requestSortBy
        let mapLat = state.markerLat ?? userSession.travelStationLat
        let mapLon = state.markerLon ?? userSession.travelStationLng

        return .run { send in
          let result = await Result {
            try await placeUseCase.searchPlaces(
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
          case .success(let pageEntity):
            let spots = makeSpots(from: pageEntity.content, userSession: userSession)
            await send(
              .inner(
                .searchPlacesResponse(
                  ExploreSpotPageEntity(
                    spots: spots,
                    currentPage: pageEntity.page + 1,
                    hasNextPage: !pageEntity.isLastPage
                  ),
                  append: append,
                  requestedPage: page
                )
              )
            )
          case .failure(let error):
            await send(.inner(.searchPlacesFailed(error.localizedDescription)))
          }
        }
        .cancellable(id: CancelID.searchPlaces, cancelInFlight: true)

    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentExploreMapAtCurrentLocation:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case let .searchPlacesResponse(pageEntity, append, requestedPage):
        // 무조건 로딩 해제 (중복 데이터여도)
        state.isLoading = false

        if append {
          let existingSpotIDs = Set(state.bufferedSpots.map(\.id))
          let uniqueNewSpots = pageEntity.spots.filter { !existingSpotIDs.contains($0.id) }

          // 중복 데이터만 있어도 페이지는 업데이트
          state.currentPage = requestedPage + 1
          state.hasNextPage = pageEntity.hasNextPage

          if !uniqueNewSpots.isEmpty {
            state.bufferedSpots.append(contentsOf: uniqueNewSpots)
            revealNextChunk(state: &state)
          }
        } else {
          state.bufferedSpots = pageEntity.spots
          state.spots = pageEntity.spots  // 카테고리 변경 시 모든 데이터 바로 표시
          state.currentPage = requestedPage + 1
          state.hasNextPage = pageEntity.hasNextPage
        }

        return .none

      case .searchPlacesFailed:
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

    return spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesQuery
    }
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
        statusText: place.isOpen ? "영업 중" : "영업 종료",
        closingText: closingText,
        distanceText: distanceText,
        walkTimeText: walkTimeText,
        address: place.address
      )
    }
  }
}

extension ExploreListFeature.State: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.searchText == rhs.searchText
    && lhs.selectedCategory == rhs.selectedCategory
    && lhs.selectedSort == rhs.selectedSort
    && lhs.spots == rhs.spots
    && lhs.currentLocation?.latitude == rhs.currentLocation?.latitude
    && lhs.currentLocation?.longitude == rhs.currentLocation?.longitude
    && lhs.userSession == rhs.userSession
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(searchText)
    hasher.combine(selectedCategory)
    hasher.combine(selectedSort)
    hasher.combine(spots)
    hasher.combine(currentLocation?.latitude)
    hasher.combine(currentLocation?.longitude)
    hasher.combine(userSession)
  }
}
