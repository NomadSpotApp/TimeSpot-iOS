//
//  ProfileFeature.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//


import Foundation
import ComposableArchitecture
import Entity

import UseCase

@Reducer
public struct ProfileFeature {
  private enum Constants {
    static let historyPageSize = 50
  }

  public init() {}

  @ObservableState
  public struct State: Equatable {
    var travelHistorySort: TravelHistorySort = .recent
    var profileEntity: ProfileEntity?  = nil
    var historyEntity: HistoryEntity? = nil
    var errorMessage: String? = nil
    var isLoading: Bool = false
    var isHistoryLoading: Bool = false
    var isHistoryLoadingMore: Bool = false
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("selectedMapType")) var selectedMapTypeStorage: ExternalMapType = .naverMap

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
    case historyRowAppeared(Int)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case fetchUser
    case fetchMyHistory(page: Int, reset: Bool)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case fetchUserResponse(Result<ProfileEntity, ProfileError>)
    case fetchMyHistoryResponse(Result<HistoryEntity, ProfileError>, reset: Bool)
  }

  //MARK: - NavigationAction
  public enum DelegateAction: Equatable {
    case presentBack
    case presentSetting
    case presentAuth

  }

  nonisolated enum CancelID: Hashable {
    case fetchUser
    case fetchMyHistory
  }

  @Dependency(\.profileUseCase) var profileUseCase
  @Dependency(\.historyUseCase) var historyUseCase
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
      return .send(.async(.fetchMyHistory(page: 1, reset: true)))

    case .historyRowAppeared(let id):
      guard
        let historyEntity = state.historyEntity,
        historyEntity.items.last?.id == id,
        let nextPage = historyEntity.nextPage,
        !state.isHistoryLoading,
        !state.isHistoryLoadingMore
      else {
        return .none
      }
      return .send(.async(.fetchMyHistory(page: nextPage, reset: false)))

      case .onAppear:
        return .merge(
          .send(.async(.fetchUser)),
          .send(.async(.fetchMyHistory(page: 1, reset: true)))
        )

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

      case .fetchMyHistory(let page, let reset):
        if reset {
          state.isHistoryLoading = true
          state.historyEntity = nil
        } else {
          state.isHistoryLoadingMore = true
        }
        return .run { [travelHistorySort = state.travelHistorySort] send in
          let result = await Result {
            try await historyUseCase.myHistory(
              page: page,
              size: Constants.historyPageSize,
              sort: travelHistorySort
            )
          }
          .mapError(ProfileError.from)
          await send(.inner(.fetchMyHistoryResponse(result, reset: reset)))
        }
        .cancellable(id: CancelID.fetchMyHistory, cancelInFlight: reset)
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
            state.$userSession.withLock {
              $0.name = state.profileEntity?.nickname ?? ""
              $0.mapType = state.profileEntity?.mapType ?? .appleMap
            }
            state.$selectedMapTypeStorage.withLock {
              $0 = state.profileEntity?.mapType ?? .appleMap
            }
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

      case .fetchMyHistoryResponse(let result, let reset):
        state.isHistoryLoading = false
        state.isHistoryLoadingMore = false
        switch result {
        case .success(let data):
          state.errorMessage = nil
          if reset || state.historyEntity == nil {
            state.historyEntity = data
          } else {
            state.historyEntity = HistoryEntity(
              items: (state.historyEntity?.items ?? []) + data.items,
              totalElements: data.totalElements,
              totalPages: data.totalPages,
              size: data.size,
              page: data.page,
              isFirstPage: data.isFirstPage,
              isLastPage: data.isLastPage
            )
          }
          return .none

        case .failure(let error):
          if error.shouldPresentAuth {
            state.historyEntity = nil
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
    hasher.combine(historyEntity)
    hasher.combine(errorMessage)
    hasher.combine(isLoading)
    hasher.combine(isHistoryLoading)
    hasher.combine(isHistoryLoadingMore)
    hasher.combine(userSession)
  }
}
