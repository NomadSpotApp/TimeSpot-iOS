//
//  ProfileCoordinator.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import ComposableArchitecture
import TCAFlow
import Web

@FlowCoordinator(screen: "ProfileScreen", navigation: true)
public struct ProfileCoordinator {

  public init(){}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<ProfileScreen.State>]

    public init() {
      self.routes = [.root(.profile(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
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

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
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


      case .routeAction(id: _, action: .setting(.delegate(.presentWithDraw))):
        state.routes.push(.withDraw(.init()))
        return .none

      case .routeAction(id: _, action: .setting(.delegate(.presentNotificationSetting))):
        state.routes.push(.notification(.init()))
        return .none

      case .routeAction(id: _, action: .withDraw(.delegate(.presentBack))):
        return .send(.view(.backAction))

      case .routeAction(id: _, action: .withDraw(.delegate(.presentAuth))):
        return .send(.navigation(.presentAuth))

      case .routeAction(id: _, action: .notification(.delegate(.presentBack))):
        return .send(.view(.backAction))

      case .routeAction(id: _, action: .setting(.delegate(.presentPrivacyPolicy))):
        state.routes.push(.web(.init(url: "https://www.notion.so/329f94ae438b807d95dcd0f5f8abf66a?source=copy_link")))
        return .none

      case .routeAction(id: _, action: .setting(.delegate(.presentServicePolicy))):
        state.routes.push(.web(.init(url: "https://www.notion.so/329f94ae438b804d99a3f8ba2c761e15?source=copy_link")))
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
    case notification(NotificationSettingFeature)
    case web(WebFeature)
  }
}

// MARK: - ProfileScreen State Equatable
extension ProfileCoordinator.ProfileScreen.State: Equatable {}
