//
//  OnBoardingCoordinator.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import ComposableArchitecture
import TCACoordinators

@Reducer
public struct OnBoardingCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable, Hashable {
    var routes: [Route<OnBoardingScreen.State>]

    public init() {
      self.routes = [.root(.onBoarding(.init()), withNavigation: true)]
    }
  }

  public enum Action {
    case router(IndexedRouterActionOf<OnBoardingScreen>)
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

  }

  // MARK: - NavigationAction
  public enum NavigationAction: Equatable {

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

extension OnBoardingCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<OnBoardingScreen>
  ) -> Effect<Action> {
    switch action {


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
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.goBackToRoot()
        }
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {

  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {

  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {

  }
}

extension OnBoardingCoordinator {
  @Reducer
  public enum OnBoardingScreen {
    case onBoarding(OnBoardingFeature)
  }
}

// MARK: - OnBoardingScreen State Equatable & Hashable
extension OnBoardingCoordinator.OnBoardingScreen.State: Equatable {}
extension OnBoardingCoordinator.OnBoardingScreen.State: Hashable {}
