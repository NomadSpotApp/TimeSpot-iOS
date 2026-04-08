//
//  SplashReducer.swift
//  Splash
//
//  Created by Wonji Suh  on 3/1/26.
//


import Foundation
import ComposableArchitecture
import UseCase
import Entity
import LogMacro


@Reducer
public struct SplashReducer {
  public init() {}

  private enum Constants {
    static let tokenCheckDelay: Duration = .seconds(1.5)
  }

  @ObservableState
  public struct State: Equatable {
    public var isCheckingToken = false
    public var hasValidToken = false
    public var isCheckingUpdate = false
    public var showUpdateAlert = false
    public var updateInfo: AppUpdateInfo?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("selectedMapType")) var selectedMapTypeStorage: ExternalMapType = .naverMap

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
    case updateAlertConfirmed
    case updateAlertCancelled
  }

  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {
    case checkToken
    case syncMapType
    case checkAppUpdate
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case tokenCheckResult(Bool)
    case appUpdateCheckResult(AppUpdateInfo?)
  }

  //MARK: - NavigationAction
  public enum NavigationAction: Equatable {
    case presentHome
    case presentAuth
  }

  @Dependency(\.keychainManager) var keychainManager
  @Dependency(\.appUpdateUseCase) var appUpdateUseCase

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
        state.isCheckingUpdate = true
        return .merge(
          .send(.async(.syncMapType)),
          .send(.async(.checkToken)),
          .send(.async(.checkAppUpdate))
        )

      case .updateAlertConfirmed:
        if let updateInfo = state.updateInfo {
          // 앱스토어로 이동
          if let url = URL(string: updateInfo.appStoreUrl) {
            UIApplication.shared.open(url)
          }
        }
        return .none

      case .updateAlertCancelled:
        // 업데이트를 취소하면 앱을 종료하거나 다시 확인
        state.showUpdateAlert = false
        return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .syncMapType:
        // AppStorage에서 저장된 mapType을 UserSession에 동기화
        state.$userSession.withLock {
          $0.mapType = state.selectedMapTypeStorage
        }
        return .none

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

      case .checkAppUpdate:
        return .run { send in
          do {
            let updateInfo = try await appUpdateUseCase.checkForUpdate()
            await send(.inner(.appUpdateCheckResult(updateInfo)))
          } catch {
            #logError("앱 업데이트 확인 실패", error.localizedDescription)
            await send(.inner(.appUpdateCheckResult(nil)))
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

        // UserSession의 isGuest 상태 업데이트
        state.$userSession.withLock {
          $0.isGuest = !hasToken
        }

        return handleNavigationAfterChecks(state: &state)

      case .appUpdateCheckResult(let updateInfo):
        state.isCheckingUpdate = false
        state.updateInfo = updateInfo

        if updateInfo != nil {
          // 업데이트가 필요한 경우 팝업 표시
          state.showUpdateAlert = true
          return .none
        } else {
          // 업데이트가 필요 없는 경우
          return handleNavigationAfterChecks(state: &state)
        }
    }
  }

  // MARK: - Helper Methods
  private func handleNavigationAfterChecks(
    state: inout State
  ) -> Effect<Action> {
    // 토큰 체크와 업데이트 체크가 모두 완료되고, 업데이트 팝업이 필요 없을 때만 네비게이션
    guard !state.isCheckingToken && !state.isCheckingUpdate && !state.showUpdateAlert else {
      return .none
    }

    if state.hasValidToken {
      // 토큰이 있으면 메인 화면으로
      return .send(.navigation(.presentHome))
    } else {
      // 토큰이 없으면 로그인 화면으로
      return .send(.navigation(.presentAuth))
    }
  }
}
