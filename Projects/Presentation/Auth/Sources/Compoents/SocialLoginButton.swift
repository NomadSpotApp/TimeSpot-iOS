//
//  SocialLoginButton.swift
//  Auth
//
//  Created by Wonji Suh  on 3/19/26.
//

import SwiftUI
import AuthenticationServices

import DesignSystem
import Entity

import ComposableArchitecture



public struct SocialLoginButton: View {
  @State var store: StoreOf<LoginFeature>
  let type: SocialType
  let onTap: () -> Void
  @State private var isPressed = false

  public var body: some View {
    switch type {
      case .apple:
        <#code#>
      case .google:
        <#code#>
    }
  }
}


extension SocialLoginButton {

  @ViewBuilder
  private func appleLoginButton(
    type: SocialType,
    request: ASAuthorizationAppleIDRequest,
    onCompletion: Result<ASAuthorization, Error>
  ) -> some View {
    ZStack {
      SignInWithAppleButton(.signIn) { request in
        request(request)
      } onCompletion: { result in
        onCompletion(result)
      }
      .frame(height: 60)
      .allowsHitTesting(true)

      RoundedRectangle(cornerRadius: 20)
        .fill(.black)
        .frame(height: 60)
        .overlay {
          HStack(spacing: .zero) {
            Spacer()

            Image(assetName: type.image)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)

            Spacer()
              .frame(width: 8)

            Text("\(type.description)로 시작하기")
              .pretendardCustomFont(textStyle: .titleBold)
              .foregroundStyle(.black)
          }
        }
        .clipShape(Capsule())
    }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.52, dampingFraction: 0.94, blendDuration: 0.14), value: isPressed)
  }


  @ViewBuilder
  fileprivate func googleLoginButton(
    type: SocialType,
    onTap: @escaping () -> Void
  ) -> some View {
    VStack {
      RoundedRectangle(cornerRadius: 20)
        .stroke(.black.opacity(0.2), style: .init(lineWidth: 1))
        .frame(height: 60)
        .overlay {
          HStack(spacing: .zero) {
            Spacer()

            Image(assetName: type.image)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)

            Spacer()
              .frame(width: 8)

            Text("\(type.description)로 시작하기")
              .pretendardCustomFont(textStyle: .titleBold)
              .foregroundStyle(.black)
          }
        }
        .onTapGesture { onTap() }
        .clipShape(Capsule())
    }
  }
}
