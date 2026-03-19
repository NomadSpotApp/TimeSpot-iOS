//
//  LoginView.swift
//  Auth
//
//  Created by Wonji Suh  on 3/17/26.
//

import SwiftUI

import DesignSystem
import Entity

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

        socialLoginButtons()

        guestLookAroundText()
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

  @ViewBuilder
  private func socialLoginButtons() -> some View {
    VStack(alignment: .center, spacing: 8) {
      ForEach(SocialType.allCases) { type in
        SocialLoginButton(store: store, type: type) {

        }

      }
    }
    .padding(.horizontal, 22)
  }

  @ViewBuilder
  private func guestLookAroundText() -> some View {
    VStack(alignment: .center) {
      Spacer()
        .frame(height: 16)

      Text("비회원으로 시작하기")
        .pretendardCustomFont(textStyle: .caption)
        .foregroundStyle(.gray800)
        .underline(true, color: .gray800.opacity(0.5))


      Spacer()
        .frame(height: 70)
    }
  }

}
