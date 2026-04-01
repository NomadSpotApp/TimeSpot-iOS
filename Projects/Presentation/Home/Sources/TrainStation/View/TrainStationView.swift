//
//  TrainStationView.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//

import SwiftUI

import DesignSystem
import Entity

import ComposableArchitecture

public struct TrainStationView: View {
  @Environment(\.modalDismiss) private var modalDismiss
  @Bindable var store: StoreOf<TrainStationFeature>

  public init(
    store: StoreOf<TrainStationFeature>
  ) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if store.isLoading {
        stationSkeletonView()
      } else {
        headerView()
        searchFieldView()

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            if store.shouldShowFavoriteSection {
              stationSectionView(
                title: "즐겨찾기",
                systemIcon: "star.fill",
                assetIcon: nil,
                iconColor: .gray550,
                stations: filteredFavoriteStations
              )
            }

            stationSectionView(
              title: "가까운 역",
              systemIcon: nil,
              assetIcon: .mapSharp,
              iconColor: .gray550,
              stations: filteredNearbyStations
            )

            stationSectionView(
              title: "주요 역",
              systemIcon: nil,
              assetIcon: .subway,
              iconColor: .gray550,
              stations: filteredMajorStations
            )
          }
          .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .scrollIndicators(.hidden)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(.staticWhite)
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}

extension TrainStationView {
  private var filteredFavoriteStations: [StationRowModel] {
    filterRows(Array(store.favoriteRows))
  }

  private var filteredNearbyStations: [StationRowModel] {
    filterRows(Array(store.nearbyRows))
  }

  private var filteredMajorStations: [StationRowModel] {
    filterRows(Array(store.majorRows))
  }

  private func filterRows(_ rows: [StationRowModel]) -> [StationRowModel] {
    let query = normalizedSearchText(store.searchText)

    guard !query.isEmpty else {
      return rows
    }

    return rows.filter {
      normalizedSearchText($0.stationName).localizedCaseInsensitiveContains(query)
      || $0.badges.joined(separator: " ").localizedCaseInsensitiveContains(query)
    }
  }

  private func normalizedSearchText(_ text: String) -> String {
    text
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  @ViewBuilder
  private func headerView() -> some View {
    Text("출발역 선택")
      .pretendardCustomFont(textStyle: .titleBold)
      .foregroundStyle(.gray900)
      .padding(.top, 34)
      .padding(.horizontal, 20)
      .padding(.bottom, 22)
  }

  @ViewBuilder
  private func searchFieldView() -> some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.gray500)

      ZStack(alignment: .leading) {
        if store.searchText.isEmpty {
          Text("역명을 입력해주세요.")
            .pretendardCustomFont(textStyle: .body2Medium)
            .foregroundStyle(.gray700)
        }

        TextField("", text: $store.searchText)
          .pretendardCustomFont(textStyle: .body2Medium)
          .foregroundStyle(.gray900)
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 60)
    .background(.gray200)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .padding(.horizontal, 20)
    .padding(.bottom, 14)
  }

  @ViewBuilder
  private func stationSectionView(
    title: String,
    systemIcon: String?,
    assetIcon: ImageAsset?,
    iconColor: Color,
    stations: [StationRowModel]
  ) -> some View {
    if !stations.isEmpty {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 8) {
          if let assetIcon {
            Image(asset: assetIcon)
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)
            
          } else if let systemIcon {
            Image(systemName: systemIcon)
              .frame(width: 16, height: 16)
              .foregroundStyle(iconColor)
          }

          Text(title)
            .pretendardCustomFont(textStyle: .body2Medium)
            .foregroundStyle(.gray700)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)

        Rectangle()
          .fill(.gray200)
          .frame(height: 1)
          .padding(.leading, 20)
          .padding(.trailing, 24)

        LazyVStack(spacing: 0) {
          ForEach(Array(stations.enumerated()), id: \.element.id) { index, row in
            VStack(spacing: 0) {
              stationRowView(row)

              if title != "주요 역" || index < stations.count - 1 {
                Rectangle()
                  .fill(.gray200)
                  .frame(height: 1)
                  .padding(.leading, 20)
                  .padding(.trailing, 24)
              }
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func stationRowView(_ row: StationRowModel) -> some View {
    HStack(spacing: 12) {
      Button {
        if row.station != nil {
          store.send(.view(.stationTapped(row)))
          modalDismiss()
        }
      } label: {
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .center, spacing: 8) {
            Text(row.stationName)
              .pretendardCustomFont(textStyle: .titleRegular)
              .foregroundStyle(.staticBlack)
              .lineLimit(1)
              .fixedSize(horizontal: true, vertical: false)
              .layoutPriority(2)

            HStack(spacing: 8) {
              ForEach(row.badges, id: \.self) { badge in
                badgeView(badge)
              }
            }
            .layoutPriority(1)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text(row.stationName)
              .pretendardCustomFont(textStyle: .titleRegular)
              .foregroundStyle(.staticBlack)
              .lineLimit(1)

            HStack(spacing: 8) {
              ForEach(row.badges, id: \.self) { badge in
                badgeView(badge)
              }
            }
          }
        }

        Spacer()

        if let distance = row.distanceText {
          Text(distance)
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.gray500)
            .lineLimit(1)
        }
      }
      .buttonStyle(.plain)

      // 비회원이 아닌 경우에만 즐겨찾기 버튼 표시
      if store.shouldShowFavoriteSection {
        Button {
          store.send(.view(.favoriteButtonTapped(row)))
        } label: {
          Image(systemName: row.isFavorite ? "star.fill" : "star")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(row.isFavorite ? .orange800 : .gray550)
            .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.leading, 20)
    .padding(.trailing, 24)
    .padding(.vertical, 18)
  }

  @ViewBuilder
  private func badgeView(_ title: String) -> some View {
    Text(title)
      .pretendardCustomFont(textStyle: .caption)
      .foregroundStyle(.gray700)
      .padding(.horizontal, 6)
      .frame(width: 48, height: 21)
      .background(.gray200)
      .clipShape(Capsule())
  }

  @ViewBuilder
  private func stationSkeletonView() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 44, height: 15)
          .skeletonShimmer()
          .padding(.top, 20)
          .padding(.horizontal, 20)
          .padding(.bottom, 12)

        RoundedRectangle(cornerRadius: 18)
          .fill(.gray200)
          .frame(height: 60)
          .skeletonShimmer()
          .padding(.horizontal, 20)
          .padding(.bottom, 18)

        skeletonSectionHeader()
          .padding(.top, 10)
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: true)
        skeletonDivider()

        skeletonSectionHeader()
          .padding(.top, 10)
        skeletonRow(showDistance: false, badgeCount: 3)
        skeletonDivider()
        skeletonRow(showDistance: false, badgeCount: 3)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
        skeletonDivider()
        skeletonRow(showDistance: false)
      }
      .padding(.bottom, 20)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func skeletonSectionHeader() -> some View {
    HStack(spacing: 8) {
      Circle()
        .fill(.gray200)
        .frame(width: 16, height: 16)
        .skeletonShimmer()

      RoundedRectangle(cornerRadius: 4)
        .fill(.gray200)
        .frame(width: 56, height: 14)
        .skeletonShimmer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .padding(.bottom, 16)
  }

  @ViewBuilder
  private func skeletonRow(
    showDistance: Bool,
    badgeCount: Int = 2
  ) -> some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 40, height: 18)
          .skeletonShimmer()

        HStack(spacing: 8) {
          ForEach(0..<badgeCount, id: \.self) { _ in
            Capsule()
              .fill(.gray200)
              .frame(width: 48, height: 21)
              .skeletonShimmer()
          }
        }
      }

      Spacer()

      if showDistance {
        RoundedRectangle(cornerRadius: 4)
          .fill(.gray200)
          .frame(width: 34, height: 14)
          .skeletonShimmer()
      }

      Circle()
        .fill(.gray200)
        .frame(width: 20, height: 20)
        .skeletonShimmer()
    }
    .padding(.leading, 20)
    .padding(.trailing, 24)
    .padding(.vertical, 18)
  }

  @ViewBuilder
  private func skeletonDivider() -> some View {
    Rectangle()
      .fill(.gray200)
      .frame(height: 1)
      .padding(.leading, 20)
      .padding(.trailing, 24)
  }
}

private extension View {
  func skeletonShimmer() -> some View {
    modifier(TrainStationSkeletonShimmerModifier())
  }
}

private struct TrainStationSkeletonShimmerModifier: ViewModifier {
  @State private var isAnimating = false

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          LinearGradient(
            colors: [
              .white.opacity(0),
              .white.opacity(0.28),
              .white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .frame(width: geometry.size.width * 0.55)
          .offset(x: isAnimating ? geometry.size.width * 1.25 : -geometry.size.width * 0.8)
        }
        .clipped()
      }
      .mask(content)
      .onAppear {
        guard !isAnimating else { return }
        withAnimation(
          .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
          isAnimating = true
        }
      }
  }
}
