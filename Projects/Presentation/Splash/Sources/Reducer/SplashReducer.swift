//
//  SplashReducer.swift
//  Splash
//
//  Created by Wonji Suh  on 3/1/26.
//


import Foundation
import ComposableArchitecture
import UseCase


@Reducer
public struct SplashReducer {
  public init() {}

  private enum Constants {
    static let tokenCheckDelay: Duration = .seconds(1.5)
  }

  public struct State: Equatable {
    public var isCheckingToken = false
    public var hasValidToken = false

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case onAppear
  }

  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkToken
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case tokenCheckResult(Bool)
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case presentHome
    case presentAuth
  }

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

        case .navigation(let navigationAction):
          return handleNavigationAction(state: &state, action: navigationAction)
      }
    }
  }
}

extension SplashReducer {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .onAppear:
        state.isCheckingToken = true
        return .send(.async(.checkToken))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .checkToken:
        return .run { send in
          // 키체인에서 액세스 토큰 확인
          let token = await keychainManager.accessToken()
          let hasToken = token != nil && !token!.isEmpty

          // 1.5초 스플래시 시간 후 결과 전달
          do {
            try await Task.sleep(for: Constants.tokenCheckDelay)
            await send(.inner(.tokenCheckResult(hasToken)))
          } catch {
            // Task 취소 또는 기타 에러 처리
            await send(.inner(.tokenCheckResult(hasToken)))
          }
        }
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
      case .presentHome:
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
      case .tokenCheckResult(let hasToken):
        state.isCheckingToken = false
        state.hasValidToken = hasToken

        if hasToken {
          // 토큰이 있으면 메인 화면으로
          return .send(.navigation(.presentHome))
        } else {
          // 토큰이 없으면 로그인 화면으로
          return .send(.navigation(.presentAuth))
        }
    }
  }
}
