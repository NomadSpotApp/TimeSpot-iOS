//
//  ExploreView.swift
//  Home
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CoreLocation
import UIKit

import DesignSystem
import Entity

public struct ExploreView: View {
  @Bindable var store: StoreOf<ExploreReducer>
  @Environment(\.dismiss) private var dismiss

  private var cardTravelDistance: CGFloat {
    UIScreen.main.bounds.width - 8
  }

  private var cardSwipeThreshold: CGFloat {
    (UIScreen.main.bounds.width - 32) / 2
  }

  private let cardHeight: CGFloat = 182

  public init(store: StoreOf<ExploreReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      mapView()

      VStack(spacing: 0) {
        headerSection()
          .padding(.top, 8)
          .padding(.horizontal, 20)

        Spacer()

        bottomSection()
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
      locationPermissionStatus: store.locationPermissionStatus,
      currentLocation: store.currentLocation,
      routeInfo: store.routeInfo,
      destination: store.selectedDestination,
      spots: filteredMapSpots,
      selectedSpotID: store.userSession.selectedExploreSpotID.isEmpty
        ? nil
        : store.userSession.selectedExploreSpotID,
      returnToLocationTrigger: store.returnToCurrentLocationTrigger,
      onSpotTapped: { spotID in
        store.send(.view(.spotTapped(spotID)))
      },
      onMapTapped: {
        store.send(.view(.spotCardChanged(nil)))
      }
    )
    .ignoresSafeArea(.all)
  }

  @ViewBuilder
  func headerSection() -> some View {
    ExploreSearchHeaderView(
      stationName: store.userSession.travelStationName,
      searchText: store.searchText,
      selectedCategory: store.selectedCategory,
      onBackTap: { dismiss() },
      onSearchTextChanged: { store.send(.view(.searchTextChanged($0))) },
      onCategoryTap: { store.send(.view(.categoryTapped($0))) }
    )
  }

  @ViewBuilder
  func bottomSection() -> some View {
    let hasSelectedSpotCard = selectedSpot != nil

    ZStack(alignment: .bottom) {
      if let selectedSpot {
        ExploreSelectedSpotCardView(
          currentSpot: selectedSpot,
          adjacentSpot: adjacentSpot,
          currentOffset: store.cardBaseOffset + store.cardDragOffset,
          adjacentOffset: adjacentCardOffset,
          cardOpacity: cardOpacity,
          onCardTap: {
            store.send(.delegate(.presentExplorerDetail))
          },
          onRouteTap: {},
          onDragChanged: { value in
            store.send(.view(.cardDragChanged(value.translation.width)))
          },
          onDragEnded: { value in
            store.send(.view(.cardDragEnded(value.translation.width)))
          }
        )
          .padding(.horizontal, 16)
          .frame(height: cardHeight)
      }

      ExploreFloatingControlsView(
        showsListButton: hasSelectedSpotCard,
        controlsBottomPadding: hasSelectedSpotCard ? cardHeight + 20 : 0,
        onListTap: {
          store.send(.delegate(.presentExploreList))
        },
        onCurrentLocationTap: {
          store.send(.view(.returnToCurrentLocation))
        }
      )
    }
    .padding(.bottom, 36)
  }

  var filteredMapSpots: [ExploreMapSpot] {
    store.state.filteredMapSpots
  }

  var selectedSpot: ExploreMapSpot? {
    store.state.selectedSpot
  }

  var adjacentSpot: ExploreMapSpot? {
    store.state.adjacentSpot(cardTravelDistance: cardTravelDistance)
  }

  var adjacentCardOffset: CGFloat? {
    store.state.adjacentCardOffset(cardTravelDistance: cardTravelDistance)
  }

  var cardOpacity: Double {
    store.state.cardOpacity(cardTravelDistance: cardTravelDistance)
  }
}
