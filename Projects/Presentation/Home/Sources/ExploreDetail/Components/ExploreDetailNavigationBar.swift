//
//  ExploreDetailNavigationBar.swift
//  Home
//
//  Created by Wonji Suh  on 4/1/26.
//

import SwiftUI
import DesignSystem

public struct ExploreDetailNavigationBar: View {
  private let placeName: String
  private let category: String
  private let showTitle: Bool
  private let onBackTap: () -> Void

  public init(
    placeName: String,
    category: String,
    showTitle: Bool,
    onBackTap: @escaping () -> Void
  ) {
    self.placeName = placeName
    self.category = category
    self.showTitle = showTitle
    self.onBackTap = onBackTap
  }

 public var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // 뒤로가기 버튼
      Button(action: onBackTap) {
        Image(asset: .leftArrow)
          .frame(width: 48, height: 48)
          .background(.staticWhite)
      }

      // 제목 영역
      if showTitle {
        HStack(spacing: 12) {
          // 장소명 - 7자 이상이면 ... 처리
          Text(placeName.count > 7 ? String(placeName.prefix(7)) + "..." : placeName)
            .pretendardCustomFont(textStyle: .heading1)
            .foregroundStyle(.staticBlack)
            .lineLimit(1)

          // 카테고리 - 그대로 표시
          Text(category)
            .pretendardCustomFont(textStyle: .body2Regular)
            .foregroundStyle(.gray700)
            .lineLimit(1)

          Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else {
        Spacer()
      }
    }
    .frame(minHeight: 48)
    .animation(.easeInOut(duration: 0.3), value: showTitle)
  }
}
