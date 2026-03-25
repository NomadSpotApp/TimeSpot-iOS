//
//  ProfileCoordinator.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import ComposableArchitecture
import TCACoordinators

@Reducer
public struct ProfileCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<ProfileScreen.State>]

    public init() {
      self.routes = [.root(.profile(.init()), embedInNavigationView: true)]
    }
  }

  public enum Action {
    case router(IndexedRouterActionOf<ProfileScreen>)
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
    case presentRoot
    case presentAuth

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

extension ProfileCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ProfileScreen>
  ) -> Effect<Action> {
    switch action {
      case .routeAction(id: _, action: .profile(.delegate(.presentBack))):
        return .send(.navigation(.presentRoot))

      case .routeAction(id: _, action: .profile(.delegate(.presentSetting))):
        state.routes.push(.setting(.init()))
        return .none

      case .routeAction(id: _, action: .profile(.delegate(.presentAuth))):
        return .send(.navigation(.presentAuth))

      case .routeAction(id: _, action: .setting(.delegate(.presentBack))):
        return .send(.view(.backAction))

      case .routeAction(id: _, action: .setting(.delegate(.presentAuth))):
        return .send(.navigation(.presentAuth))

      case .routeAction(id: _, action: .withDraw(.delegate(.presentBack))):
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
      case .presentRoot:
        return .none

      case .presentAuth:
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
    return .none
  }

}

extension ProfileCoordinator {
  @Reducer
  public enum ProfileScreen {
    case profile(ProfileFeature)
    case setting(SettingFeature)
    case withDraw(WithDrawFeature)
  }
}

// MARK: - AuthScreen State Equatable & Hashable
extension ProfileCoordinator.ProfileScreen.State: Equatable {}
extension ProfileCoordinator.ProfileScreen.State: Hashable {}

extension ProfileCoordinator.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(routes)
  }
}
