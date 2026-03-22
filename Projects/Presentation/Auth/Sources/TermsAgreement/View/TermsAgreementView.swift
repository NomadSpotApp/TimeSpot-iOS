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
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
        .frame(height: 32) // 상단 간격 조정

      termsAgreementTitle()

      Spacer()
        .frame(height: 16) // 제목과 컨텐츠 사이 간격

      termsAgreementContent()

      Spacer() // 유연한 공간

      termsToggleButton()

      Spacer()
        .frame(height: 24) // 토글과 버튼 사이 간격

      confirmButton()

      Spacer()
        .frame(height: 16) // 하단 간격
    }
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(.white) // 배경색을 흰색으로
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
    VStack(alignment: .leading, spacing: 4) {
      Text("회원 가입 및 서비스 제공을 위해 개인정보를 ")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.gray800)

      Text("수집·이용합니다.")
        .pretendardCustomFont(textStyle: .bodyRegular)
        .foregroundStyle(.gray800)
    }
  }

  @ViewBuilder
  fileprivate func termsToggleButton() -> some View {
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

  @ViewBuilder
  fileprivate func confirmButton() -> some View {
    CustomButton(
      action: {
        modalDismiss()
        store.send(.scope(.close))
      },
      title: "확인",
      config: CustomButtonConfig.create(),
      isEnable: store.privacyAgreed
    )
  }
}
