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

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        categoryIcon

        Text(category.title)
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
