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
          // 스켈레톤 UI
          skeletonView()
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

  @ViewBuilder
  func skeletonView() -> some View {
    VStack(spacing: 0) {
      // 검색 헤더 스켈레톤
      VStack(spacing: 20) {
        HStack(spacing: 16) {
          // 뒤로가기 버튼
          RoundedRectangle(cornerRadius: 8)
            .fill(.gray200)
            .frame(width: 40, height: 40)

          // 검색바
          RoundedRectangle(cornerRadius: 20)
            .fill(.gray200)
            .frame(height: 44)
        }

        // 카테고리 필터 스켈레톤 - 2줄로 배치
        VStack(spacing: 12) {
          HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
              Capsule()
                .fill(.gray200)
                .frame(width: CGFloat([80, 60, 70, 90][index]), height: 36)
            }
            Spacer()
          }

          HStack {
            Capsule()
              .fill(.gray200)
              .frame(width: 100, height: 36)
            Spacer()
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)

      // 정렬 옵션 스켈레톤
      HStack {
        Spacer()
        RoundedRectangle(cornerRadius: 6)
          .fill(.gray200)
          .frame(width: 100, height: 24)
      }
      .padding(.top, 24)
      .padding(.horizontal, 20)

      // 리스트 스켈레톤
      ScrollView(showsIndicators: false) {
        LazyVStack(spacing: 16) {
          ForEach(0..<5, id: \.self) { _ in
            skeletonListItem()
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
      }
      .background(.gray100)
    }
  }

  @ViewBuilder
  func skeletonListItem() -> some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(.staticWhite)
      .frame(height: 140)
      .overlay {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 12) {
            // 상단 배지
            RoundedRectangle(cornerRadius: 10)
              .fill(.gray200)
              .frame(width: 60, height: 20)

            // 제목
            RoundedRectangle(cornerRadius: 6)
              .fill(.gray200)
              .frame(height: 18)
              .frame(maxWidth: .infinity, alignment: .leading)

            // 부제목 라인들
            VStack(alignment: .leading, spacing: 6) {
              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 140, height: 14)

              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 100, height: 14)
            }

            Spacer()

            // 하단 정보
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 50, height: 12)

              RoundedRectangle(cornerRadius: 4)
                .fill(.gray200)
                .frame(width: 80, height: 12)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          // 이미지 영역
          RoundedRectangle(cornerRadius: 12)
            .fill(.gray200)
            .frame(width: 100, height: 100)
        }
        .padding(16)
      }
  }
}
