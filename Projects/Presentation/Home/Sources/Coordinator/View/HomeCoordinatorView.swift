//
//  HomeCoordinatorView.swift
//  Home
//
//  Created by Wonji Suh  on 3/24/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import TCAFlow
import Profile
import UseCase
import LogMacro

public struct HomeCoordinatorView: View {
  @Bindable var store: StoreOf<HomeCoordinator>

  public init(store: StoreOf<HomeCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
        case .home(let homeStore):
          HomeView(store: homeStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()
            .transition(.asymmetric(
              insertion: .move(edge: .leading),
              removal: .move(edge: .trailing)
            ))

        case .explore(let exploreStore):
          ExploreView(store: exploreStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()
           

        case .exploreList(let exploreListStore):
          ExploreListView(store: exploreListStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()


        case .exploreDetail(let exploreDetailStore):
          ExploreDetailView(store: exploreDetailStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

        case .profile(let profileStore):
          ProfileCoordinatorView(store: profileStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()
            .transition(.asymmetric(
              insertion: .move(edge: .trailing),
              removal: .move(edge: .leading)
            ))

        case .route(let routeStore):
          RouteView(store: routeStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

        case .routeNotification(let routeNotificationStore):
          RouteNotificationView(store: routeNotificationStore)
            .navigationBarBackButtonHidden()
            .enableSwipeBack()

      }
    }
    .animation(.easeInOut(duration: 0.35), value: store.routes)
  }
}
