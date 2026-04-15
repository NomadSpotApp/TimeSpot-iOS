//
//  ExploreView.swift
//  Home
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CoreLocation
import UIKit

import DesignSystem
import Entity
import LogMacro

public struct ExploreView: View {
  @Bindable var store: StoreOf<ExploreFeature>
  @Environment(\.dismiss) private var dismiss

  // ✅ PFW Pattern: GeometryReader 기반 반응형 레이아웃
  private func cardTravelDistance(geometry: GeometryProxy) -> CGFloat {
    geometry.size.width - 8
  }

  private func cardSwipeThreshold(geometry: GeometryProxy) -> CGFloat {
    (geometry.size.width - 32) / 2
  }

  public init(store: StoreOf<ExploreFeature>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { geometry in
      ZStack {
        mapView()

        // 🦴 마커 로딩 중일 때는 스켈레톤 전체 화면으로 표시
        if store.place.isLoading && store.place.spots.isEmpty {
          ExploreSkeletonView()
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: store.place.isLoading && store.place.spots.isEmpty)
        } else {
          // ✅ 마커 로딩 완료 후 실제 UI 표시
          VStack(spacing: 0) {
            headerSection()
              .padding(.top, 8)
              .padding(.horizontal, 16)

            Spacer()

            bottomSection(geometry: geometry)
          }
          .transition(.scale.combined(with: .opacity))
          .animation(.easeInOut(duration: 0.3), value: !(store.place.isLoading && store.place.spots.isEmpty))
        }
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .onDisappear {
      store.send(.view(.onDisappear))
    }
    .alert($store.scope(state: \.alert, action: \.scope.alert))
  }
}

private extension ExploreView {
  @ViewBuilder
  func mapView() -> some View {
    NaverMapComponent(
      locationPermissionStatus: store.location.permissionStatus,
      currentLocation: store.location.currentLocation,
      routeInfo: nil,
      destination: store.route.selectedDestination,
      travelStation: nil,
      spots: store.filteredMapSpots,
      selectedSpotID: store.userSession.selectedExploreSpotID.isEmpty
        ? nil
        : store.userSession.selectedExploreSpotID,
      returnToLocationTrigger: store.mapUI.returnToCurrentLocationTrigger,
      autoFitTrigger: 0, // ExploreView에서는 자동 피팅 사용하지 않음
      onSpotTapped: { spotID in
        store.send(.view(.spotTapped(spotID)))
      },
      onMapTapped: {
        store.send(.view(.spotCardChanged(nil)))
      },
      onCameraIdle: nil
    )
    .ignoresSafeArea(.all)
  }

  @ViewBuilder
  func headerSection() -> some View {
    ExploreSearchHeaderView(
      stationName: "\(store.userSession.travelStationName)역",
      searchText: store.place.searchText,
      selectedCategory: store.place.selectedCategory,
      showCategories: true,   // 카테고리 표시
      isSearchable: false,    // 검색창 아닌 텍스트로 표시
      onBackTap: { dismiss() },
      onSearchTextChanged: { store.send(.view(.searchTextChanged($0))) },
      onCategoryTap: { store.send(.view(.categoryTapped($0))) },
      onSearchBarTap: nil
    )
  }

  @ViewBuilder
  func bottomSection(geometry: GeometryProxy) -> some View {
    let selectedSpot = store.state.selectedSpot
    let hasSelectedSpotCard = selectedSpot != nil
    let travelDistance = cardTravelDistance(geometry: geometry)

    VStack(spacing: 16) {
      ExploreFloatingControlsView(
        showsListButton: hasSelectedSpotCard,
        controlsBottomPadding: 0,
        onListTap: {
          store.send(.delegate(.presentExploreList))
        },
        onCurrentLocationTap: {
          store.send(.view(.returnToCurrentLocation))
        }
      )

      if let selectedSpot {
        ExploreSelectedSpotCardView(
          currentSpot: selectedSpot,
          adjacentSpot: store.state.adjacentSpot(cardTravelDistance: travelDistance),
          store: store,
          currentOffset: store.mapUI.cardBaseOffset + store.mapUI.cardDragOffset,
          adjacentOffset: store.state.adjacentCardOffset(cardTravelDistance: travelDistance),
          cardOpacity: store.state.cardOpacity(cardTravelDistance: travelDistance),
          onCardTap: {
            store.send(.view(.detailTapped))
          },
          onRouteTap: {
            store.send(.delegate(.presentRoute))
          },
          onDragChanged: { value in
            store.send(.view(.cardDragChanged(value.translation.width)))
          },
          onDragEnded: { value in
            store.send(.view(.cardDragEnded(value.translation.width)))
          }
        )
        .padding(.horizontal, 16)
      }
    }
    .padding(.bottom, 36)
  }
}
