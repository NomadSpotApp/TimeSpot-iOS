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
        }
      }

    }

  }
}

