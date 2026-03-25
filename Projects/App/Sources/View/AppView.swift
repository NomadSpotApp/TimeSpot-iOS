//
//  AppView.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import SwiftUI

import Presentation


import ComposableArchitecture

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>

  var body: some View {

    ZStack {
      Color.white
        .edgesIgnoringSafeArea(.all)

      SwitchStore(store) { state in
        switch state {
          case .splash:
            if let store = store.scope(state: \.splash, action: \.scope.splash) {
              SplashView(store: store)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

          case .auth:
            if let store = store.scope(state: \.auth, action: \.scope.auth) {
              AuthCoordinatorView(store: store)
                .transition(.asymmetric(
                  insertion: .move(edge: .trailing),
                  removal: .move(edge: .leading)
                ))
            }

          case .home:
            if let store = store.scope(state: \.home, action: \.scope.home) {
              HomeCoordinatorView(store: store)
                .transition(.asymmetric(
                  insertion: .move(edge: .trailing),
                  removal: .move(edge: .leading)
                ))
            }

        }
      }

    }
    .animation(
      .spring(response: 0.52, dampingFraction: 0.94, blendDuration: 0.14),
      value: store.state.animationID
    )
  }
}
