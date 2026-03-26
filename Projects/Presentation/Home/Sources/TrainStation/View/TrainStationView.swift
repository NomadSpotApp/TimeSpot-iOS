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
      .scrollIndicators(.hidden)
    }
    .background(.staticWhite)
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}

extension TrainStationView {
  private var filteredFavoriteStations: [StationRowModel] {
    filterRows(favoriteStations)
  }

  private var filteredNearbyStations: [StationRowModel] {
    filterRows(nearbyStations)
  }

  private var filteredMajorStations: [StationRowModel] {
    filterRows(majorStations)
  }

  private func filterRows(_ rows: [StationRowModel]) -> [StationRowModel] {
    guard !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return rows
    }

    return rows.filter {
      $0.station.displayName.localizedCaseInsensitiveContains(store.searchText)
      || $0.badges.joined(separator: " ").localizedCaseInsensitiveContains(store.searchText)
    }
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
    Button {
      store.send(.view(.stationTapped(row.station)))
      modalDismiss()
    } label: {
      HStack(spacing: 12) {
        HStack(spacing: 8) {
          Text(row.station.displayName)
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.staticBlack)

          HStack(spacing: 8) {
            ForEach(row.badges, id: \.self) { badge in
              badgeView(badge)
            }
          }
        }

        Spacer()

        if let distance = row.distanceText {
          Text(distance)
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.gray500)
        }

        Image(systemName: row.isFavorite ? "star.fill" : "star")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(row.isFavorite ? .orange700 : .gray550)
          .frame(width: 20, height: 20)
      }
      .padding(.leading, 20)
      .padding(.trailing, 24)
      .padding(.vertical, 18)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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
}

private extension TrainStationView {
  var favoriteStations: [StationRowModel] {
    [
      .init(id: "favorite-dongdaegu-1", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: true),
      .init(id: "favorite-dongdaegu-2", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: true)
    ]
  }

  var nearbyStations: [StationRowModel] {
    [
      .init(id: "nearby-dongdaegu-1", station: Station.dongdaegu, badges: ["경부선"], distanceText: "2.3km", isFavorite: false),
      .init(id: "nearby-dongdaegu-2", station: Station.dongdaegu, badges: ["경부선"], distanceText: "2.3km", isFavorite: false)
    ]
  }

  var majorStations: [StationRowModel] {
    [
      .init(id: "major-dongdaegu-1", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-2", station: Station.dongdaegu, badges: ["경부선", "경전선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-3", station: Station.dongdaegu, badges: ["경부선", "강릉선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-4", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-5", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-6", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-7", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-8", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-9", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-10", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false),
      .init(id: "major-dongdaegu-11", station: Station.dongdaegu, badges: ["경부선"], distanceText: nil, isFavorite: false)
    ]
  }
}
