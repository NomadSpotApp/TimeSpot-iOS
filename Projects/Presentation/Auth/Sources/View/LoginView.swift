//
//  LoginView.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import SwiftUI

import DesignSystem

import ComposableArchitecture

public struct LoginView: View {
  @Bindable var store: StoreOf<LoginFeature>

  public init(store: StoreOf<LoginFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray100
        .edgesIgnoringSafeArea(.all)


      VStack {
        loginLogo()
      }
    }
  }
}


extension LoginView {

  @ViewBuilder
  private func loginLogo() -> some View {
    VStack{
      Spacer()

      Text("Time Spot")
        .font(.pretendardFontFamily(family: .SemiBold, size: 48))
        .foregroundStyle(.black)

      Spacer()
    }
  }

  
}
