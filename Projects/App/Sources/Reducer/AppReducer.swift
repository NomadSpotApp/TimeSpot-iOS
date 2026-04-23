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
import UseCase

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
    case handlePushNotificationDeepLink(String)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case updateToHome
    case updateToAuth
    case setupPushNotificationObserver
    case handlePushDeepLink(String)
    case checkPendingPushDeepLink
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
  @Dependency(\.authUseCase) var authUseCase

  private enum Constants {
    static let splashTransitionDelay: Duration = .seconds(2)
  }

  // 🎯 PFW 패턴: 단순하고 명확한 CancelID
  private enum CancelID {
    case refreshTokenExpiredListener
    case splashRouting
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
      #logDebug("🏠 AppReducer: Home 상태로 전환, 대기 중인 딥링크 확인")

      // 🎯 PFW 패턴: cancel 액션을 현재 case(.auth)에서 먼저 처리하도록 순서 보장
      // state 전환은 이후 .updateToHome 액션에서 수행하여 ifCaseLet 라우팅 실패 방지
      let cancelAuthEffects: Effect<Action> = {
        switch state {
        case .auth:
          return .send(.scope(.auth(.inner(.cancelAllEffects))))
        default:
          return .none
        }
      }()

      let cancelSplashEffects = Effect<Action>.cancel(id: CancelID.splashRouting)

      return .concatenate(
        cancelAuthEffects,
        cancelSplashEffects,
        .send(.inner(.updateToHome))
      )

    case .presentAuth:
      // 🎯 PFW 패턴: cancel 액션을 현재 case(.home)에서 먼저 처리하도록 순서 보장
      let cancelHomeEffects: Effect<Action> = {
        switch state {
        case .home:
          return .send(.scope(.home(.inner(.cancelAllEffects))))
        default:
          return .none
        }
      }()

      let cancelSplashEffects = Effect<Action>.cancel(id: CancelID.splashRouting)

      return .concatenate(
        cancelHomeEffects,
        cancelSplashEffects,
        .send(.inner(.updateToAuth))
      )

    case .handlePushNotificationDeepLink(let urlString):
      #logDebug("🔗 AppReducer: 푸쉬 딥링크 처리 = \(urlString)")
      return .send(.inner(.handlePushDeepLink(urlString)))

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
      // 🎯 PFW 패턴: cancel 액션을 현재 case에서 먼저 처리하도록 순서 보장
      let cancelCurrentEffects: Effect<Action> = {
        switch state {
        case .home:
          return .send(.scope(.home(.inner(.cancelAllEffects))))
        case .auth:
          return .send(.scope(.auth(.inner(.cancelAllEffects))))
        case .splash:
          return .none
        }
      }()

      let cancelSplashEffects = Effect<Action>.cancel(id: CancelID.splashRouting)

      return .concatenate(
        cancelCurrentEffects,
        cancelSplashEffects,
        .send(.inner(.updateToAuth))
      )
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .updateToHome:
      // cancel 액션이 자식 reducer에서 처리된 이후 안전하게 state 전환
      if let pendingDeepLink = UserDefaults.standard.string(forKey: "pendingPushDeepLink") {
        #logDebug("📋 AppReducer: 대기 중인 딥링크 발견, 즉시 처리 = \(pendingDeepLink)")
        let visitingHistoryId = UserDefaults.standard.integer(forKey: "visitingHistoryId")
        #logDebug("🔍 AppReducer: 현재 visitingHistoryId = \(visitingHistoryId)")

        if (pendingDeepLink.contains("min_before")
            || pendingDeepLink.contains("min_after")
            || pendingDeepLink.contains("departure_time")
            || pendingDeepLink.contains("end_journey"))
          && visitingHistoryId > 0 {
          #logDebug("✅ AppReducer: 유효한 여정, RouteNotificationView 포함 Home 상태 생성")
          UserDefaults.standard.removeObject(forKey: "pendingPushDeepLink")
          state = .home(.init(withRouteNotification: true, deepLink: pendingDeepLink))
        } else {
          #logDebug("🔍 AppReducer: 여정 없음/일반 딥링크, 기본 Home 상태로 전환")
          UserDefaults.standard.removeObject(forKey: "pendingPushDeepLink")
          state = .home(.init())
        }
      } else {
        #logDebug("🔍 AppReducer: 대기 중인 딥링크 없음, 일반 Home 상태로 전환")
        state = .home(.init())
      }
      return .none

    case .updateToAuth:
      state = .auth(.init())
      return .none

    case .setupPushNotificationObserver:
      #logDebug("📱 AppReducer: 푸쉬 알림 옵저버 설정")
      return .run { send in
        for await notification in NotificationCenter.default.notifications(named: .pushNotificationDeepLink) {
          if let urlString = notification.userInfo?["url"] as? String {
            #logDebug("📱 AppReducer: 푸쉬 딥링크 수신 = \(urlString)")
            await send(.view(.handlePushNotificationDeepLink(urlString)))
          }
        }
      }

    case .handlePushDeepLink(let urlString):
      #logDebug("🔗 AppReducer: 딥링크 처리 = \(urlString)")

      // Home 상태일 때만 HomeCoordinator로 전달
      switch state {
      case .home:
        #logDebug("✅ AppReducer: Home 상태, HomeCoordinator로 딥링크 전달")
        // 시간 알림 딥링크면 RouteView로 이동
        if urlString.contains("min_before") || urlString.contains("min_after") || urlString.contains("departure_time") || urlString.contains("end_journey") {
          #logDebug("🚀 AppReducer: 시간 알림 딥링크 감지, HomeCoordinator로 전달")
          return .send(.scope(.home(.inner(.presentRouteFromPushNotification(urlString)))))
        }
        #logDebug("❌ AppReducer: 시간 알림 딥링크가 아님")
        return .none
      case .auth, .splash:
        #logDebug("⏳ AppReducer: 아직 Home 상태가 아님, 나중에 처리 필요")
        return .none
      }

    case .checkPendingPushDeepLink:
      #logDebug("🔍 AppReducer: 대기 중인 푸쉬 딥링크 확인")
      return .run { send in
        if let pendingDeepLink = UserDefaults.standard.string(forKey: "pendingPushDeepLink") {
          #logDebug("📋 AppReducer: 대기 중인 딥링크 발견 = \(pendingDeepLink)")
          UserDefaults.standard.removeObject(forKey: "pendingPushDeepLink")
          await send(.inner(.handlePushDeepLink(pendingDeepLink)))
        } else {
          #logDebug("🔍 AppReducer: 대기 중인 딥링크 없음")
        }
      }
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    return .none
  }

  // 🎯 PFW 철학: 타입 안전한 상태 검증
  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    // 🎯 PFW 패턴: 타입 안전한 상태 매칭
    switch (action, state) {
    case (.splash, .splash), (.home, .home), (.auth, .auth):
      // ✅ 올바른 상태 매칭 - 네비게이션 처리 진행
      break

    case (.splash, _), (.home, _), (.auth, _):
      // ✅ 상태 불일치 - PFW 철학: 조용히 무시
      return .none
    }

    // 🎯 PFW 패턴: 단순한 네비게이션 처리
    return handleScopeNavigation(action: action)
  }

  // 🎯 PFW 패턴: 네비게이션 로직 분리
  private func handleScopeNavigation(action: ScopeAction) -> Effect<Action> {
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

      case .home(.navigation(.presentAuth)):
        return .send(.view(.presentAuth))

    default:
      // 🎯 PFW 단순성: 하위 Coordinator의 내부 액션은 그대로 전달
      return .none
    }
  }

  /// Refresh token 만료 감지 리스너 설정
  private func setupRefreshTokenExpiredListener() -> Effect<Action> {
    #logDebug(" [AppReducer] 🚨 SETTING UP REFRESH TOKEN EXPIRED LISTENER...")
    return .publisher {
      NotificationCenter.default
        .publisher(for: NSNotification.Name("RefreshTokenExpired"))
        .map { notification in
          #logDebug(" [AppReducer] 🔥 🎯 REFRESH TOKEN EXPIRED NOTIFICATION RECEIVED!")
          #logDebug(" [AppReducer] Notification details: \(notification)")
          return Action.async(.refreshTokenExpired)
        }
    }
  }
}

// MARK: - Notification Extensions
extension Notification.Name {
  static let pushNotificationDeepLink = Notification.Name("pushNotificationDeepLink")
  static let dismissRouteNotification = Notification.Name("dismissRouteNotification")
}
