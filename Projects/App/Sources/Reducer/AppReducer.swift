//
//  AppReducer.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import Foundation
import Presentation
import Home
import ComposableArchitecture
import Entity
import LogMacro

@Reducer
public struct AppReducer: Sendable {
  public init() {}

  @ObservableState
  public enum State {
    case splash(SplashReducer.State)
    case home(HomeCoordinator.State)
    case auth(AuthCoordinator.State)


    public init() {
      self = .splash(.init())
    }

    // Animation identifier for SwiftUI transitions
    var animationID: String {
      switch self {
      case .splash: return "splash"
      case .auth: return "auth"
      case .home: return "home"
      }
    }
  }

  //MARK: - Action
  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
    case scope(ScopeAction)
  }

  @CasePathable
  public enum View {
    case presentView
    case presentRoot
    case presentAuth
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case updateToHome
    case updateToAuth
  }

  //MARK: - 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case startNotificationListener
    case refreshTokenExpired
  }

  //MARK: - 네비게이션 연결 액션
  public enum NavigationAction: Equatable {

  }

  //MARK: - 스코프 액션
  @CasePathable
  public enum ScopeAction {
    case splash(SplashReducer.Action)
    case home(HomeCoordinator.Action)
    case auth(AuthCoordinator.Action)
  }

  @Dependency(\.continuousClock) var clock

  private enum Constants {
    static let splashTransitionDelay: Duration = .seconds(2)
  }

  private enum CancelID {
    case refreshTokenExpiredListener
    case splashRouting
    case authEffects
    case mainEffects
  }

  public var body: some ReducerOf<Self> {
    EmptyReducer()
      .ifCaseLet(\.splash, action: \.scope.splash) {
      SplashReducer()
    }
    .ifCaseLet(\.home, action: \.scope.home) {
      HomeCoordinator()
    }
    .ifCaseLet(\.auth, action: \.scope.auth) {
      AuthCoordinator()
    }
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .inner(let innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .async(let asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case .navigation(let navigationAction):
        return handleNavigationAction(state: &state, action: navigationAction)

      case .scope(let scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)
      }
    }
  }
}

extension AppReducer {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .presentView:
      return .run { send in
//        await send(.scope(.splash(.view(.onAppear))))
      }

    case .presentRoot:
        state = .home(.init())
      return .none

    case .presentAuth:
      state = .auth(.init())
      return .concatenate(
        .cancel(id: CancelID.mainEffects),
      )

    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .startNotificationListener:
      return setupRefreshTokenExpiredListener()
        .cancellable(id: CancelID.refreshTokenExpiredListener, cancelInFlight: true)

    case .refreshTokenExpired:
      // Refresh token이 만료된 경우 로그인 화면으로 이동
      state = .auth(.init())
      return .concatenate(
        .cancel(id: CancelID.splashRouting),
        .cancel(id: CancelID.mainEffects),
      )
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    return .none
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    return .none
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
      case .splash(.navigation(.presentHome)):
        // 토큰이 있어서 메인 화면으로 이동
        return .run { send in
          try await clock.sleep(for: Constants.splashTransitionDelay)
          await send(.view(.presentRoot))
        }

      case .splash(.navigation(.presentAuth)):
        // 토큰이 없어서 로그인 화면으로 이동
        return .run { send in
          try await clock.sleep(for: Constants.splashTransitionDelay)
          await send(.view(.presentAuth))
        }

      case .auth(.navigation(.presentMain)):
        return .send(.view(.presentRoot))

      case .home(.router(.routeAction(id: _, action: .profile(.navigation(.presentAuth))))):
        return .send(.view(.presentAuth))

    default:
      return .none
    }
  }

  /// Refresh token 만료 감지 리스너 설정
  private func setupRefreshTokenExpiredListener() -> Effect<Action> {
    #logDebug("🔔 [AppReducer] 🚨 SETTING UP REFRESH TOKEN EXPIRED LISTENER...")
    return .publisher {
      NotificationCenter.default
        .publisher(for: NSNotification.Name("RefreshTokenExpired"))
        .map { notification in
          #logDebug("🔔 [AppReducer] 🔥 🎯 REFRESH TOKEN EXPIRED NOTIFICATION RECEIVED!")
          #logDebug("🔔 [AppReducer] Notification details: \(notification)")
          return Action.async(.refreshTokenExpired)
        }
    }
  }
}
