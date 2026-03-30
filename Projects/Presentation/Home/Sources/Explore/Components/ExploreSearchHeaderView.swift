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
  let showCategories: Bool
  let isSearchable: Bool // 검색 가능 여부
  let onBackTap: () -> Void
  let onSearchTextChanged: ((String) -> Void)?
  let onCategoryTap: ((ExploreCategory) -> Void)?
  let onSearchBarTap: (() -> Void)?

  init(
    stationName: String,
    searchText: String = "",
    selectedCategory: ExploreCategory = .all,
    showCategories: Bool = false,
    isSearchable: Bool = false,
    onBackTap: @escaping () -> Void,
    onSearchTextChanged: ((String) -> Void)? = nil,
    onCategoryTap: ((ExploreCategory) -> Void)? = nil,
    onSearchBarTap: (() -> Void)? = nil
  ) {
    self.stationName = stationName
    self.searchText = searchText
    self.selectedCategory = selectedCategory
    self.showCategories = showCategories
    self.isSearchable = isSearchable
    self.onBackTap = onBackTap
    self.onSearchTextChanged = onSearchTextChanged
    self.onCategoryTap = onCategoryTap
    self.onSearchBarTap = onSearchBarTap
  }

  /// 10자 이상인 텍스트에 중간 스페이스 추가
  private func formatLongText(_ text: String) -> String {
    guard text.count > 10 else { return text }

    let characters = Array(text)
    let midPoint = characters.count / 2

    // 중간점 근처에서 적절한 위치 찾기 (±2 범위 내)
    let searchRange = max(0, midPoint - 2)...min(characters.count - 1, midPoint + 2)

    // 이미 스페이스가 있는 위치 찾기
    if let spaceIndex = searchRange.first(where: { characters[$0] == " " }) {
      return text
    }

    // 스페이스가 없으면 중간에 스페이스 추가
    let insertIndex = midPoint
    var result = characters
    result.insert(" ", at: insertIndex)

    return String(result)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        backButton()
        searchBar()
      }

      if showCategories {
        categoryScrollView()
          .padding(.top, 10)
      }
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
    if isSearchable {
      // 검색 가능한 TextField 형태
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.gray600)

        ZStack(alignment: .leading) {
          if searchText.isEmpty {
            Text("\(formatLongText(stationName))역")
              .pretendardCustomFont(textStyle: .titleRegular)
              .foregroundStyle(.gray600)
          }

          TextField(
            "",
            text: Binding(
              get: { searchText },
              set: { newValue in
                onSearchTextChanged?(newValue)
              }
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
      .clipShape(RoundedRectangle(cornerRadius: 28))
      .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    } else {
      HStack {
        Text("\(formatLongText(stationName))역")
          .pretendardFont(family: .Medium, size: 18)
          .foregroundStyle(.staticBlack)

        Spacer()
      }
      .padding(.horizontal, 24)
      .frame(height: 48)
      .background(.staticWhite)
      .clipShape(RoundedRectangle(cornerRadius: 28))
      .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
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
              action: { onCategoryTap?(category) }
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
    case .shopping:
      targetCategory = .restaurant
    case .activity:
      targetCategory = .shopping
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
