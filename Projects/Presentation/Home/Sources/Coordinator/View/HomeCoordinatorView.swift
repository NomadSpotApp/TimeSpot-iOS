//
//  HomeCoordinatorView.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//

import SwiftUI
import ComposableArchitecture
import TCACoordinators

public struct HomeCoordinatorView: View {
  @Bindable var store: StoreOf<HomeCoordinator>
  
  public init(store: StoreOf<HomeCoordinator>) {
    self.store = store
  }
  
  public var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .home(let homeStore):
          HomeView(store: homeStore)
            .navigationBarBackButtonHidden()

        case .explore(let exploreStore):
          ExploreView(store: exploreStore)
            .navigationBarBackButtonHidden()
      }
    }
  }
}
