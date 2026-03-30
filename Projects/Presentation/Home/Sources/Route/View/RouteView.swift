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
import LogMacro
import Utill

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

      // 🦴 경로 계산 중일 때는 스켈레톤 전체 화면으로 표시
      if store.routeInfo == nil {
        RouteSkeletonView()
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.3), value: store.routeInfo == nil)
      } else {
        // ✅ 경로 계산 완료 후 실제 UI 표시
        VStack {
          headerSection()

          remainingTimeCard()
            .padding(.top, 12)
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: store.routeInfo != nil)

          Spacer()

          // 🧭 길찾기 버튼 (하단에서 32만큼 떨어진 위치)
          routeStartButton()
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 16)
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: store.routeInfo != nil)
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}


private extension RouteView {
  @ViewBuilder
  func naverMap() -> some View {
    let destination = makeDestination()
    let routeInfo = store.routeInfo

    NaverMapComponent(
      locationPermissionStatus: store.locationPermissionStatus,
      currentLocation: store.currentLocation,
      routeInfo: routeInfo,
      destination: destination,
      spots: [], // 🚗 경로 모드에서는 spots 마커를 전달하지 않음
      selectedSpotID: nil, // 🚗 경로 모드에서는 선택된 스팟 없음
      returnToLocationTrigger: 0
    )
    .onAppear {
      #logDebug("🎯 [RouteView] routeInfo: \(routeInfo != nil ? "있음" : "nil")")
      #logDebug("🎯 [RouteView] destination: \(destination?.name ?? "nil")")
    }
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

  @ViewBuilder
  func remainingTimeCard() -> some View {
    VStack(alignment: .leading) {
      HStack {
        Text("도보")
          .pretendardCustomFont(textStyle: .body2Medium)
          .foregroundStyle(.staticBlack)

        Spacer()
      }

      Spacer()
        .frame(height: 4)

      HStack{
        Text((store.routeInfo?.duration ?? 0).formattedDuration)
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.orange800)

        Spacer()

        Text((store.routeInfo?.distance ?? 0).formattedDistance)
          .pretendardCustomFont(textStyle: .bodyMedium)
          .foregroundStyle(.gray800)
      }

      Spacer()
        .frame(height: 8)

      HStack {
        Image(systemName: "clock")
          .foregroundStyle(.gray600)
          .font(.system(size: 12))

        Text("\(Date.estimatedArrivalTime(durationMinutes: store.routeInfo?.duration ?? 0)) 도착 예정")
          .pretendardCustomFont(textStyle: .caption)
          .foregroundStyle(.gray600)

        Spacer()
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 28)
        .stroke(.orange500, style: .init(lineWidth: 1))
        .background(.orange100)
    )
    .cornerRadius(28)
  }

  @ViewBuilder
  private func routeStartButton() -> some View {
    CustomButton(
      action: {
        store.send(.view(.startNavigation))
      },
      title: "길찾기 시작",
      config: CustomButtonConfig.create(),
      isEnable: store.routeInfo != nil
    )
    .padding(.horizontal, 16)
  }


}
