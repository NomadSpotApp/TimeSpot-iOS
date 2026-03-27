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
    public var searchText: String = ""
    public var selectedCategory: ExploreCategory = .all
    public var selectedSort: ExploreListSort = .stationNearest
    public var requestSortBy: String = "STATION_NEAREST"
    public var spots: [ExploreMapSpot] = []
    public var currentPage: Int = 0
    public var hasNextPage: Bool = true
    public var isLoading: Bool = false
    public var currentLocation: CLLocationCoordinate2D?
    public var markerLat: Double?
    public var markerLon: Double?
    @Shared(.inMemory("UserSession")) public var userSession: UserSession = .empty

    public init() {}

    public init(exploreState: ExploreReducer.State) {
      self.searchText = exploreState.searchText
      self.selectedCategory = exploreState.selectedCategory
      self.currentLocation = exploreState.currentLocation?.coordinate
      self.requestSortBy = "STATION_NEAREST"
      self.markerLat = exploreState.searchMarkerLat ?? exploreState.userSession.travelStationLat
      self.markerLon = exploreState.searchMarkerLon ?? exploreState.userSession.travelStationLng
      self.spots = exploreState.spots
      self.currentPage = exploreState.currentPage
      self.hasNextPage = exploreState.hasNextPage
    }
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
    case searchPlacesResponse(ExploreSpotPageEntity, append: Bool)
    case searchPlacesFailed(String)
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
  }

  public enum DelegateAction: Equatable {
    case presentExploreMap
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
        return .send(.async(.searchPlaces(page: 0, append: false)))

      case .searchTextChanged(let text):
        state.searchText = text
        state.currentPage = 0
        state.hasNextPage = true
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.searchPlaces(page: 0, append: false)))
        )

      case .categoryTapped(let category):
        state.selectedCategory = category
        state.currentPage = 0
        state.hasNextPage = true
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.searchPlaces(page: 0, append: false)))
        )

      case .sortTapped(let sort):
        state.selectedSort = sort
        state.requestSortBy = sort.rawValue
        state.currentPage = 0
        state.hasNextPage = true
        return .merge(
          .cancel(id: CancelID.searchPlaces),
          .send(.async(.searchPlaces(page: 0, append: false)))
        )

      case .loadNextPage:
        guard state.hasNextPage, !state.isLoading else {
          return .none
        }
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
        let baseSpots = state.spots
        let sortBy = state.requestSortBy
        let markerLat = state.markerLat ?? userSession.travelStationLat
        let markerLon = state.markerLon ?? userSession.travelStationLng

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
          case .success(let pageEntity):
            await send(.inner(.searchPlacesResponse(pageEntity, append: append)))
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
      case .presentExploreMap:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case let .searchPlacesResponse(pageEntity, append):
        state.isLoading = false
        state.spots = pageEntity.spots
        state.currentPage = pageEntity.currentPage
        state.hasNextPage = pageEntity.hasNextPage
        return .none

      case .searchPlacesFailed:
        state.isLoading = false
        return .none
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
