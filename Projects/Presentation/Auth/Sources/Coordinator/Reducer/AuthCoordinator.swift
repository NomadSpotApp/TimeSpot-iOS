//
//  AuthCoordinator.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import ComposableArchitecture
import TCAFlow
import OnBoarding
import Web

@FlowCoordinator(screen: "AuthScreen", navigation: true)
public struct AuthCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<AuthScreen.State>]

    public init() {
      self.routes = [.root(.login(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AuthScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  // MARK: - ViewAction
  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  // MARK: - AsyncAction 비동기 처리 액션

  public enum AsyncAction: Equatable {

  }

  // MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case pushOnBoarding
    case performPushOnBoarding
  }

  // MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case presentMain
  }

  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
    switch action {
      case .router(let routeAction):
        return routerAction(state: &state, action: routeAction)

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

extension AuthCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AuthScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(id: _, action: .login(.delegate(.presentGuestLookAround))):
        return routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.push(.onBoarding(.init()))
        }

      case .routeAction(id: _, action: .login(.delegate(.presentOnBoarding))):
        return .send(.inner(.pushOnBoarding))

      case .routeAction(id: _, action: .login(.delegate(.presentMain))):
        return .send(.navigation(.presentMain))

      case .routeAction(id: _, action: .onBoarding(.navigation(.onBoardingCompleted))):
        return .send(.navigation(.presentMain))

      case .routeAction(id: _, action: .login(.delegate(.presentPrivacyWeb))):
        state.routes.push(.web(.init(url: "https://www.notion.so/329f94ae438b807d95dcd0f5f8abf66a?source=copy_link")))
        return .none

      case .routeAction(id: _, action: .web(.backToRoot)):
        return .send(.view(.backAction))

      default:
        return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .backAction:
        state.routes.goBack()
        return .none

      case .backToRootAction:
        state.routes.goBackToRoot()
        return .none
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
      case .presentMain:
        return .none
    }

  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
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
      case .pushOnBoarding:
        return .run { send in
          await Task.yield()
          await send(.inner(.performPushOnBoarding))
        }

      case .performPushOnBoarding:
        state.routes.push(.onBoarding(.init()))
        return .none
    }
  }

}

extension AuthCoordinator {
  @Reducer
  public enum AuthScreen {
    case login(LoginFeature)
    case onBoarding(OnBoardingFeature)
    case web(WebFeature)
  }
}

// MARK: - AuthScreen State Equatable
extension AuthCoordinator.AuthScreen.State: Equatable {}
