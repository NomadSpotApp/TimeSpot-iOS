//
//  ExploreHelpers.swift
//  Home
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import CoreLocation
import Entity

// MARK: - ExploreHelpers

public struct ExploreHelpers {

  // MARK: - State Management

  public static func resetPagination(state: inout ExploreReducer.State) {
    state.currentPage = 0
    state.hasNextPage = true
    state.pendingSelectFirstSpotFromNextPage = false
  }

  public static func resetSearchContext(
    state: inout ExploreReducer.State,
    clearMarker: Bool = true,
    preserveSearchText: Bool = false,
    preserveSelectedCategory: Bool = false
  ) {
    if !preserveSearchText {
      state.searchText = ""
    }
    if !preserveSelectedCategory {
      state.selectedCategory = .all
    }
    state.isLoadingPlaces = false
    state.hasRequestedPlaces = false
    resetPagination(state: &state)
    if clearMarker {
      state.searchMarkerLat = nil
      state.searchMarkerLon = nil
    }
  }

  public static func clearSelectedSpot(state: inout ExploreReducer.State) {
    state.isSpotCardVisible = false
    state.cardDragOffset = 0
    state.cardBaseOffset = 0
    state.isCardTransitioning = false

    state.$userSession.withLock {
      $0.selectedExploreSpotID = ""
    }
  }

  // MARK: - Data Calculations

  public static func currentKeyword(state: ExploreReducer.State) -> String {
    return state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public static func currentCategory(state: ExploreReducer.State) -> ExploreCategory? {
    return state.selectedCategory == .all ? nil : state.selectedCategory
  }

  public static func isSameCoordinate(_ lhs: Double?, _ rhs: Double?, tolerance: Double = 0.000001) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
      return lhs == nil && rhs == nil
    }

    return abs(lhs - rhs) < tolerance
  }

  public static func isResolvingSelectedMarkerDetail(state: ExploreReducer.State) -> Bool {
    let selectedSpotID = state.userSession.selectedExploreSpotID
    guard !selectedSpotID.isEmpty else { return false }

    let spot = state.spots.first { $0.id == selectedSpotID }
    return spot?.hasDetail == false
  }

  public static func hasUnresolvedBaseSpots(_ spots: [ExploreMapSpot]) -> Bool {
    return spots.contains { !$0.hasDetail }
  }

  // MARK: - Filtered Data

  public static func filteredSpots(state: ExploreReducer.State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)
    let filtered = state.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.currentLocation else {
      return filtered
    }

    return filtered.sorted { lhs, rhs in
      let lhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: lhs.coordinate.latitude,
          longitude: lhs.coordinate.longitude
        )
      )
      let rhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: rhs.coordinate.latitude,
          longitude: rhs.coordinate.longitude
        )
      )

      return lhsDistance < rhsDistance
    }
  }

  public static func syncSelectedSpot(state: inout ExploreReducer.State) {
    guard let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty else {
      return
    }

    guard state.spots.contains(where: { $0.id == selectedSpotID }) else {
      clearSelectedSpot(state: &state)
      return
    }
  }

  public static func filteredCardSpots(state: ExploreReducer.State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)
    let filtered = state.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.selectedCategory == .all || spot.category == state.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.currentLocation else {
      return filtered
    }

    return filtered.sorted { lhs, rhs in
      let lhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: lhs.coordinate.latitude,
          longitude: lhs.coordinate.longitude
        )
      )
      let rhsDistance = currentLocation.distance(
        from: CLLocation(
          latitude: rhs.coordinate.latitude,
          longitude: rhs.coordinate.longitude
        )
      )

      return lhsDistance < rhsDistance
    }
  }

  public static func currentCardSpots(state: ExploreReducer.State) -> [ExploreMapSpot] {
    return filteredCardSpots(state: state)
  }
}
