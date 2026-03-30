//
//  RouteView.swift
//  Home
//
//  Created by Wonji Suh  on 3/30/26.
//

import SwiftUI
import CoreLocation
import DesignSystem
import Entity
import ComposableArchitecture

public struct RouteView: View {
  @Bindable var store: StoreOf<RouteFeature>
  @Environment(\.dismiss) private var dismiss

  public init(store: StoreOf<RouteFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      naverMap()
        .edgesIgnoringSafeArea(.all)

      VStack {
        headerSection()
        Spacer()
      }
      .padding(.horizontal, 16)
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }



}


private extension RouteView {
  @ViewBuilder
  func naverMap() -> some View {
    NaverMapComponent(
      locationPermissionStatus: store.locationPermissionStatus,
      currentLocation: store.currentLocation,
      routeInfo: store.routeInfo,
      destination: makeDestination(),
      spots: makeSelectedSpotForRoute(),
      selectedSpotID: store.userSession.selectedExploreSpotID.isEmpty
        ? nil
        : store.userSession.selectedExploreSpotID,
      returnToLocationTrigger: 0
    )
  }

  private func makeDestination() -> Destination? {
    guard let lat = store.userSession.routeDestinationLat,
          let lng = store.userSession.routeDestinationLng else { return nil }

    return Destination(
      name: store.userSession.routeDestinationName.nilIfEmpty ?? "목적지",
      coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
    )
  }

  private func makeSelectedSpotForRoute() -> [ExploreMapSpot] {
    guard !store.userSession.selectedExploreSpotID.isEmpty,
          let lat = store.userSession.routeDestinationLat,
          let lng = store.userSession.routeDestinationLng else {
      return []
    }

    let selectedSpot = ExploreMapSpot(
      id: store.userSession.selectedExploreSpotID,
      name: store.userSession.routeDestinationName.nilIfEmpty ?? "선택된 스팟",
      category: .etc, // 기본 카테고리
      coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
      hasDetail: true,
      imageURL: nil,
      badgeText: "",
      subtitle: "",
      statusText: "",
      closingText: "",
      distanceText: "",
      walkTimeText: "",
      address: "",
      visitable: true
    )

    return [selectedSpot]
  }

  @ViewBuilder
  func headerSection() -> some View {
    ExploreSearchHeaderView(
      stationName: store.userSession.routeDestinationName,
      showCategories: false,
      isSearchable: false,
      onBackTap: { dismiss() }
    )
    .padding(.top, 8)
  }

}
