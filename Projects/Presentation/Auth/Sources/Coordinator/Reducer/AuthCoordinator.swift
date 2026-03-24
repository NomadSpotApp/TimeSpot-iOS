//
//  AuthCoordinator.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import ComposableArchitecture
import TCACoordinators
import OnBoarding

@Reducer
public struct AuthCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<AuthScreen.State>]

    public init() {
      self.routes = [.root(.login(.init()), withNavigation: true)]
    }
  }

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
  }

  // MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case presentMain
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
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
    .forEachRoute(\.routes, action: \.router)
  }

}

extension AuthCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AuthScreen>
  ) -> Effect<Action> {
    switch action {

      case .routeAction(id: _, action: .login(.delegate(.presentOnBoarding))):
        return .run { send in
          try await Task.sleep(for: .milliseconds(50))
          await send(.inner(.pushOnBoarding))
        }

      case .routeAction(id: _, action: .login(.delegate(.presentMain))):
        return .send(.navigation(.presentMain))

      case .routeAction(id: _, action: .onBoarding(.navigation(.presentMain))):
        return .send(.navigation(.presentMain))


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
        state.routes.push(.onBoarding(.init()))
        return .none
    }
  }
}

extension AuthCoordinator {
  @Reducer
  public enum AuthScreen {
    case login(LoginFeature)
    case onBoarding(OnBoardingCoordinator)
  }
}

// MARK: - AuthScreen State Equatable & Hashable
extension AuthCoordinator.AuthScreen.State: Equatable {}
extension AuthCoordinator.AuthScreen.State: Hashable {}
