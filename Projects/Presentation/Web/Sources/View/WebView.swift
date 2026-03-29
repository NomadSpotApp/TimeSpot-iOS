//
//  WebView.swift
//  Profile
//
//  Created by Wonji Suh  on 1/4/26.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture


public struct WebView: View {
  @Bindable var store: StoreOf<WebFeature>

  public init(
    store: StoreOf<WebFeature>,
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.staticWhite
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()
          .frame(height: 8)

        CustomNavigationBackBar {
          store.send(.backToRoot)
        }

        Spacer()
          .frame(height: 20)

        WebRepresentableView(urlToLoad: store.url)
          .edgesIgnoringSafeArea(.bottom)
      }
      .navigationBarBackButtonHidden(true)
    }
  }
}

