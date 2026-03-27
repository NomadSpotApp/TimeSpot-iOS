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
      Color.staticWhite
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
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

        sortSection()
          .padding(.top, 28)
          .padding(.horizontal, 20)

        ScrollView(showsIndicators: false) {
          LazyVStack(spacing: 12) {
            ForEach(filteredSpots) { spot in
              ExploreSpotListCardView(spot: spot)
              .onAppear {
                guard spot.id == filteredSpots.last?.id else { return }
                store.send(.view(.loadNextPage))
              }
            }

            if store.isLoading {
              ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 12)
          .padding(.bottom, 28)
        }
        .background(.gray100)
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}

private extension ExploreListView {
  var filteredSpots: [ExploreMapSpot] {
    let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    return store.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = store.selectedCategory == .all || spot.category == store.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }
  }

  @ViewBuilder
  func sortSection() -> some View {
    HStack {
      Spacer()

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
                  .frame(width: 24, height: 24)
              }

              Text(sort.title)
                .pretendardCustomFont(textStyle: .bodyMedium)
                .foregroundStyle(.gray800)
            }
            .environment(\.layoutDirection, .leftToRight)
          }
        }
      } label: {
        HStack(spacing: 4) {
          Text(store.selectedSort.title)
            .pretendardCustomFont(textStyle: .bodyMedium)
            .foregroundStyle(.gray700)

          Image(asset: .arrowtriangleDown)
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
      }
    }
  }
}
