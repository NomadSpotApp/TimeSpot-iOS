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

  // MARK: - 거리 기반 정렬 최적화

  /// 거리 기반으로 스팟들을 정렬 (CLLocation 객체 생성 최소화)
  private static func sortSpotsByDistance(_ spots: [ExploreMapSpot], from currentLocation: CLLocation) -> [ExploreMapSpot] {
    let spotsWithDistance = spots.map { spot in
      let location = CLLocation(
        latitude: spot.coordinate.latitude,
        longitude: spot.coordinate.longitude
      )
      let distance = currentLocation.distance(from: location)
      return (spot: spot, distance: distance)
    }

    return spotsWithDistance
      .sorted { $0.distance < $1.distance }
      .map { $0.spot }
  }

  // MARK: - State Management

  public static func resetPagination(state: inout ExploreFeature.State) {
    state.place.currentPage = 0
    state.place.hasNextPage = true
    state.place.pendingSelectFirstSpot = false
  }

  public static func resetSearchContext(
    state: inout ExploreFeature.State,
    clearMarker: Bool = true,
    preserveSearchText: Bool = false,
    preserveSelectedCategory: Bool = false
  ) {
    if !preserveSearchText {
      state.place.searchText = ""
    }
    if !preserveSelectedCategory {
      state.place.selectedCategory = .all
    }
    state.place.isLoading = false
    state.place.hasRequested = false
    resetPagination(state: &state)
    if clearMarker {
      state.mapUI.searchMarkerLat = nil
      state.mapUI.searchMarkerLon = nil
    }
  }

  public static func clearSelectedSpot(state: inout ExploreFeature.State) {
    state.mapUI.isSpotCardVisible = false
    state.mapUI.cardDragOffset = 0
    state.mapUI.cardBaseOffset = 0
    state.mapUI.isCardTransitioning = false

    state.$userSession.withLock {
      $0.selectedExploreSpotID = ""
      $0.selectedExplorePlaceID = ""
    }
  }

  // MARK: - Data Calculations

  public static func currentKeyword(state: ExploreFeature.State) -> String {
    return state.place.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public static func currentCategory(state: ExploreFeature.State) -> ExploreCategory? {
    return state.place.selectedCategory == .all ? nil : state.place.selectedCategory
  }


  public static func isResolvingSelectedMarkerDetail(state: ExploreFeature.State) -> Bool {
    let selectedSpotID = state.userSession.selectedExploreSpotID
    guard !selectedSpotID.isEmpty else { return false }

    let spot = state.place.spots.first { $0.id == selectedSpotID }
    return spot?.hasDetail == false
  }


  // MARK: - Filtered Data

  public static func filteredSpots(state: ExploreFeature.State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)
    let filtered = state.place.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.place.selectedCategory == .all || spot.category == state.place.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.location.currentLocation else {
      return filtered
    }

    return sortSpotsByDistance(filtered, from: currentLocation)
  }

  public static func syncSelectedSpot(state: inout ExploreFeature.State) {
    guard let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty else {
      return
    }

    guard state.place.spots.contains(where: { $0.id == selectedSpotID }) else {
      clearSelectedSpot(state: &state)
      return
    }
  }

  public static func syncSelectionWithFilters(state: inout ExploreFeature.State) {
    guard let selectedSpotID = state.userSession.selectedExploreSpotID.nilIfEmpty else {
      return
    }

    guard let selectedSpot = state.place.spots.first(where: { $0.id == selectedSpotID && $0.hasDetail }) else {
      clearSelectedSpot(state: &state)
      return
    }

    let matchesCategory = state.place.selectedCategory == .all || selectedSpot.category == state.place.selectedCategory
    let query = currentKeyword(state: state)
    let matchesQuery = query.isEmpty || selectedSpot.name.localizedCaseInsensitiveContains(query)

    if !matchesCategory || !matchesQuery {
      clearSelectedSpot(state: &state)
    }
  }

  public static func filteredCardSpots(state: ExploreFeature.State) -> [ExploreMapSpot] {
    let query = currentKeyword(state: state)
    let filtered = state.place.spots.filter { spot in
      let hasDetail = spot.hasDetail
      let matchesCategory = state.place.selectedCategory == .all || spot.category == state.place.selectedCategory
      let matchesQuery = query.isEmpty || spot.name.localizedCaseInsensitiveContains(query)
      return hasDetail && matchesCategory && matchesQuery
    }

    guard let currentLocation = state.location.currentLocation else {
      return filtered
    }

    return sortSpotsByDistance(filtered, from: currentLocation)
  }

  public static func currentCardSpots(state: ExploreFeature.State) -> [ExploreMapSpot] {
    return filteredCardSpots(state: state)
  }
}
