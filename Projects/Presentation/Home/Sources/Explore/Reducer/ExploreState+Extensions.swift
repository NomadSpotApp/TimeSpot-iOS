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
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
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
    let matchesCategory = selectedCategory == .all || spot.category == selectedCategory
    let matchesQuery = trimmedSearchText.isEmpty || spot.name.localizedCaseInsensitiveContains(trimmedSearchText)
    return matchesCategory && matchesQuery
  }

  var filteredMapSpots: [ExploreMapSpot] {
    spots.filter { spot in
      spot.hasDetail && matchesCurrentFilters(spot)
    }
  }

  var filteredSpots: [ExploreMapSpot] {
    spots.filter { spot in
      spot.hasDetail && matchesCurrentFilters(spot)
    }
  }

  func mergedSpot(for spotID: String) -> ExploreMapSpot? {
    spots.first(where: { $0.id == spotID && $0.hasDetail })
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
    guard isSpotCardVisible else { return nil }

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
    guard abs(cardDragOffset) > 0 else {
      return nil
    }

    let adjacentIndex: Int
    if cardDragOffset < 0 {
      adjacentIndex = (currentIndex + 1) % cardSpots.count
    } else {
      adjacentIndex = (currentIndex - 1 + cardSpots.count) % cardSpots.count
    }
    return cardSpots[adjacentIndex]
  }

  func adjacentCardOffset(cardTravelDistance: CGFloat) -> CGFloat? {
    guard adjacentSpot(cardTravelDistance: cardTravelDistance) != nil else { return nil }
    let baseOffset = cardDragOffset >= 0 ? -cardTravelDistance : cardTravelDistance
    return baseOffset + cardDragOffset
  }

  func cardOpacity(cardTravelDistance: CGFloat) -> Double {
    let progress = min(abs(cardBaseOffset + cardDragOffset) / cardTravelDistance, 1)
    return 1 - (progress * 0.02)
  }
}

// MARK: - ExploreReducer.State + Hashable

extension ExploreFeature.State: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(locationPermissionStatus)
    hasher.combine(currentLocation?.coordinate.latitude)
    hasher.combine(currentLocation?.coordinate.longitude)
    hasher.combine(isLocationPermissionDenied)
    hasher.combine(locationError)
    hasher.combine(mapCenterLat)
    hasher.combine(mapCenterLon)
    hasher.combine(spots)
    hasher.combine(isLoadingRoute)
    hasher.combine(routeError)
    hasher.combine(shouldReturnToCurrentLocation)
    hasher.combine(userSession)
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
