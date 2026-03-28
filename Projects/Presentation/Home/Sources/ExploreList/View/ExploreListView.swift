//
//  ExploreListView.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import SwiftUI
import DesignSystem
import Entity

import ComposableArchitecture

public struct ExploreListView: View {
  @Bindable var store: StoreOf<ExploreListFeature>
  @Environment(\.dismiss) private var dismiss

  public init(
    store: StoreOf<ExploreListFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      VStack(spacing: 0) {
        if store.isLoading && store.spots.isEmpty {
          ExploreListSkeletonView()
        } else {
          ExploreSearchHeaderView(
            stationName: store.userSession.travelStationName,
            searchText: store.searchText,
            selectedCategory: store.selectedCategory,
            onBackTap: { dismiss() },
            onSearchTextChanged: { store.send(.view(.searchTextChanged($0))) },
            onCategoryTap: { store.send(.view(.categoryTapped($0))) }
          )
          .padding(.top, 8)
          .padding(.horizontal, 16)
          .background(.staticWhite)

          sortSection()
            .padding(.top, 28)
            .padding(.horizontal, 16)
            .background(.staticWhite)

          ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
              ForEach(filteredSpots) { spot in
                ExploreSpotListCardView(spot: spot)
                  .onAppear {
                    guard shouldShowLoadMore else { return }
                    guard spot.id == filteredSpots.last?.id else { return }
                    store.send(.view(.loadNextPage))
                  }
              }

              if store.isLoading {
                ProgressView()
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 16)
              }

              // 플로팅 버튼 공간
              Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
          }
          .background(.gray100)
        }
      }

      // 플로팅 지도보기 버튼
      VStack {
        Spacer()
        floatingMapButton()
      }
    }
    .background(.staticWhite)
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}

private extension ExploreListView {
  var isFilteringLocally: Bool {
    !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || store.selectedCategory != .all
  }

  var shouldShowLoadMore: Bool {
    !isFilteringLocally && (store.spots.count < store.bufferedSpots.count || store.hasNextPage)
  }

  var filteredSpots: [ExploreMapSpot] {
    let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    let sourceSpots = isFilteringLocally ? store.bufferedSpots : store.spots

    return sourceSpots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = store.selectedCategory == .all || spot.category == store.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }
  }

  @ViewBuilder
  func sortSection() -> some View {
    HStack(spacing: 0) {
      Spacer(minLength: 16)

      Menu {
        ForEach(ExploreListSort.allCases, id: \.self) { sort in
          Button {
            store.send(.view(.sortTapped(sort)))
          } label: {
            HStack(spacing: 8) {
              if store.selectedSort == sort {
                Image(asset: .rowCheck)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 12, height: 12)
              }

              Text(sort.title)
                .pretendardCustomFont(textStyle: .bodyMedium)
                .foregroundStyle(.gray800)
            }
            .environment(\.layoutDirection, .leftToRight)
          }
        }
      } label: {
        HStack(spacing: 8) {
          Text(store.selectedSort.title)
            .pretendardCustomFont(textStyle: .bodyMedium)
            .foregroundStyle(.gray700)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .truncationMode(.tail)
            .frame(maxWidth: 200, alignment: .trailing)

          Image(asset: .arrowtriangleDown)
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
      }
    }
  }

  @ViewBuilder
  func floatingMapButton() -> some View {
    Button {
      store.send(.delegate(.presentExploreMapAtCurrentLocation))
    } label: {
      HStack(alignment: .center, spacing: 4) {
        Image(asset: .locationBadge)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)

        Text("지도보기")
          .pretendardCustomFont(textStyle: .body2Bold)
          .foregroundStyle(.staticWhite)
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 10)
      .background(.orange800)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
      .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
    }
    .padding(.bottom, 40)
  }
}
