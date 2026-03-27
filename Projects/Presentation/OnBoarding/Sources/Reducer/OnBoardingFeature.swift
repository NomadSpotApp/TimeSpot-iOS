//
//  OnBoardingFeature.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import Foundation
import ComposableArchitecture

import DesignSystem
import UseCase
import Entity
import LogMacro

@Reducer
public struct OnBoardingFeature {
  public init() {}

  private enum SharedKeys {
    static let userSession = "UserSession"
  }

  @ObservableState
  public struct State: Hashable {
    public init() {}
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    var stepRange: ClosedRange<Int> = 1...4
    var activeStep: Int = 1
    var selectedMap: ExternalMapType? = nil
    var loginEntity: LoginEntity? = nil
    @Shared(.inMemory(SharedKeys.userSession)) var userSession: UserSession = .empty
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
    case scope(ScopeAction)

  }

  @CasePathable
  public enum ScopeAction {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case nextStepButtonTapped
    case mapSelected(ExternalMapType)
  }



  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case signup
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case signUpResponse(Result<LoginEntity, SignUpError>)
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case onBoardingCompleted
  }

  nonisolated enum CancelID: Hashable {
    case signup
  }

  @Dependency(\.signUpUseCase) var signUpUseCase

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

        case .navigation(let navigationAction):
          return handleNavigationAction(state: &state, action: navigationAction)

        case .scope(let scopeAction):
          return handleScopeAction(state: &state, action: scopeAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension OnBoardingFeature {
  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case .customAlert(.presented(.confirmTapped)),
         .customAlert(.presented(.cancelTapped)),
         .customAlert(.dismiss):
      state.customAlert = nil
      return .none

    case .customAlert(.presented(.policyTapped)):
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .nextStepButtonTapped:
      if state.activeStep >= state.stepRange.upperBound {
        return .send(.async(.signup))
      }
      state.activeStep += 1
      return .none

    case .mapSelected(let mapType):
      state.selectedMap = state.selectedMap == mapType ? nil : mapType
        state.$userSession.withLock {
          $0.mapType = mapType
        }
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .signup:
        return .run { [
          userSession = state.userSession
        ] send in
          let signupResult = await Result {
            try await signUpUseCase.registerUser(userSession: userSession)
          }
            .mapError(SignUpError.from)
          return await send(.inner(.signUpResponse(signupResult)))
        }
        .cancellable(id: CancelID.signup, cancelInFlight: true)
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
    case .onBoardingCompleted:
      // Coordinator에서 처리
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {

      case .signUpResponse(let result):
        switch result {
          case .success(let data):
            state.loginEntity = data
            return .send(.navigation(.onBoardingCompleted))

          case .failure(let error):
            #logDebug("회원가입 실패", error.localizedDescription)
            state.customAlert = .alert(
              title: "회원가입 실패",
              message: error.errorDescription ?? "회원가입 중 문제가 발생했어요.",
              confirmTitle: "확인",
              cancelTitle: "닫기",
              isDestructive: false
            )
            return .none
        }
    }
  }
}

// MARK: - State Equatable & Hashable
extension OnBoardingFeature.State: Equatable {
  public static func == (lhs: OnBoardingFeature.State, rhs: OnBoardingFeature.State) -> Bool {
    lhs.stepRange == rhs.stepRange &&
    lhs.activeStep == rhs.activeStep &&
    lhs.selectedMap == rhs.selectedMap &&
    lhs.loginEntity == rhs.loginEntity
  }
}
extension OnBoardingFeature.State {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(customAlert != nil)
    hasher.combine(activeStep)
    hasher.combine(selectedMap)
  }
}
