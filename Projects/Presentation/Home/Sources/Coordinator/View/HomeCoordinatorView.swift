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
import UseCase
import LogMacro

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

        case .exploreList(let exploreListStore):
          ExploreListView(store: exploreListStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .exploreDetail(let exploreDetailStore):
          ExploreDetailView(store: exploreDetailStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .profile(let profileStore):
          ProfileCoordinatorView(store: profileStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .route(let routeStore):
          RouteView(store: routeStore)
            .navigationBarBackButtonHidden()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .routeNotification(let routeNotificationStore):
          RouteNotificationView(store: routeNotificationStore)
            .navigationBarBackButtonHidden()
            .transition(.opacity)

      }
    }
    .animation(.easeInOut(duration: 0.1), value: store.routes.count)
    .transaction { transaction in
      if store.routes.count > 1 {
        transaction.animation = .easeInOut(duration: 0.1)
      }
    }
  }
}

