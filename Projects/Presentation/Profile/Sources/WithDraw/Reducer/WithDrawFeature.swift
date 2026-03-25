//
//  WithDrawFeature.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//


import Foundation
import ComposableArchitecture

import DesignSystem
import Utill
import UseCase
import Entity

@Reducer
public struct WithDrawFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    var customAlertMode: CustomAlertMode? = nil
    var withdrawButtonTapped: Bool = false
    var withDrawEntity: LogoutEntity?  = nil
    var errorMessage: String? = nil
    public init() {}
  }

  enum CustomAlertMode: Equatable, Hashable {
    case withDrawError
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
    case scope(ScopeAction)

  }

  @CasePathable
  public enum ScopeAction {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case tapWithDrawAgree
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case withDraw
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case withDrawResponse(Result<LogoutEntity, AuthError>)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentBack
    case presentAuth

  }

  nonisolated enum CancelID: Hashable {
    case withDraw
  }

  @Dependency(\.authUseCase) var authUseCase

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

        case .scope(let scopeAction):
          return handleScopeAction(state: &state, action: scopeAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension WithDrawFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .tapWithDrawAgree:
        state.withdrawButtonTapped.toggle()
        return .none
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)),
         .customAlert(.presented(.cancelTapped)),
         .customAlert(.dismiss):
      state.customAlert = nil
      state.customAlertMode = nil
      return .none

    case .customAlert(.presented(.policyTapped)):
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .withDraw:
        return .run { send in
          let result = await Result {
            try await authUseCase.withDraw()
          }
            .mapError(AuthError.from)
          await send(.inner(.withDrawResponse(result)))
        }
        .cancellable(id: CancelID.withDraw, cancelInFlight: true)

    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentBack:
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

      case .withDrawResponse(let result):
        switch result {
          case .success(let data):
            state.withDrawEntity = data
            state.errorMessage = nil
            state.customAlert = nil
            state.customAlertMode = nil
            return .send(.delegate(.presentAuth))

          case .failure(let error):
            state.errorMessage = error.localizedDescription
            state.customAlertMode = .withDrawError
            state.customAlert = .alert(
              title: "회원 탈퇴 실패",
              message: error.errorDescription ?? "회원 탈퇴 중 문제가 발생했어요.",
              confirmTitle: "확인",
              cancelTitle: "닫기",
              isDestructive: false
            )
            return .none
        }
    }
  }
}



extension WithDrawFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(customAlertMode)
    hasher.combine(withdrawButtonTapped )
    hasher.combine(withDrawEntity)
    hasher.combine(errorMessage)
  }
}
