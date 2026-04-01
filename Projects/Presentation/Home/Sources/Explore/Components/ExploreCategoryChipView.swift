//
//  ExploreCategoryChipView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity

struct ExploreCategoryChipView: View {
  let category: ExploreCategory
  let isSelected: Bool
  let action: () -> Void

  /// 10자 이상인 텍스트에 중간 스페이스 추가
  private func formatLongText(_ text: String) -> String {
    guard text.count > 10 else { return text }

    let characters = Array(text)
    let midPoint = characters.count / 2

    // 중간점 근처에서 적절한 위치 찾기 (±2 범위 내)
    let searchRange = max(0, midPoint - 2)...min(characters.count - 1, midPoint + 2)

    // 이미 스페이스가 있는 위치 찾기
    if searchRange.first(where: { characters[$0] == " " }) != nil {
      return text
    }

    // 스페이스가 없으면 중간에 스페이스 추가
    let insertIndex = midPoint
    var result = characters
    result.insert(" ", at: insertIndex)

    return String(result)
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        categoryIcon

        Text(formatLongText(category.title))
          .pretendardCustomFont(textStyle: .body2Medium)
          .foregroundStyle(isSelected ? .staticBlack : .gray700)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 16)
      .background(isSelected ? .orange200 : .staticWhite)
      .overlay {
        Capsule()
          .stroke(isSelected ? .orange800 : .gray300, lineWidth: 1)
      }
      .clipShape(Capsule())
      .shadow(color: .black.opacity(isSelected ? 0.04 : 0.08), radius: 8, y: 2)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var categoryIcon: some View {
    switch category {
    case .all:
      Image(asset: isSelected ? .tapAll : .all)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    case .cafe:
      Image(asset: isSelected ? .tapCaffe : .cafe)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    case .shopping:
      Image(asset: isSelected ? .tapShopping : .shopping)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      case .restaurant:
        Image(asset: isSelected ? .tapFood : .food)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
    case .activity:
      Image(asset: isSelected ? .tapGame : .game)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    case .etc:
      Image(asset: isSelected ? .tapEtc : .etc)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
    }
  }
}
