//
//  TrainStationFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation
import ComposableArchitecture

import DomainInterface
import Utill
import Entity

@Reducer
public struct TrainStationFeature {
  @Dependency(\.keychainManager) var keychainManager

  public init() {}

  @ObservableState
  public struct State: Equatable {
    var searchText: String = ""
    var shouldShowFavoriteSection: Bool = false
    var selectedStation: Station

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
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkAccessToken
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case accessTokenChecked(Bool)
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
      return .send(.async(.checkAccessToken))

    case .stationTapped(let station):
      state.selectedStation = station
      return .send(.delegate(.stationSelected(station)))
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
    }
  }
}

extension TrainStationFeature.State: Hashable {}
