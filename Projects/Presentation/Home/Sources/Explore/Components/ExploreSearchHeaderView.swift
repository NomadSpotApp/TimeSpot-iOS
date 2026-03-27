//
//  ExploreSearchHeaderView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity

struct ExploreSearchHeaderView: View {
  let stationName: String
  let searchText: String
  let selectedCategory: ExploreCategory
  let onBackTap: () -> Void
  let onSearchTextChanged: (String) -> Void
  let onCategoryTap: (ExploreCategory) -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        backButton()
        searchBar()
      }

      categoryScrollView()
        .padding(.top, 10)
    }
  }

  @ViewBuilder
  private func backButton() -> some View {
    Button(action: onBackTap) {
      Image(asset: .leftArrow)
        .resizable()
        .scaledToFit()
        .frame(width: 48, height: 48)
        .background(.staticWhite)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func searchBar() -> some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.gray600)

      ZStack(alignment: .leading) {
        if searchText.isEmpty {
          Text("\(stationName)역")
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.gray600)
        }

        TextField(
          "",
          text: Binding(
            get: { searchText },
            set: onSearchTextChanged
          )
        )
        .pretendardCustomFont(textStyle: .titleRegular)
        .foregroundStyle(.staticBlack)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      }
    }
    .padding(.horizontal, 24)
    .frame(height: 48)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
  }

  @ViewBuilder
  private func categoryScrollView() -> some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ExploreCategory.allCases, id: \.self) { category in
            ExploreCategoryChipView(
              category: category,
              isSelected: selectedCategory == category,
              action: { onCategoryTap(category) }
            )
            .id(category)
          }
        }
        .padding(.horizontal, 2)
      }
      .onAppear {
        scrollToCategory(selectedCategory, with: proxy, animated: false)
      }
      .onChange(of: selectedCategory) { _, category in
        DispatchQueue.main.async {
          scrollToCategory(category, with: proxy)
        }
      }
    }
  }

  private func scrollToCategory(
    _ category: ExploreCategory,
    with proxy: ScrollViewProxy,
    animated: Bool = true
  ) {
    let targetCategory: ExploreCategory
    switch category {
    case .all, .cafe:
      targetCategory = .all
    case .restaurant:
      targetCategory = .cafe
    case .activity:
      targetCategory = .restaurant
    case .etc:
      targetCategory = .activity
    }

    let action = {
      proxy.scrollTo(targetCategory, anchor: .leading)
    }

    if animated {
      withAnimation(.easeInOut(duration: 0.2)) {
        action()
      }
    } else {
      action()
    }
  }
}
