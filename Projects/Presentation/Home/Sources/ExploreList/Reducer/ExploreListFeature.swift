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
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case searchPlaces(page: Int, append: Bool)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case searchPlacesResponse(ExploreSpotPageEntity, append: Bool, requestedPage: Int)
    case searchPlacesFailed(String)
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
        state.lastTriggeredLoadSpotID = nil
        return .none

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
          print("⏸️ [ExploreList] loadNextPage skipped: already loading")
          return .none
        }

        let visibleSpots = filteredSpots(from: state.spots, state: state)
        let bufferedVisibleSpots = filteredSpots(from: state.bufferedSpots, state: state)
        let currentLastSpotID = visibleSpots.last?.id

        guard state.lastTriggeredLoadSpotID != currentLastSpotID else {
          print("⏸️ [ExploreList] loadNextPage skipped: duplicate trigger for lastVisibleSpotID=\(currentLastSpotID ?? "nil")")
          return .none
        }

        if visibleSpots.count < bufferedVisibleSpots.count {
          state.lastTriggeredLoadSpotID = currentLastSpotID
          print(
            "📦 [ExploreList] reveal buffered chunk: lastVisibleSpotID=\(currentLastSpotID ?? "nil"), visible=\(visibleSpots.count), bufferedVisible=\(bufferedVisibleSpots.count), rawShown=\(state.spots.count), rawBuffered=\(state.bufferedSpots.count)"
          )
          revealNextVisibleChunk(state: &state)
          return .none
        }

        guard state.hasNextPage else {
          print(
            "⏹️ [ExploreList] loadNextPage skipped: no next page, lastVisibleSpotID=\(currentLastSpotID ?? "nil"), visible=\(visibleSpots.count), bufferedVisible=\(bufferedVisibleSpots.count)"
          )
          return .none
        }

        state.lastTriggeredLoadSpotID = currentLastSpotID
        print(
          "🌐 [ExploreList] request next page: page=\(state.currentPage), lastVisibleSpotID=\(currentLastSpotID ?? "nil"), visible=\(visibleSpots.count), bufferedVisible=\(bufferedVisibleSpots.count)"
        )
        return .send(.async(.searchPlaces(page: state.currentPage, append: true)))
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
        state.isLoading = false

        if append {
          let existingSpotIDs = Set(state.bufferedSpots.map(\.id))
          let uniqueNewSpots = pageEntity.spots.filter { !existingSpotIDs.contains($0.id) }
          let duplicateSpotIDs = pageEntity.spots
            .map(\.id)
            .filter { existingSpotIDs.contains($0) }

          print(
            "📥 [ExploreList] append response: requestedPage=\(requestedPage), responseCount=\(pageEntity.spots.count), uniqueNew=\(uniqueNewSpots.count), duplicates=\(duplicateSpotIDs.count), firstID=\(pageEntity.spots.first?.id ?? "nil"), lastID=\(pageEntity.spots.last?.id ?? "nil"), hasNextPage=\(pageEntity.hasNextPage)"
          )

          if uniqueNewSpots.isEmpty {
            let duplicatePreview = Array(duplicateSpotIDs.prefix(10)).joined(separator: ", ")
            print(
              "⚠️ [ExploreList] append response contained no new spots. duplicateIDs(prefix10)=[\(duplicatePreview)]"
            )
          }

          state.bufferedSpots.append(contentsOf: uniqueNewSpots)
          revealNextChunk(state: &state)
          print("🔄 [무한스크롤] 버퍼 총: \(state.bufferedSpots.count)개, 화면 노출: \(state.spots.count)개")
        } else {
          print(
            "📥 [ExploreList] initial response: requestedPage=\(requestedPage), responseCount=\(pageEntity.spots.count), firstID=\(pageEntity.spots.first?.id ?? "nil"), lastID=\(pageEntity.spots.last?.id ?? "nil"), hasNextPage=\(pageEntity.hasNextPage)"
          )
          state.bufferedSpots = pageEntity.spots
          state.spots = []
          revealNextChunk(state: &state)
          print("🆕 [새로고침] 버퍼 총: \(state.bufferedSpots.count)개, 화면 노출: \(state.spots.count)개")
        }

        state.currentPage = requestedPage + 1
        state.hasNextPage = pageEntity.hasNextPage
        return .none

      case .searchPlacesFailed:
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
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
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
        walkTimeText: walkTimeText
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
