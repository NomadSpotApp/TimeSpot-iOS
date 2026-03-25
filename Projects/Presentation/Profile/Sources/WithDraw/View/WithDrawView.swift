//
//  WithDrawView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

import DesignSystem

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

        
      }
      .padding(.horizontal, 16)
    }
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


}
