//
//  ExploreDetailView.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//


import SwiftUI
import DesignSystem

import ComposableArchitecture

public struct ExploreDetailView: View {
  @Bindable var store: StoreOf<ExploreDetailFeature>
  @Environment(\.dismiss) private var dismiss

  public init(
    store: StoreOf<ExploreDetailFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray100
        .edgesIgnoringSafeArea(.all)

      VStack {
        Spacer()
          .frame(height: 8)

        CustomNavigationBackBar(buttonAction: {
          dismiss()
        }, title: "")


        exploreSpotNameTitle()

        Spacer()
      }
    }
  }
}


private extension ExploreDetailView {

  @ViewBuilder
  func exploreSpotNameTitle() -> some View {
    VStack(alignment: .leading) {
      Spacer()
        .frame(height: 24)

      HStack(spacing: 8) {
        Text("시티뷰 전망대")
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.staticBlack)

        Text("관광지")
          .pretendardCustomFont(textStyle: .body2Regular)
          .foregroundStyle(.gray700)
      }
    }
  }

}
