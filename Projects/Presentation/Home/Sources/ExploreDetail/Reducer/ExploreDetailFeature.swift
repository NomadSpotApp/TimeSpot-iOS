//
//  ExploreDetailFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import ComposableArchitecture
import Entity
import UseCase

@Reducer
public struct ExploreDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var placeDetail: PlaceDetailEntity?
    public var isLoading: Bool = false
    public var errorMessage: String?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
  }

  public enum AsyncAction: Equatable {
    case fetchPlaceDetail
  }

  public enum InnerAction: Equatable {
    case fetchPlaceDetailResponse(Result<PlaceDetailEntity, PlaceError>)
  }

  public enum DelegateAction: Equatable {}

  @Dependency(\.placeUseCase) var placeUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
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

extension ExploreDetailFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .send(.async(.fetchPlaceDetail))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchPlaceDetail:
      guard let placeID = Int(state.userSession.selectedExplorePlaceID) else {
        state.errorMessage = PlaceError.placeNotFound.errorDescription
        return .none
      }

      state.isLoading = true
      state.errorMessage = nil
      let userSession = state.userSession

      return .run { send in
        let result = await Result {
          try await placeUseCase.detailPlace(
            userSession: userSession,
            placeId: placeID
          )
        }
        .mapError(PlaceError.from)

        await send(.inner(.fetchPlaceDetailResponse(result)))
      }
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {}
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .fetchPlaceDetailResponse(let result):
      state.isLoading = false

      switch result {
      case .success(let detail):
        state.placeDetail = detail
        state.errorMessage = nil
      case .failure(let error):
        state.errorMessage = error.errorDescription
      }
      return .none
    }
  }
}

extension ExploreDetailFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(placeDetail)
    hasher.combine(isLoading)
    hasher.combine(errorMessage)
    hasher.combine(userSession)
  }
}
