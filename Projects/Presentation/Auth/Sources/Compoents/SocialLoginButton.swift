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
        appleLoginButton(type: type) { request in
          store.send(.async(.prepareAppleRequest(request)))
        } onCompletion: { result  in
          store.send(.async(.appleLogin(result, nonce: store.nonce)))
        }

      case .google:
        googleLoginButton(type: type, onTap: onTap)
    }
  }
}


extension SocialLoginButton {

  @ViewBuilder
  private func appleLoginButton(
    type: SocialType,
    request: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
  ) -> some View {
    ZStack {
      SignInWithAppleButton(.signIn) { req in
        request(req)
      } onCompletion: { result in
        onCompletion(result)
      }
      .frame(height: 60)
      .clipShape(Capsule())
      .allowsHitTesting(true)

      RoundedRectangle(cornerRadius: 20)
        .fill(.black)
        .frame(height: 60)
        .overlay {
          HStack(spacing: .zero) {
            Spacer()

            Image(systemName: type.image)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
              .foregroundStyle(.gray100)

            Spacer()
              .frame(width: 8)

            Text("\(type.description)로 시작하기")
              .pretendardCustomFont(textStyle: .titleBold)
              .foregroundStyle(.gray100)
            Spacer()
          }
        }
        .allowsHitTesting(false)
        .allowsTightening(false)
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
          RoundedRectangle(cornerRadius: 30)
              .stroke(.black.opacity(0.5), lineWidth: 1)
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

                      Spacer()
                  }
              }
              .clipShape(Capsule()) 
              .contentShape(Capsule())
              .onTapGesture { onTap() }
      }
  }
}
