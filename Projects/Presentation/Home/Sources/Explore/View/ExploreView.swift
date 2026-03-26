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
  @State private var cardDragOffset: CGFloat = 0
  @State private var cardBaseOffset: CGFloat = 0
  @State private var isCardTransitioning = false

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
      spots: filteredSpots,
      selectedSpotID: store.userSession.selectedExploreSpotID.isEmpty
        ? nil
        : store.userSession.selectedExploreSpotID,
      returnToLocation: store.shouldReturnToCurrentLocation,
      onSpotTapped: { spotID in
        store.send(.view(.spotTapped(spotID)))
      },
      onMapTapped: {
        store.send(.view(.spotCardChanged(nil)))
      }
    )
    .ignoresSafeArea(.all)
  }

  var filteredSpots: [ExploreMapSpot] {
    let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    return store.spots.filter { spot in
      let matchesCategory = store.selectedCategory == .all || spot.category == store.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return matchesCategory && matchesQuery
    }
  }

  var selectedSpot: ExploreMapSpot? {
    guard store.isSpotCardVisible else { return nil }

    let selectedSpotID = store.userSession.selectedExploreSpotID

    if !selectedSpotID.isEmpty,
       let selectedSpot = filteredSpots.first(where: { $0.id == selectedSpotID }) {
      return selectedSpot
    }

    return nil
  }

  @ViewBuilder
  func headerSection() -> some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        backButton()
        searchBar()
      }

      categoryScrollView()
        .padding(.top, 12)
    }
  }

  @ViewBuilder
  func backButton() -> some View {
    Button {
      dismiss()
    } label: {
      Image(asset: .leftArrow)
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)
        .background(.staticWhite)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func searchBar() -> some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.gray600)

      ZStack(alignment: .leading) {
        if store.searchText.isEmpty {
          Text("\(store.userSession.travelStationName)역")
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.gray600)
        }

        TextField(
          "",
          text: Binding(
            get: { store.searchText },
            set: { store.send(.view(.searchTextChanged($0))) }
          )
        )
        .pretendardCustomFont(textStyle: .titleRegular)
        .foregroundStyle(.staticBlack)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      }
    }
    .padding(.horizontal, 24)
    .frame(height: 56)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
  }

  @ViewBuilder
  func categoryScrollView() -> some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ExploreCategory.allCases, id: \.self) { category in
            categoryChip(category)
            .id(category)
          }
        }
        .padding(.horizontal, 2)
      }
      .onAppear {
        scrollToCategory(store.selectedCategory, with: proxy, animated: false)
      }
      .onChange(of: store.selectedCategory) { _, category in
        DispatchQueue.main.async {
          scrollToCategory(category, with: proxy)
        }
      }
    }
  }

  @ViewBuilder
  func categoryChip(_ category: ExploreCategory) -> some View {
    ExploreCategoryChipView(
      category: category,
      isSelected: store.selectedCategory == category,
      action: {
        store.send(.view(.categoryTapped(category)))
      }
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
          currentOffset: cardBaseOffset + cardDragOffset,
          adjacentOffset: adjacentCardOffset,
          cardOpacity: cardOpacity,
          onRouteTap: {},
          onDragChanged: handleCardDragChanged,
          onDragEnded: handleCardDragEnded
        )
          .padding(.horizontal, 16)
          .frame(height: cardHeight)
      }

      ExploreFloatingControlsView(
        showsListButton: hasSelectedSpotCard,
        controlsBottomPadding: hasSelectedSpotCard ? cardHeight + 20 : 0,
        onListTap: {},
        onCurrentLocationTap: {
          store.send(.view(.returnToCurrentLocation))
        }
      )
    }
    .padding(.bottom, 36)
  }

  func moveSelectedSpot(next: Bool) {
    guard !filteredSpots.isEmpty else { return }
    guard !isCardTransitioning else { return }

    let currentIndex = filteredSpots.firstIndex(where: { $0.id == store.userSession.selectedExploreSpotID }) ?? 0
    let newIndex: Int
    let entryOffset: CGFloat = next ? -cardTravelDistance : cardTravelDistance

    if next {
      newIndex = (currentIndex + 1) % filteredSpots.count
    } else {
      newIndex = (currentIndex - 1 + filteredSpots.count) % filteredSpots.count
    }

    isCardTransitioning = true

    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.9)) {
      cardDragOffset = next ? cardTravelDistance : -cardTravelDistance
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = store.send(.view(.spotCardChanged(filteredSpots[newIndex].id)))
      cardBaseOffset = entryOffset
      cardDragOffset = 0

      withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.88)) {
        cardBaseOffset = 0
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
        isCardTransitioning = false
      }
    }
  }

  func handleCardDragChanged(_ value: DragGesture.Value) {
    guard !isCardTransitioning else { return }
    let limitedOffset = max(min(value.translation.width, cardTravelDistance), -cardTravelDistance)
    cardDragOffset = limitedOffset
  }

  func handleCardDragEnded(_ value: DragGesture.Value) {
    guard !isCardTransitioning else { return }

    if value.translation.width > cardSwipeThreshold {
      moveSelectedSpot(next: true)
      return
    }

    if value.translation.width < -cardSwipeThreshold {
      moveSelectedSpot(next: false)
      return
    }

    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.88)) {
      cardDragOffset = 0
    }
  }

  var adjacentSpot: ExploreMapSpot? {
    guard let currentIndex = filteredSpots.firstIndex(where: { $0.id == store.userSession.selectedExploreSpotID }) else {
      return nil
    }
    guard abs(cardDragOffset) > 0 else {
      return nil
    }

    let adjacentIndex: Int
    if cardDragOffset >= 0 {
      adjacentIndex = (currentIndex + 1) % filteredSpots.count
    } else {
      adjacentIndex = (currentIndex - 1 + filteredSpots.count) % filteredSpots.count
    }
    return filteredSpots[adjacentIndex]
  }

  var adjacentCardOffset: CGFloat? {
    guard adjacentSpot != nil else { return nil }
    let baseOffset = cardDragOffset >= 0 ? -cardTravelDistance : cardTravelDistance
    return baseOffset + cardDragOffset
  }

  var cardOpacity: Double {
    let progress = min(abs(cardBaseOffset + cardDragOffset) / cardTravelDistance, 1)
    return 1 - (progress * 0.02)
  }

  func scrollToCategory(
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
    @unknown default:
      targetCategory = .all
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
