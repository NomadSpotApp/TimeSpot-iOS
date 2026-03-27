//
//  NaverMapComponent.swift
//  Home
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import UIKit
import CoreLocation
import NMapsMap
import DesignSystem
import Entity
import LogMacro

// 네이버 맵을 SwiftUI에서 사용하기 위한 컴포넌트
public struct NaverMapComponent: UIViewRepresentable {
  let locationPermissionStatus: CLAuthorizationStatus
  let currentLocation: CLLocation?
  let routeInfo: RouteInfo?
  let destination: Destination?
  let spots: [ExploreMapSpot]
  let selectedSpotID: String?
  let returnToLocationTrigger: Int
  let onSpotTapped: ((String) -> Void)?
  let onMapTapped: (() -> Void)?

  // 마커와 경로를 저장할 변수들
  private static var currentMarker: NMFMarker?
  private static var destinationMarker: NMFMarker?
  private static var spotMarkers: [String: NMFMarker] = [:]
  private static var selectedSpotID: String?
  private static var lastSyncedSpotID: String?
  private static var lastDestinationKey: String?
  private static var lastReturnToLocationTrigger: Int?
  private static var routePath: NMFPath?

  public init(
    locationPermissionStatus: CLAuthorizationStatus,
    currentLocation: CLLocation?,
    routeInfo: RouteInfo? = nil,
    destination: Destination? = nil,
    spots: [ExploreMapSpot] = [],
    selectedSpotID: String? = nil,
    returnToLocationTrigger: Int = 0,
    onSpotTapped: ((String) -> Void)? = nil,
    onMapTapped: (() -> Void)? = nil
  ) {
    self.locationPermissionStatus = locationPermissionStatus
    self.currentLocation = currentLocation
    self.routeInfo = routeInfo
    self.destination = destination
    self.spots = spots
    self.selectedSpotID = selectedSpotID
    self.returnToLocationTrigger = returnToLocationTrigger
    self.onSpotTapped = onSpotTapped
    self.onMapTapped = onMapTapped
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public func makeUIView(context: Context) -> NMFMapView {
    let mapView = NMFMapView()
    context.coordinator.parent = self

    // 지도 기본 설정
    mapView.positionMode = .normal
    mapView.isZoomGestureEnabled = true
    mapView.isScrollGestureEnabled = true
    mapView.isRotateGestureEnabled = true
    mapView.isTiltGestureEnabled = true

    // 🌙 다크 모드 설정
    mapView.mapType = .navi
    mapView.isNightModeEnabled = true

    // 🎯 네이버 지도 위치 오버레이 설정 (항상 기본 오버레이 사용)
    mapView.locationOverlay.hidden = false
    mapView.touchDelegate = context.coordinator

    // 현재 위치가 있으면 그 위치로, 없으면 선택한 역 위치, 그것도 없으면 서울
    let initialLatitude = currentLocation?.coordinate.latitude
      ?? destination?.coordinate.latitude
      ?? 37.5666805
    let initialLongitude = currentLocation?.coordinate.longitude
      ?? destination?.coordinate.longitude
      ?? 126.9784147

    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: initialLatitude, lng: initialLongitude),
      zoom: 15
    )
    let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
    mapView.moveCamera(cameraUpdate)

    return mapView
  }

  public func updateUIView(_ uiView: NMFMapView, context: Context) {
    context.coordinator.parent = self
    let shouldReturnToLocation =
      currentLocation != nil
      && Self.lastReturnToLocationTrigger != returnToLocationTrigger
    let shouldPrioritizeCurrentLocation = shouldReturnToLocation
    // 기존 마커들과 경로 제거
    Self.currentMarker?.mapView = nil
    Self.destinationMarker?.mapView = nil
    Self.spotMarkers.values.forEach { $0.mapView = nil }
    Self.spotMarkers.removeAll()
    Self.routePath?.mapView = nil

    // 위치 권한이 허용되었고 현재 위치가 있을 때 - 항상 현재 위치 마커 표시
    if (locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways),
       let location = currentLocation {

      // 현재 위치로 돌아가기 버튼이 눌렸을 때만 카메라 이동
      if shouldReturnToLocation {
        Self.lastReturnToLocationTrigger = returnToLocationTrigger
        moveCamera(
          on: uiView,
          to: NMGLatLng(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
          ),
          zoom: 16
        )
      }

      // 경로가 있을 때는 출발점에 빨간색 마커도 추가로 표시
      if routeInfo != nil {
        let currentMarker = NMFMarker()
        currentMarker.position = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)

        // 네이버 기본 마커 (빨간색)
        currentMarker.iconTintColor = UIColor.red
        currentMarker.touchHandler = { _ in
          Self.selectedSpotID = nil
          Self.updateSpotMarkerSelection()
          onMapTapped?()
          return true
        }
        currentMarker.mapView = uiView
        Self.currentMarker = currentMarker

        #logDebug(" [NaverMapComponent] 출발점 마커 추가")
      } else {
        #logDebug(" [NaverMapComponent] 기본 위치 오버레이 사용")
      }
    }

    // 목적지 마커 추가 (네이버 3D 기본 마커 - 초록색)
    if let destination = destination {
      let destinationKey = "\(destination.coordinate.latitude),\(destination.coordinate.longitude),\(destination.name)"
      let destinationMarker = NMFMarker()
      destinationMarker.position = NMGLatLng(
        lat: destination.coordinate.latitude,
        lng: destination.coordinate.longitude
      )

      // 네이버 기본 마커 (초록색)
      destinationMarker.iconTintColor = UIColor.systemGreen
      destinationMarker.touchHandler = { _ in
        Self.selectedSpotID = nil
        Self.updateSpotMarkerSelection()
        onMapTapped?()
        return true
      }
      destinationMarker.mapView = uiView
      Self.destinationMarker = destinationMarker

      #logDebug(" [NaverMapComponent] 목적지 마커 추가: \(destination.name)")

      if !shouldPrioritizeCurrentLocation && Self.lastDestinationKey != destinationKey {
        Self.lastDestinationKey = destinationKey
        moveCamera(
          on: uiView,
          to: NMGLatLng(
            lat: destination.coordinate.latitude,
            lng: destination.coordinate.longitude
          ),
          zoom: 15
        )
      }
    } else {
      Self.lastDestinationKey = nil
    }

    let previousSpotID = Self.lastSyncedSpotID
    Self.selectedSpotID = selectedSpotID
    Self.lastSyncedSpotID = selectedSpotID

    if !spots.contains(where: { $0.id == Self.selectedSpotID }) {
      Self.selectedSpotID = nil
    }

    for spot in spots {
      let marker = NMFMarker()
      marker.position = NMGLatLng(
        lat: spot.coordinate.latitude,
        lng: spot.coordinate.longitude
      )
      marker.iconImage = NMFOverlayImage(image: markerImage(for: spot.category))
      marker.anchor = CGPoint(x: 0.5, y: 1.0)
      Self.applySpotMarkerStyle(
        marker,
        isSelected: spot.id == Self.selectedSpotID
      )
      marker.touchHandler = { _ in
        context.coordinator.markMarkerTap()
        Self.selectedSpotID = spot.id
        Self.updateSpotMarkerSelection()
        onSpotTapped?(spot.id)
        moveCamera(
          on: uiView,
          to: NMGLatLng(
            lat: spot.coordinate.latitude,
            lng: spot.coordinate.longitude
          ),
          zoom: 17
        )
        return true
      }
      marker.mapView = uiView
      Self.spotMarkers[spot.id] = marker
    }

    if !shouldPrioritizeCurrentLocation,
       let selectedSpotID = Self.selectedSpotID,
       let selectedSpot = spots.first(where: { $0.id == selectedSpotID }) {
      let currentCameraTarget = uiView.cameraPosition.target
      let shouldMoveToSelectedSpot =
        selectedSpotID != previousSpotID
        || abs(currentCameraTarget.lat - selectedSpot.coordinate.latitude) > 0.000001
        || abs(currentCameraTarget.lng - selectedSpot.coordinate.longitude) > 0.000001

      if shouldMoveToSelectedSpot {
        moveCamera(
          on: uiView,
          to: NMGLatLng(
            lat: selectedSpot.coordinate.latitude,
            lng: selectedSpot.coordinate.longitude
          ),
          zoom: 17
        )
      }
    } else if !shouldPrioritizeCurrentLocation, routeInfo == nil, !spots.isEmpty {
      adjustCameraToFitSpots(
        mapView: uiView,
        spots: spots,
        destination: destination
      )
    }

    // 도보 경로 그리기
    if let routeInfo = routeInfo, !routeInfo.paths.isEmpty {
      #logDebug(" [NaverMapComponent] 경로 정보: 좌표 \(routeInfo.paths.count)개, 거리 \(routeInfo.distance)m")

      // 경로 좌표들을 NMGLatLng 배열로 변환
      let pathCoords = routeInfo.paths.map { coordinate in
        #logDebug(" [NaverMapComponent] 경로 좌표: \(coordinate.latitude), \(coordinate.longitude)")
        return NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
      }

      // 좌표가 부족한 경우 체크
      guard pathCoords.count >= 2 else {
        #logDebug(" [NaverMapComponent] 경로 좌표 부족: \(pathCoords.count)개")
        return
      }

      // 기존 실선 경로 먼저 그리기
      let pathOverlay = NMFPath()
      let lineString = NMGLineString(points: pathCoords)
      pathOverlay.path = lineString as! NMGLineString<AnyObject>

      // 경로 스타일 (실선으로 표시)
      pathOverlay.color = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.8) // 파란색
      pathOverlay.width = 8
      pathOverlay.outlineColor = UIColor.white
      pathOverlay.outlineWidth = 2
      pathOverlay.mapView = uiView
      Self.routePath = pathOverlay

      // 🎯 경로 전체가 보이도록 카메라 조정 (중앙으로)
      adjustCameraToFitRoute(mapView: uiView, routeCoords: pathCoords, currentLocation: currentLocation)

      #logDebug(" [NaverMapComponent] 경로 표시 및 카메라 조정 완료")
    }
  }

  public final class Coordinator: NSObject, NMFMapViewTouchDelegate {
    var parent: NaverMapComponent
    private var shouldIgnoreNextMapTap = false

    init(parent: NaverMapComponent) {
      self.parent = parent
    }

    func markMarkerTap() {
      shouldIgnoreNextMapTap = true
    }

    public func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
      if shouldIgnoreNextMapTap {
        shouldIgnoreNextMapTap = false
        return
      }
      parent.onMapTapped?()
    }
  }

  // MARK: - Helper Functions

  private func markerImage(for category: ExploreCategory) -> UIImage {
    let asset: ImageAsset
    switch category {
    case .all:
      asset = .etcPin
    case .cafe:
      asset = .cafePin
    case .restaurant:
      asset = .foodPin
    case .activity:
      asset = .gamePin
    case .etc:
      asset = .etcPin
    @unknown default:
      asset = .etcPin
    }

    return UIImage(asset) ?? UIImage()
  }

  private static func applySpotMarkerStyle(
    _ marker: NMFMarker,
    isSelected: Bool
  ) {
    marker.width = isSelected ? 36 : 20
    marker.height = isSelected ? 43 : 24
    marker.zIndex = isSelected ? 100 : 10
  }

  private static func updateSpotMarkerSelection() {
    for (spotID, marker) in spotMarkers {
      applySpotMarkerStyle(marker, isSelected: spotID == selectedSpotID)
    }
  }

  private func moveCamera(
    on mapView: NMFMapView,
    to target: NMGLatLng,
    zoom: Double
  ) {
    let cameraPosition = NMFCameraPosition(target, zoom: zoom)
    let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
    cameraUpdate.animation = .easeOut
    cameraUpdate.animationDuration = 0.45
    mapView.moveCamera(cameraUpdate)
  }

  // 3D 효과가 있는 핀 마커 이미지 생성
  private func create3DMarkerImage(color: UIColor, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let cgContext = context.cgContext

      // 핀의 원형 부분 (상단)
      let circleRadius = size.width * 0.35
      let circleCenter = CGPoint(x: size.width / 2, y: circleRadius + 2)

      // 3D 효과를 위한 그라데이션
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let lightColor = color.withAlphaComponent(1.0).cgColor
      let darkColor = color.withAlphaComponent(0.7).cgColor

      let gradient = CGGradient(colorsSpace: colorSpace, colors: [lightColor, darkColor] as CFArray, locations: [0.0, 1.0])!

      // 원형 부분 그리기 (3D 그라데이션)
      cgContext.saveGState()
      cgContext.addEllipse(in: CGRect(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius,
                                     width: circleRadius * 2, height: circleRadius * 2))
      cgContext.clip()
      cgContext.drawRadialGradient(gradient,
                                  startCenter: CGPoint(x: circleCenter.x - circleRadius * 0.3, y: circleCenter.y - circleRadius * 0.3),
                                  startRadius: 0,
                                  endCenter: circleCenter,
                                  endRadius: circleRadius,
                                  options: [])
      cgContext.restoreGState()

      // 핀의 삼각형 부분 (하단)
      cgContext.setFillColor(darkColor)
      cgContext.beginPath()
      cgContext.move(to: CGPoint(x: circleCenter.x - circleRadius * 0.5, y: circleCenter.y + circleRadius * 0.7))
      cgContext.addLine(to: CGPoint(x: circleCenter.x + circleRadius * 0.5, y: circleCenter.y + circleRadius * 0.7))
      cgContext.addLine(to: CGPoint(x: circleCenter.x, y: size.height - 2))
      cgContext.closePath()
      cgContext.fillPath()

      // 테두리 (입체감 강화)
      cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
      cgContext.setLineWidth(1)
      cgContext.addEllipse(in: CGRect(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius,
                                     width: circleRadius * 2, height: circleRadius * 2))
      cgContext.strokePath()

      // 중앙 하이라이트 점
      cgContext.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
      cgContext.addEllipse(in: CGRect(x: circleCenter.x - 3, y: circleCenter.y - 3, width: 6, height: 6))
      cgContext.fillPath()
    }
  }

  // 경로 전체가 보이도록 카메라 조정
  private func adjustCameraToFitRoute(mapView: NMFMapView, routeCoords: [NMGLatLng], currentLocation: CLLocation?) {
    var allCoords = routeCoords

    // 현재 위치도 포함
    if let location = currentLocation {
      allCoords.append(NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude))
    }

    guard allCoords.count > 0 else { return }

    // 좌표들의 최소/최대값 계산
    var minLat = allCoords[0].lat
    var maxLat = allCoords[0].lat
    var minLng = allCoords[0].lng
    var maxLng = allCoords[0].lng

    for coord in allCoords {
      minLat = min(minLat, coord.lat)
      maxLat = max(maxLat, coord.lat)
      minLng = min(minLng, coord.lng)
      maxLng = max(maxLng, coord.lng)
    }

    // 약간의 여백 추가 (10%)
    let latPadding = (maxLat - minLat) * 0.1
    let lngPadding = (maxLng - minLng) * 0.1

    let bounds = NMGLatLngBounds(
      southWest: NMGLatLng(lat: minLat - latPadding, lng: minLng - lngPadding),
      northEast: NMGLatLng(lat: maxLat + latPadding, lng: maxLng + lngPadding)
    )

    // 카메라를 bounds에 맞게 조정
    let cameraUpdate = NMFCameraUpdate(fit: bounds, paddingInsets: UIEdgeInsets(top: 100, left: 50, bottom: 100, right: 50))
    cameraUpdate.animationDuration = 1.0
    mapView.moveCamera(cameraUpdate)

    #logDebug(" [NaverMapComponent] 경로 전체가 보이도록 카메라 조정 완료")
  }

  private func adjustCameraToFitSpots(
    mapView: NMFMapView,
    spots: [ExploreMapSpot],
    destination: Destination?
  ) {
    var allCoords = spots.map {
      NMGLatLng(lat: $0.coordinate.latitude, lng: $0.coordinate.longitude)
    }

    if let destination {
      allCoords.append(
        NMGLatLng(
          lat: destination.coordinate.latitude,
          lng: destination.coordinate.longitude
        )
      )
    }

    guard let first = allCoords.first else { return }

    var minLat = first.lat
    var maxLat = first.lat
    var minLng = first.lng
    var maxLng = first.lng

    for coord in allCoords {
      minLat = min(minLat, coord.lat)
      maxLat = max(maxLat, coord.lat)
      minLng = min(minLng, coord.lng)
      maxLng = max(maxLng, coord.lng)
    }

    let latPadding = max((maxLat - minLat) * 0.25, 0.0015)
    let lngPadding = max((maxLng - minLng) * 0.25, 0.0015)

    let bounds = NMGLatLngBounds(
      southWest: NMGLatLng(lat: minLat - latPadding, lng: minLng - lngPadding),
      northEast: NMGLatLng(lat: maxLat + latPadding, lng: maxLng + lngPadding)
    )

    let cameraUpdate = NMFCameraUpdate(
      fit: bounds,
      paddingInsets: UIEdgeInsets(top: 180, left: 48, bottom: 220, right: 48)
    )
    cameraUpdate.animation = .easeOut
    cameraUpdate.animationDuration = 0.45
    mapView.moveCamera(cameraUpdate)
  }

  private func createCircleMarkerImage(color: UIColor, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      // 원형 마커 생성 (스크린샷 스타일)
      color.setFill()
      UIColor.white.setStroke()

      let rect = CGRect(origin: .zero, size: size)
      let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
      circlePath.lineWidth = 3

      // 원 그리기
      circlePath.fill()
      circlePath.stroke()

      // 중앙에 작은 흰색 점 (네이버 스타일)
      UIColor.white.setFill()
      let centerDot = UIBezierPath(ovalIn: rect.insetBy(dx: size.width/3, dy: size.height/3))
      centerDot.fill()
    }
  }
}

#Preview {
  NaverMapComponent(
    locationPermissionStatus: .authorizedWhenInUse,
    currentLocation: CLLocation(latitude: 37.5666805, longitude: 126.9784147)
  )
}
