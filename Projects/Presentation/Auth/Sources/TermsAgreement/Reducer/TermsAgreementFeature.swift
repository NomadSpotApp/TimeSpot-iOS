//
//  TermsAgreementFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 3/19/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI


@Reducer
public struct TermsAgreementFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable, Hashable {
    var privacyAgreed: Bool = false
    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case scope(ScopeAction)
    case delegate(DelegateAction)

  }

  //MARK: - ViewAction
  @CasePathable
  public enum View {
    case privacyAgreementTapped
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case close
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case presentPrivacyWeb
  }


  @Dependency(\.continuousClock) var clock

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(_):
          return .none

        case .view(let viewAction):
          return handleViewAction(state: &state, action: viewAction)

        case .scope(let scopeAction):
          return handleScopeAction(state: &state, action: scopeAction)

        case .delegate(let navigationAction):
          return handleNavigationAction(state: &state, action: navigationAction)
      }
    }
  }
}

extension TermsAgreementFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      case .privacyAgreementTapped:
        state.privacyAgreed.toggle()
        return .none
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
      case .close:
        // 약관 동의 완료 - 바로 종료 신호를 보냄
        return .none
    }
  }

  private func handleNavigationAction(
    state: inout State,
    action: DelegateAction
  )  -> Effect<Action> {
    switch action {
      case .presentPrivacyWeb:
        return .none
    }
  }
}


