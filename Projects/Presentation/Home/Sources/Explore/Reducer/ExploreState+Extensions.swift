//
//  ExploreState+Extensions.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import CoreLocation
import ComposableArchitecture
import Entity

extension ExploreFeature.State {
  var trimmedSearchText: String {
    place.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func hasVisibleMarkerContent(_ spot: ExploreMapSpot) -> Bool {
    spot.hasDetail
      || !spot.name.isEmpty
      || !spot.badgeText.isEmpty
      || !spot.statusText.isEmpty
      || !spot.closingText.isEmpty
      || !spot.distanceText.isEmpty
      || !spot.walkTimeText.isEmpty
  }

  func matchesCurrentFilters(_ spot: ExploreMapSpot) -> Bool {
    let matchesCategory = place.selectedCategory == .all || spot.category == place.selectedCategory
    let matchesQuery = trimmedSearchText.isEmpty || spot.name.localizedCaseInsensitiveContains(trimmedSearchText)
    return matchesCategory && matchesQuery
  }

  // 필터링된 스팟들 (중복 로직 제거)
  var filteredSpots: [ExploreMapSpot] {
    place.spots.filter { spot in
      spot.hasDetail && matchesCurrentFilters(spot)
    }
  }

  // 호환성을 위한 별칭 (기존 코드 유지)
  var filteredMapSpots: [ExploreMapSpot] {
    filteredSpots
  }

  func mergedSpot(for spotID: String) -> ExploreMapSpot? {
    place.spots.first(where: { $0.id == spotID && $0.hasDetail })
  }

  var cardSpots: [ExploreMapSpot] {
    let selectedSpotID = userSession.selectedExploreSpotID

    guard !selectedSpotID.isEmpty else {
      return filteredSpots
    }

    if filteredSpots.contains(where: { $0.id == selectedSpotID }) {
      return filteredSpots
    }

    if let selectedSearchSpot = mergedSpot(for: selectedSpotID) {
      return [selectedSearchSpot] + filteredSpots
    }

    return filteredSpots
  }

  var selectedSpot: ExploreMapSpot? {
    guard mapUI.isSpotCardVisible else { return nil }

    let selectedSpotID = userSession.selectedExploreSpotID

    if !selectedSpotID.isEmpty,
       let selectedSpot = mergedSpot(for: selectedSpotID) {
      return selectedSpot
    }

    return nil
  }

  func adjacentSpot(cardTravelDistance: CGFloat) -> ExploreMapSpot? {
    let currentSelectedID = selectedSpot?.id ?? userSession.selectedExploreSpotID
    guard let currentIndex = cardSpots.firstIndex(where: { $0.id == currentSelectedID }) else {
      return nil
    }
    guard abs(mapUI.cardDragOffset) > 0 else {
      return nil
    }

    let adjacentIndex: Int
    if mapUI.cardDragOffset < 0 {
      adjacentIndex = (currentIndex + 1) % cardSpots.count
    } else {
      adjacentIndex = (currentIndex - 1 + cardSpots.count) % cardSpots.count
    }
    return cardSpots[adjacentIndex]
  }

  func adjacentCardOffset(cardTravelDistance: CGFloat) -> CGFloat? {
    guard adjacentSpot(cardTravelDistance: cardTravelDistance) != nil else { return nil }
    let baseOffset = mapUI.cardDragOffset >= 0 ? -cardTravelDistance : cardTravelDistance
    return baseOffset + mapUI.cardDragOffset
  }

  func cardOpacity(cardTravelDistance: CGFloat) -> Double {
    let progress = min(abs(mapUI.cardBaseOffset + mapUI.cardDragOffset) / cardTravelDistance, 1)
    return 1 - (progress * 0.02)
  }
}


// MARK: - ExploreReducer.AsyncAction + Equatable

extension ExploreFeature.AsyncAction {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.requestLocationPermission, .requestLocationPermission),
         (.requestFullAccuracy, .requestFullAccuracy),
         (.startLocationUpdates, .startLocationUpdates),
         (.stopLocationUpdates, .stopLocationUpdates),
         (.requestCurrentLocation, .requestCurrentLocation):
      return true
    case (.fetchPlaces(let lhsPage, let lhsAppend), .fetchPlaces(let rhsPage, let rhsAppend)):
      return lhsPage == rhsPage && lhsAppend == rhsAppend
    default:
      return false
    }
  }
}
