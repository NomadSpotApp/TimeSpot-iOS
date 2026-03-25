//
//  ProfileFeature.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//


import Foundation
import ComposableArchitecture
import Entity

import  UseCase

@Reducer
public struct ProfileFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var travelHistorySort: TravelHistorySort = .recent
    var profileEntity: ProfileEntity?  = nil
    var errorMessage: String? = nil
    var isLoading: Bool = false

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
    case travelHistorySortSelected(TravelHistorySort)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case fetchUser
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case fetchUserResponse(Result<ProfileEntity, ProfileError>)
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {
    case presentBack
    case presentSetting
    case presentAuth

  }

  nonisolated enum CancelID: Hashable {
    case fetchUser
  }

  @Dependency(\.profileUseCase) var profileUseCase
  @Dependency(\.keychainManager) var keychainManager

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

extension ProfileFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .travelHistorySortSelected(let sort):
      state.travelHistorySort = sort
      return .none

      case .onAppear:
        return .run { send in
          await send(.async(.fetchUser))
        }

    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {

      case .fetchUser:
        state.isLoading = true
        return .run { send in
          let result = await Result {
            try await profileUseCase.fetchUser()

          }
            .mapError(ProfileError.from)
          return await send(.inner(.fetchUserResponse(result)))

        }
        .cancellable(id: CancelID.fetchUser, cancelInFlight: true)
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentBack:
        return .none

      case .presentSetting:
        return .none

      case .presentAuth:
        return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      case .fetchUserResponse(let result):
        state.isLoading = false
        switch result {
          case .success(let data):
            state.profileEntity = data
            state.errorMessage = nil
            return .none

          case .failure(let error):
            if error.shouldPresentAuth {
              state.profileEntity = nil
              state.errorMessage = nil
              return .run { send in
                try? await keychainManager.clear()
                await send(.delegate(.presentAuth))
              }
            }
            state.errorMessage = error.errorDescription
            return .none
        }
    }
  }
}


extension ProfileFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(travelHistorySort)
    hasher.combine(profileEntity)
    hasher.combine(errorMessage)
    hasher.combine(isLoading)
  }
}
