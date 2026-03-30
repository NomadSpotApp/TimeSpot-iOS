//
//  LoginFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import Foundation
import AuthenticationServices

import Entity
import DesignSystem
import Utill

import ComposableArchitecture
import LogMacro

@Reducer
public struct LoginFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable, Hashable {
    @Presents var destination: Destination.State?
    var nonce: String = ""
    var appleAccessToken: String = ""
    var appleLoginFullName: ASAuthorizationAppleIDCredential?
    var loginEntity: LoginEntity?
    var currentSocialType: SocialType?
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    @Shared(.appStorage("selectedMapType")) var selectedMapTypeStorage: ExternalMapType = .naverMap

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case destination(PresentationAction<Destination.Action>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case signInWithSocial(social: SocialType)
  }

  @Reducer
  public enum Destination {
    case termsService(TermsAgreementFeature)
  }

  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction {
    case prepareAppleRequest(ASAuthorizationAppleIDRequest)
    case appleLogin(Result<ASAuthorization, Error>, nonce: String)
    case login(socialType: SocialType)
  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case clearDestination
    case loginResponse(Result<LoginEntity, AuthError>)
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentTermsAgreement
    case presentPrivacyWeb
    case presentOnBoarding
    case presentMain
    case presntGuestLookAround

  }

  nonisolated enum CancelID: Hashable {
    case googleOAuth
    case appleOAuth
  }



  @Dependency(\.appleManger) var appleLoginManger
  @Dependency(\.unifiedOAuthUseCase) var unifiedOAuthUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(_):
          return .none

        case .destination(let action):
          return handleDestinationAction(state: &state, action: action)

        case .view(let viewAction):
          return handleViewAction(state: &state, action: viewAction)

        case .async(let asyncAction):
          return handleAsyncAction(state: &state, action: asyncAction)

        case .inner(let innerAction):
          return handleInnerAction(state: &state, action: innerAction)

        case .delegate(let delegateAction):
          return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension LoginFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .signInWithSocial(let social):
        return .send(.async(.login(socialType: social)))
    }
  }



  private func handleDestinationAction(
    state: inout State,
    action: PresentationAction<Destination.Action>
  ) -> Effect<Action> {
    switch action {
      case .presented(.termsService(.scope(.close))):
        // destination 해제 후 온보딩으로 이동
        return .run { send in
          // clearDestination 생략하고 바로 온보딩으로 이동
          try await Task.sleep(for: .seconds(0.3))
          await send(.delegate(.presentOnBoarding))
        }


      case .presented(.termsService(.delegate(.presentPrivacyWeb))):
        return .send(.delegate(.presentPrivacyWeb))


      default:
        return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      case .prepareAppleRequest(let request):
        let nonce = appleLoginManger.prepare(request)
        state.nonce = nonce
        return .none

      case .appleLogin(let result, let nonce):
        state.currentSocialType = .apple
        return .run { send in
          guard
            case .success(let auth) = result,
            let credential = auth.credential as? ASAuthorizationAppleIDCredential,
            !nonce.isEmpty
          else {
            await send(.inner(.loginResponse(.failure(.invalidCredential("Apple 인증 정보가 없습니다")))))
            return
          }

          // Apple credential을 직접 처리하여 로그인 완료
          let outcome = await unifiedOAuthUseCase.processOAuthFlow(
            with: .apple,
            appleCredential: credential,
            nonce: nonce,
            googleToken: nil
          )
          await send(.inner(.loginResponse(outcome)))
        }
        .cancellable(id: CancelID.appleOAuth)

      case .login(let socialType):
        state.currentSocialType = socialType
        state.$userSession.withLock { $0.provider = socialType }
        return .run { [
          appleCredential = state.appleLoginFullName,
          nonce = state.nonce
        ] send in
          let outcome = await unifiedOAuthUseCase.processOAuthFlow(
            with: socialType,
            appleCredential: appleCredential,
            nonce: nonce,
            googleToken: ""
          )
          return await send(.inner(.loginResponse(outcome)))
        }
        .cancellable(id: socialType == .apple ? CancelID.appleOAuth : CancelID.googleOAuth)
    }
  }

  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      case .presentTermsAgreement:
        state.destination = .termsService(.init())
        return .none

      case .presentPrivacyWeb:
        state.destination = nil
        return .none

      case .presentOnBoarding:
        return .none

      case .presentMain:
        return .none

      case .presntGuestLookAround:
        // 비회원으로 시작하기
        state.$userSession.withLock { userSession in
          userSession.isGuest = true
        }
        return .send(.delegate(.presentOnBoarding))

    }
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .clearDestination:
      state.destination = nil
      return .none

      case .loginResponse(let result):
        switch result {
          case .success(let loginEntity):
            state.loginEntity = loginEntity
            state.$selectedMapTypeStorage.withLock {
              $0 = loginEntity.mapType ?? .appleMap
            }

            if loginEntity.isNewUser {
              return .send(.delegate(.presentTermsAgreement))
            } else {
              return .send(.delegate(.presentMain))
            }


          case .failure(let error):
            #logNetwork("로그인 실패", error.localizedDescription)
            let socialType = state.currentSocialType
            return .run { send in
              await MainActor.run {
                let errorMessage: String
                switch socialType {
                  case .apple:
                    errorMessage = "Apple 인증에 실패하였습니다."
                  case .google:
                    errorMessage = "구글 인증에 실패하였습니다."
                  default:
                    errorMessage = "인증에 실패했어요. 다시 시도해주세요."
                }
                ToastManager.shared.showError(errorMessage)
              }
            }
        }
    }
  }
}



// MARK: - State Equatable & Hashable
extension LoginFeature.State {
  public static func == (lhs: LoginFeature.State, rhs: LoginFeature.State) -> Bool {
    lhs.nonce == rhs.nonce &&
    lhs.appleAccessToken == rhs.appleAccessToken &&
    lhs.loginEntity == rhs.loginEntity &&
    lhs.currentSocialType == rhs.currentSocialType &&
    lhs.destination == rhs.destination
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(nonce)
    hasher.combine(appleAccessToken)
    hasher.combine(currentSocialType)
    hasher.combine(selectedMapTypeStorage)
  }
}

// MARK: - Destination State Equatable & Hashable
extension LoginFeature.Destination.State: Equatable {}
extension LoginFeature.Destination.State: Hashable {}
