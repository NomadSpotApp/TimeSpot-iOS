//
//  TrainStationFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation
import CoreLocation
import ComposableArchitecture
import IdentifiedCollections

import DomainInterface
import UseCase
import Utill
import Entity

@Reducer
public struct TrainStationFeature {
  @Dependency(\.keychainManager) var keychainManager
  @Dependency(\.stationUseCase) var stationUseCase

  public init() {}

  public enum CancelID: Hashable {
    case checkAccessToken
    case fetchStations
    case favoriteMutation
  }

  @ObservableState
  public struct State: Equatable {
    var searchText: String = ""
    var shouldShowFavoriteSection: Bool = false
    var selectedStation: Station
    var selectedStationID: Int?
    var favoriteRows: IdentifiedArrayOf<StationRowModel> = []
    var nearbyRows: IdentifiedArrayOf<StationRowModel> = []
    var majorRows: IdentifiedArrayOf<StationRowModel> = []
    var isLoading: Bool = false
    var errorMessage: String?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    public init(
      selectedStation: Station = .seoul,
      selectedStationID: Int? = nil
    ) {
      self.selectedStation = selectedStation
      self.selectedStationID = selectedStationID
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
    case stationTapped(StationRowModel)
    case favoriteButtonTapped(StationRowModel)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkAccessToken
    case fetchStations
    case addFavoriteStation(Int)
    case deleteFavoriteStation(favoriteID: Int, stationID: Int)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case accessTokenChecked(Bool)
    case fetchStationsResponse(StationListEntity)
    case fetchStationsFailed(String)
    case addFavoriteStationResponse
    case addFavoriteStationFailed(String)
    case deleteFavoriteStationResponse(Int)
    case deleteFavoriteStationFailed(String)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case stationSelected(StationRowModel)
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

      // 비회원인 경우 즐겨찾기 섹션은 표시하지 않음
      if state.userSession.isGuest {
        state.shouldShowFavoriteSection = false
        return .send(.async(.fetchStations))
      }

      return .merge(
        .send(.async(.checkAccessToken)),
        .send(.async(.fetchStations))
      )

    case .stationTapped(let row):
      guard let station = row.station else { return .none }
      state.selectedStation = station
      state.selectedStationID = row.stationID
      return .send(.delegate(.stationSelected(row)))
    case .favoriteButtonTapped(let row):
      // 비회원이거나 즐겨찾기 섹션이 비활성화된 경우 즐겨찾기 기능 사용 불가
      guard state.shouldShowFavoriteSection && !state.userSession.isGuest else { return .none }

      if row.isFavorite {
        guard let favoriteID = row.favoriteID else { return .none }
        return .send(.async(.deleteFavoriteStation(favoriteID: favoriteID, stationID: row.stationID)))
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
      .cancellable(id: CancelID.checkAccessToken)
    case .fetchStations:
      return .run { [stationUseCase] send in
        let locationManager = await LocationPermissionManager.shared
        let location = await MainActor.run { locationManager.currentLocation }
        let userLat = location?.coordinate.latitude ?? 37.5666805
        let userLon = location?.coordinate.longitude ?? 126.9784147

        do {
          let entity = try await stationUseCase.fetchStations(
            userLat: userLat,
            userLon: userLon,
            page: 1,
            size: 30
          )
          await send(.inner(.fetchStationsResponse(entity)))
        } catch {
          await send(.inner(.fetchStationsFailed(error.localizedDescription)))
        }
      }
      .cancellable(id: CancelID.fetchStations)
    case .addFavoriteStation(let stationID):
      return .run { [stationUseCase] send in
        do {
          _ = try await stationUseCase.addFavoriteStation(stationID: stationID)
          await send(.inner(.addFavoriteStationResponse))
        } catch {
          let nsError = error as NSError
          if nsError.domain == "StationFavoriteError", nsError.code == 409 {
            await send(.inner(.addFavoriteStationResponse))
            return
          }
          await send(.inner(.addFavoriteStationFailed(error.localizedDescription)))
        }
      }
      .cancellable(id: CancelID.favoriteMutation, cancelInFlight: true)
    case .deleteFavoriteStation(let favoriteID, let stationID):
      return .run { [stationUseCase] send in
        do {
          _ = try await stationUseCase.deleteFavoriteStation(favoriteID: favoriteID)
          await send(.inner(.deleteFavoriteStationResponse(stationID)))
        } catch {
          let nsError = error as NSError
          if nsError.domain == "StationFavoriteError", nsError.code == 404 {
            await send(.inner(.deleteFavoriteStationResponse(stationID)))
            return
          }
          await send(.inner(.deleteFavoriteStationFailed(error.localizedDescription)))
        }
      }
      .cancellable(id: CancelID.favoriteMutation, cancelInFlight: true)
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
      state.favoriteRows = StationRowModel.makeFavoriteRows(from: entity.favoriteStations)
      state.nearbyRows = StationRowModel.makeNearbyRows(from: entity.nearbyStations)
      state.majorRows = StationRowModel.makeMajorRows(from: entity.stations.content)

      // Avoid overlapping access by copying to local variables
      let favoriteRows = state.favoriteRows
      var nearbyRows = state.nearbyRows
      var majorRows = state.majorRows

      StationRowModel.applyFavoriteState(
        favoriteRows: favoriteRows,
        nearbyRows: &nearbyRows,
        majorRows: &majorRows
      )

      state.nearbyRows = nearbyRows
      state.majorRows = majorRows
      state.isLoading = false
      return .none
    case .fetchStationsFailed(let message):
      state.errorMessage = message
      state.isLoading = false
      return .none
    case .addFavoriteStationResponse:
      return .send(.async(.fetchStations))
    case .addFavoriteStationFailed(let message):
      state.errorMessage = message
      return .none
    case .deleteFavoriteStationResponse(let stationID):
      state.favoriteRows.removeAll { $0.stationID == stationID }

      let updatedNearbyRows = state.nearbyRows.map { row in
        guard row.stationID == stationID else { return row }
        let updatedEntity = StationEntity(
          id: row.stationEntity.id,
          favoriteID: nil,
          station: row.stationEntity.station,
          name: row.stationEntity.name,
          badges: row.stationEntity.badges,
          latitude: row.stationEntity.latitude,
          longitude: row.stationEntity.longitude,
          isFavorite: false
        )
        return StationRowModel(
          stationEntity: updatedEntity,
          distanceText: row.distanceText,
          rowType: "nearby"
        )
      }
      state.nearbyRows = IdentifiedArray(uniqueElements: updatedNearbyRows)

      let updatedMajorRows = state.majorRows.map { row in
        guard row.stationID == stationID else { return row }
        let updatedEntity = StationEntity(
          id: row.stationEntity.id,
          favoriteID: nil,
          station: row.stationEntity.station,
          name: row.stationEntity.name,
          badges: row.stationEntity.badges,
          latitude: row.stationEntity.latitude,
          longitude: row.stationEntity.longitude,
          isFavorite: false
        )
        return StationRowModel(
          stationEntity: updatedEntity,
          distanceText: row.distanceText,
          rowType: "station"
        )
      }
      state.majorRows = IdentifiedArray(uniqueElements: updatedMajorRows)
      return .none
    case .deleteFavoriteStationFailed(let message):
      state.errorMessage = message
      return .none
    }
  }
}

extension TrainStationFeature.State: Hashable {}

