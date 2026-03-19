//
//  TermsAgreementView.swift
//  Auth
//
//  Created by Wonji Suh  on 3/19/26.
//

import SwiftUI

import DesignSystem
import ComposableArchitecture

public struct TermsAgreementView: View {
  @Bindable var store: StoreOf<TermsAgreementFeature>
  @Environment(\.modalDismiss) private var modalDismiss

  public init(
    store: StoreOf<TermsAgreementFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .leading) {
      // 닫기 버튼
      Spacer()
        .frame(height: 24)

      termsAgreementTitle()

      termsAgreementContent()

      termsToggleButton()

      confirmButton()
    }
    .padding(.horizontal, 24)
    .background(.gray100)
  }
}


extension TermsAgreementView {

  @ViewBuilder
  fileprivate  func termsAgreementTitle() -> some View {
    VStack {
      HStack {
        Text("개인정보처리 방침에")
          .pretendardCustomFont(textStyle: .heading2)
          .foregroundStyle(.gray900)

        Spacer()
      }
      HStack {
        Text("동의하시겠습니까?")
          .pretendardCustomFont(textStyle: .heading2)
          .foregroundStyle(.gray900)

        Spacer()
      }
    }
  }

  @ViewBuilder
  fileprivate func termsAgreementContent() -> some View {
    VStack {
      Spacer()
        .frame(height: 12)

      HStack {
        Text("회원 가입 및 서비스 제공을 위해 개인정보를 ")
          .pretendardCustomFont(textStyle: .bodyRegular)
          .foregroundStyle(.gray800)

        Spacer()
      }
      HStack {
        Text("수집·이용합니다.")
          .pretendardCustomFont(textStyle: .bodyRegular)
          .foregroundStyle(.gray800)

        Spacer()
      }
    }
  }

  @ViewBuilder
  fileprivate func termsToggleButton() -> some View {
    VStack {
      Spacer()
        .frame(height: 24)

      TermsRowView(
        title: "개인정보처리 방침 동의",
        isOn: store.privacyAgreed,
        action: {
          store.send(.view(.privacyAgreementTapped))
        },
        onArrowTap: {
          store.send(.delegate(.presentPrivacyWeb))
        }
      )
    }
  }

  @ViewBuilder
  fileprivate func confirmButton() -> some View {
    VStack {
      Spacer()
        .frame(height: 32)

      CustomButton(
        action: {},
        title: "확인",
        config: CustomButtonConfig.create(),
        isEnable: store.privacyAgreed
      )

      Spacer()
    }
  }
}
