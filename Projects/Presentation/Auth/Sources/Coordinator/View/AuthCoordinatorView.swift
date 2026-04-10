//
//  AuthCoordinatorView.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import SwiftUI

import ComposableArchitecture
import TCAFlow
import OnBoarding
import Web

public struct AuthCoordinatorView: View {
  @Bindable private var store: StoreOf<AuthCoordinator>

  public init(store: StoreOf<AuthCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screens in
      switch screens.case {
        case .login(let loginStore):
          LoginView(store: loginStore)
            .navigationBarBackButtonHidden()

        case .onBoarding(let onBoardingStore):
          OnBoardingView(store: onBoardingStore)
            .navigationBarBackButtonHidden()

        case .web(let webStore):
          WebView(store: webStore)
            .navigationBarBackButtonHidden()
      }
    }
  }
}
