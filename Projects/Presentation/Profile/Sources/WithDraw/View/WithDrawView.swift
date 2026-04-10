//
//  WithDrawView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

import DesignSystem
import MixpanelSessionReplay

import ComposableArchitecture

public struct WithDrawView: View {
  @Bindable var store: StoreOf<WithDrawFeature>

  public init(
    store: StoreOf<WithDrawFeature>
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

        CustomNavigationBackBar(
          buttonAction: {
            store.send(.delegate(.presentBack))
          },
          title: "회원탈퇴"
        )

        titleHeaderView()

        warningContentView()

        withDrawAgreeButton()

        withDrawButton()

        Spacer()
      }
      .padding(.horizontal, 16)
      .mpReplaySensitive(true)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}


extension WithDrawView {

  @ViewBuilder
  fileprivate func titleHeaderView() -> some View {
    VStack(alignment: .center) {
      Spacer()
        .frame(height: 66)


      Text("Time Spot을 탈퇴하시나요?")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.staticBlack)

      Spacer()
        .frame(height: 12)

      Text("탈퇴 시 주의사항을 확인해주세요")
        .pretendardCustomFont(textStyle: .heading1)
        .foregroundStyle(.gray800)

    }
  }

  @ViewBuilder
  fileprivate func warningContentView() -> some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: 46)

      VStack(spacing: 0) {
        Image(asset: .warningTriangle)
          .resizable()
          .scaledToFit()
          .frame(width: 28, height: 28)

        Spacer()
          .frame(height: 8)

        Text("주의 사항")
          .pretendardCustomFont(textStyle: .bodyBold)
          .foregroundStyle(.gray800)

        Spacer()
          .frame(height: 18)

        warningBulletRow("Time Spot 탈퇴 시 계정에 저장된 정보 및 최근 내역이 삭제됩니다.")

        Spacer()
          .frame(height: 16)

        warningBulletRow("탈퇴 후 삭제된 정보는 다시 복구되지 않습니다.")
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
      .padding(.bottom, 28)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.gray200)
      )
    }
  }

  @ViewBuilder
  fileprivate func warningBulletRow(_ text: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text("•")
        .pretendardCustomFont(textStyle: .body2Medium)
        .foregroundStyle(.gray800)

      Text(text)
        .pretendardCustomFont(textStyle: .body2Medium)
        .foregroundStyle(.gray800)
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)
    }
  }


  @ViewBuilder
  fileprivate func withDrawAgreeButton() -> some View {
    VStack {
      Spacer()
        .frame(height: UIScreen.screenHeight * 0.22)

      HStack {
        Image(asset: store.withdrawButtonTapped ? .check : .noCheck)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)

        Spacer()
          .frame(width: 12)

        Text("주의 사항을 모두 확인했고 이에 동의합니다.")
          .pretendardCustomFont(textStyle: .bodyMedium)
          .foregroundStyle(.staticBlack)

        Spacer()

      }
      .onTapGesture {
        store.send(.view(.tapWithDrawAgree))
      }
    }
  }

  @ViewBuilder
  fileprivate func withDrawButton() -> some View {
    VStack {
      Spacer()
        .frame(height: 25)

      CustomButton(
        action: {
          store.send(.async(.withDraw))
        },
        title: "탈퇴하기",
        config: CustomButtonConfig.create(),
        isEnable: store.withdrawButtonTapped
      )
    }
  }


}
