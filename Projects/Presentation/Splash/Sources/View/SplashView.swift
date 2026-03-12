//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 3/1/26.
//

import SwiftUI

import ComposableArchitecture


public struct SplashView: View {
  @Bindable var store: StoreOf<SplashReducer>

  public init(store: StoreOf<SplashReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.white
        .edgesIgnoringSafeArea(.all)


      VStack {
        Text("hello")
      }
    }
    .onAppear {
      store.send(.navigation(.presentHome))
    }
  }
}
