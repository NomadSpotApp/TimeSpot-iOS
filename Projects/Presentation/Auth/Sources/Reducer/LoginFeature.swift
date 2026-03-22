//
//  LoginFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import Foundation
import ComposableArchitecture

import Utill

@Reducer
public struct LoginFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable, Hashable {
    @Presents var destination: Destination.State?

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

  }

  @Reducer
  public enum Destination {
    case termsService(TermsAgreementFeature)
  }

  //MARK: - AsyncAction 비동기 처리 액션
  public enum AsyncAction: Equatable {

  }

  //MARK: - 앱내에서 사용하는 액션
  public enum InnerAction: Equatable {
    case clearDestination
  }

  //MARK: - DelegateAction
  public enum DelegateAction: Equatable {
    case presentTermsAgreement
    case presentPrivacyWeb
    case presentOnBoarding

  }


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

    }
  }



  private func handleDestinationAction(
    state: inout State,
    action: PresentationAction<Destination.Action>
  ) -> Effect<Action> {
    switch action {
      case .presented(.termsService(.scope(.close))):
        // 3초 후에 destination 해제
        return .run { send in
          try await Task.sleep(for: .seconds(1.2))
          await send(.inner(.clearDestination))
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
    }
  }
}



// MARK: - Destination State Equatable
extension LoginFeature.Destination.State: Equatable {}
extension LoginFeature.Destination.State: Hashable {}
