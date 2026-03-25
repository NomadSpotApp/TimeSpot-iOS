//
//  SettingFeature.swift
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
public struct SettingFeature {
  public init() {}

  enum CustomAlertMode: Equatable, Hashable {
    case logoutConfirmation
    case logoutError
  }

  @ObservableState
  public struct State: Equatable {
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    var customAlertMode: CustomAlertMode? = nil
    var logoutEntity: LogoutEntity? = nil
    var errorMessage: String? = nil

    public init() {}
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
    case timeNotificationRowTapped
    case logoutRowTapped
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case logout
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case presentLogoutConfirmationAlert
    case logoutResponse(Result<LogoutEntity, AuthError>)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentBack
    case presentAuth

  }

  nonisolated enum CancelID: Hashable {
    case logout
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

extension SettingFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .timeNotificationRowTapped:
      return .none
    case .logoutRowTapped:
      return .send(.inner(.presentLogoutConfirmationAlert))
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)):
      switch state.customAlertMode {
      case .logoutConfirmation:
        state.customAlert = nil
        state.customAlertMode = nil
        return .send(.async(.logout))

      case .logoutError:
        state.customAlert = nil
        state.customAlertMode = nil
          return .none

      case .none:
        state.customAlert = nil
        return .none
      }

    case .customAlert(.presented(.cancelTapped)),
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
      case .logout:
        return .run { send in
          let result = await Result {
            try await authUseCase.logout()
          }
            .mapError(AuthError.from)
          await send(.inner(.logoutResponse(result)))
        }
        .cancellable(id: CancelID.logout, cancelInFlight: true)

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
      case .presentLogoutConfirmationAlert:
        state.customAlertMode = .logoutConfirmation
        state.customAlert = .logout()
        return .none

      case .logoutResponse(let result):
        switch result {
          case .success(let data):
            state.logoutEntity = data
            state.errorMessage = nil
            state.customAlert = nil
            state.customAlertMode = nil
            return .send(.delegate(.presentAuth))

          case .failure(let error):
            state.errorMessage = error.errorDescription
            state.customAlertMode = .logoutError
            state.customAlert = .alert(
              title: "로그아웃 실패",
              message: error.errorDescription ?? "로그아웃 중 문제가 발생했어요.",
              confirmTitle: "다시 시도",
              cancelTitle: "닫기",
              isDestructive: false
            )
            return .none


        }
    }
  }
}

extension SettingFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(customAlertMode)
    hasher.combine(logoutEntity)
    hasher.combine(errorMessage)
  }
}
