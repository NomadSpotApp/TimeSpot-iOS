//
//  HomeCoordinatorView.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//

import SwiftUI
import ComposableArchitecture
import TCACoordinators
import Profile

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
            .transition(.asymmetric(
              insertion: .move(edge: .leading).combined(with: .opacity),
              removal: .move(edge: .trailing).combined(with: .opacity)
            ))

        case .explore(let exploreStore):
          ExploreView(store: exploreStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .bottom).combined(with: .opacity),
              removal: .move(edge: .top).combined(with: .opacity)
            ))

        case .profile(let profileStore):
          ProfileCoordinatorView(store: profileStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))
      }
    }
    .animation(.easeInOut(duration: 0.35), value: store.routes.count)
    .transaction { transaction in
      if store.routes.count > 1 {
        transaction.animation = .easeInOut(duration: 0.35)
      }
    }
  }
}
