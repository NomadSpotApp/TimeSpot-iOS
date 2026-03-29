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
      .presentDSModal(
          item: $store.scope(state: \.destination?.termsService, action: \.destination.termsService),
          height: .fraction(0.4),
          showDragIndicator: true
      ) { termServiceStore in
          TermsAgreementView(store: termServiceStore)
      }
      .toastOverlay()
    }
  }
}


extension LoginView {

  @ViewBuilder
  private func loginLogo() -> some View {
    VStack{
      Spacer()

      Image(asset: .logo)
        .resizable()
        .scaledToFit()
        .frame(width: 212, height: 38)




      Spacer()
    }
  }

  @ViewBuilder
  private func socialLoginButtons() -> some View {
    VStack(alignment: .center, spacing: 8) {
      ForEach(SocialType.allCases) { type in
        SocialLoginButton(store: store, type: type) {
          store.send(.view(.signInWithSocial(social: type)))
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
        .onTapGesture {
          store.send(.delegate(.presentPrivacyWeb))
        }


      Spacer()
        .frame(height: 70)
    }
  }

}
