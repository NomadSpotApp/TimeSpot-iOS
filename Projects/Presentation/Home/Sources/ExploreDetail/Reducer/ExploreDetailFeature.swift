//
//  ExploreDetailFeature.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import ComposableArchitecture
import DesignSystem
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
    public var shouldDismiss: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var customAlertMode: CustomAlertMode?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum ScopeAction {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum CustomAlertMode: Equatable {
    case visitUnavailable
    case networkError
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
      case .scope(let scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)
      case .delegate(let delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
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

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)):
      switch state.customAlertMode {
      case .visitUnavailable, .networkError:
        state.customAlert = nil
        state.customAlertMode = nil
        state.shouldDismiss = true
        return .none
      case .none:
        state.customAlert = nil
        return .none
      }

    case .customAlert(.presented(.cancelTapped)), .customAlert(.dismiss):
      state.customAlert = nil
      state.customAlertMode = nil
      return .none

    case .customAlert(.presented(.policyTapped)):
      return .none
    }
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
        if isVisitUnavailable(detail: detail, fetchedAt: state.userSession.explorePlacesFetchedAt) {
          state.customAlertMode = .visitUnavailable
          state.customAlert = .alert(
            title: "방문 불가능해요",
            message: "남은 체류 시간이 없어서 이전 화면으로 돌아갈게요.",
            confirmTitle: "확인",
            cancelTitle: "취소"
          )
        }
      case .failure(let error):
        state.errorMessage = error.errorDescription
        state.customAlertMode = .networkError
        state.customAlert = .alert(
          title: "오류가 발생했어요",
          message: error.errorDescription ?? "장소 정보를 불러오지 못했어요.",
          confirmTitle: "확인",
          cancelTitle: "취소"
        )
      }
      return .none
    }
  }

  private func isVisitUnavailable(
    detail: PlaceDetailEntity,
    fetchedAt: Date?
  ) -> Bool {
    let elapsedMinutes: Int
    if let fetchedAt {
      elapsedMinutes = max(Int(Date().timeIntervalSince(fetchedAt) / 60), 0)
    } else {
      elapsedMinutes = 0
    }
    return max(detail.stayableMinutes - elapsedMinutes, 0) <= 0
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
