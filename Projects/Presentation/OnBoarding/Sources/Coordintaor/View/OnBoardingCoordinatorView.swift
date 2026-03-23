//
//  OnBoardingCoordinatorView.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/21/26.
//

import SwiftUI

import ComposableArchitecture
import TCACoordinators

public struct OnBoardingCoordinatorView: View {
  @Bindable var store: StoreOf<OnBoardingCoordinator>

  public init(store: StoreOf<OnBoardingCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screens in
      switch screens.case {
        case .onBoarding(let onBoardingStore):
          OnBoardingView(store: onBoardingStore)
            .navigationBarBackButtonHidden()
      }
    }
  }
}
