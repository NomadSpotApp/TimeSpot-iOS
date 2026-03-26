//
//  TrainStationFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation
import CoreLocation
import ComposableArchitecture

import DomainInterface
import UseCase
import Utill
import Entity

@Reducer
public struct TrainStationFeature {
  @Dependency(\.keychainManager) var keychainManager
  @Dependency(\.stationUseCase) var stationUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    var searchText: String = ""
    var shouldShowFavoriteSection: Bool = false
    var selectedStation: Station
    var favoriteItems: [FavoriteStationItemEntity] = []
    var favoriteRows: [StationRowModel] = []
    var nearbyRows: [StationRowModel] = []
    var majorRows: [StationRowModel] = []
    var isLoading: Bool = false
    var errorMessage: String?

    public init(selectedStation: Station = .seoul) {
      self.selectedStation = selectedStation
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
    case stationTapped(Station)
    case favoriteButtonTapped(StationRowModel)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkAccessToken
    case fetchStations
    case fetchFavoriteStations
    case addFavoriteStation(Int)
    case deleteFavoriteStation(Int)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case accessTokenChecked(Bool)
    case fetchStationsResponse(StationListEntity)
    case fetchStationsFailed(String)
    case fetchFavoriteStationsResponse(FavoriteStationEntity)
    case fetchFavoriteStationsFailed(String)
    case addFavoriteStationResponse
    case addFavoriteStationFailed(String)
    case deleteFavoriteStationResponse
    case deleteFavoriteStationFailed(String)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case stationSelected(Station)
  }


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

extension TrainStationFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      state.isLoading = true
      return .merge(
        .send(.async(.checkAccessToken)),
        .send(.async(.fetchStations))
      )

    case .stationTapped(let station):
      state.selectedStation = station
      return .send(.delegate(.stationSelected(station)))
    case .favoriteButtonTapped(let row):
      guard state.shouldShowFavoriteSection else { return .none }
      if row.isFavorite {
        return .send(.async(.deleteFavoriteStation(row.favoriteID ?? row.stationID)))
      } else {
        return .send(.async(.addFavoriteStation(row.stationID)))
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .checkAccessToken:
      return .run { [keychainManager] send in
        let accessToken = await keychainManager.accessToken()
        let hasAccessToken = !(accessToken?.isEmpty ?? true)
        await send(.inner(.accessTokenChecked(hasAccessToken)))
      }
    case .fetchStations:
      return .run { [stationUseCase] send in
        let locationManager = await LocationPermissionManager.shared
        let location = await MainActor.run { locationManager.currentLocation }
        let lat = location?.coordinate.latitude ?? 37.5666805
        let lng = location?.coordinate.longitude ?? 126.9784147

        do {
          let entity = try await stationUseCase.fetchStations(
            lat: lat,
            lng: lng,
            page: 1,
            size: 30
          )
          await send(.inner(.fetchStationsResponse(entity)))
        } catch {
          await send(.inner(.fetchStationsFailed(error.localizedDescription)))
        }
      }
    case .fetchFavoriteStations:
      return .run { [stationUseCase] send in
        do {
          let entity = try await stationUseCase.fetchFavoriteStations(
            page: 1,
            size: 30
          )
          await send(.inner(.fetchFavoriteStationsResponse(entity)))
        } catch {
          await send(.inner(.fetchFavoriteStationsFailed(error.localizedDescription)))
        }
      }
    case .addFavoriteStation(let stationID):
      return .run { [stationUseCase] send in
        do {
          _ = try await stationUseCase.addFavoriteStation(stationID: stationID)
          await send(.inner(.addFavoriteStationResponse))
        } catch {
          await send(.inner(.addFavoriteStationFailed(error.localizedDescription)))
        }
      }
    case .deleteFavoriteStation(let favoriteID):
      return .run { [stationUseCase] send in
        do {
          _ = try await stationUseCase.deleteFavoriteStation(favoriteID: favoriteID)
          await send(.inner(.deleteFavoriteStationResponse))
        } catch {
          await send(.inner(.deleteFavoriteStationFailed(error.localizedDescription)))
        }
      }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    default:
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .accessTokenChecked(let shouldShowFavoriteSection):
      state.shouldShowFavoriteSection = shouldShowFavoriteSection
      return .none
    case .fetchStationsResponse(let entity):
      state.nearbyRows = makeNearbyRows(entity.nearbyStations)
      state.majorRows = makeMajorRows(entity.stations.content)
      if state.shouldShowFavoriteSection {
        state.favoriteRows = makeFavoriteSummaryRows(entity.favoriteStations)
      }
      applyFavoriteState(state: &state)
      state.isLoading = false
      return .none
    case .fetchStationsFailed(let message):
      state.errorMessage = message
      state.isLoading = false
      return .none
    case .fetchFavoriteStationsResponse(let entity):
      state.favoriteItems = entity.items
      applyFavoriteState(state: &state)
      return .none
    case .fetchFavoriteStationsFailed(let message):
      if state.favoriteRows.isEmpty {
        state.errorMessage = message
      }
      return .none
    case .addFavoriteStationResponse:
      return .send(.async(.fetchFavoriteStations))
    case .addFavoriteStationFailed(let message):
      state.errorMessage = message
      return .none
    case .deleteFavoriteStationResponse:
      return .send(.async(.fetchFavoriteStations))
    case .deleteFavoriteStationFailed(let message):
      state.errorMessage = message
      return .none
    }
  }
}

extension TrainStationFeature.State: Hashable {}

private extension TrainStationFeature {
  func makeNearbyRows(_ stations: [StationSummaryEntity]) -> [StationRowModel] {
    stations.map { station in
      let normalizedName = normalizedStationName(station.name)
      return StationRowModel(
        id: "nearby-\(station.stationID)",
        favoriteID: nil,
        station: Station(displayName: normalizedName),
        stationID: station.stationID,
        stationName: normalizedName,
        badges: station.lines,
        distanceText: "2.3km",
        isFavorite: false
      )
    }
  }

  func makeMajorRows(_ stations: [StationSummaryEntity]) -> [StationRowModel] {
    stations.map { station in
      let normalizedName = normalizedStationName(station.name)
      return StationRowModel(
        id: "station-\(station.stationID)",
        favoriteID: nil,
        station: Station(displayName: normalizedName),
        stationID: station.stationID,
        stationName: normalizedName,
        badges: station.lines,
        distanceText: nil,
        isFavorite: false
      )
    }
  }

  func makeFavoriteRows(
    _ favorites: [FavoriteStationItemEntity],
    stationRows: [StationRowModel]
  ) -> [StationRowModel] {
    favorites.map { favorite in
      let normalizedName = normalizedStationName(favorite.stationName)
      let matchedLines = stationRows.first(where: {
        normalizedStationName($0.stationName) == normalizedName
      })?.badges ?? []

      return StationRowModel(
        id: "favorite-\(favorite.favoriteID)",
        favoriteID: favorite.favoriteID,
        station: Station(displayName: normalizedName),
        stationID: favorite.stationID,
        stationName: normalizedName,
        badges: matchedLines,
        distanceText: nil,
        isFavorite: true
      )
    }
  }

  func makeFavoriteSummaryRows(_ stations: [StationSummaryEntity]) -> [StationRowModel] {
    Array(
      Dictionary(
        uniqueKeysWithValues: stations.map { station in
          (normalizedStationName(station.name), station)
        }
      ).values
    )
    .sorted { $0.name < $1.name }
    .map { station in
      let normalizedName = normalizedStationName(station.name)
      return StationRowModel(
        id: "favorite-summary-\(station.stationID)",
        favoriteID: nil,
        station: Station(displayName: normalizedName),
        stationID: station.stationID,
        stationName: normalizedName,
        badges: station.lines,
        distanceText: nil,
        isFavorite: true
      )
    }
  }

  func applyFavoriteState(state: inout State) {
    let favoriteNameMap = Dictionary(
      uniqueKeysWithValues: state.favoriteItems.map {
        (normalizedStationName($0.stationName), $0.favoriteID)
      }
    )

    let stationRows = state.majorRows + state.nearbyRows
    state.favoriteRows = makeFavoriteRows(state.favoriteItems, stationRows: stationRows)

    state.nearbyRows = state.nearbyRows.map { row in
      let favoriteID = favoriteNameMap[normalizedStationName(row.stationName)]
      return StationRowModel(
        id: row.id,
        favoriteID: favoriteID,
        station: row.station,
        stationID: row.stationID,
        stationName: row.stationName,
        badges: row.badges,
        distanceText: row.distanceText,
        isFavorite: favoriteID != nil
      )
    }

    state.majorRows = state.majorRows.map { row in
      let favoriteID = favoriteNameMap[normalizedStationName(row.stationName)]
      return StationRowModel(
        id: row.id,
        favoriteID: favoriteID,
        station: row.station,
        stationID: row.stationID,
        stationName: row.stationName,
        badges: row.badges,
        distanceText: row.distanceText,
        isFavorite: favoriteID != nil
      )
    }
  }

  func normalizedStationName(_ name: String) -> String {
    name
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
