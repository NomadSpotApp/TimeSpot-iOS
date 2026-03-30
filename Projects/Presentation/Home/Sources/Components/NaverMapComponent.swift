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
  let travelStation: Destination? // 🚉 출발역 정보
  let spots: [ExploreMapSpot]
  let selectedSpotID: String?
  let returnToLocationTrigger: Int
  let onSpotTapped: ((String) -> Void)?
  let onMapTapped: (() -> Void)?
  let onCameraIdle: ((CLLocationCoordinate2D) -> Void)?

  // 마커와 경로를 저장할 변수들
  private static var currentMarker: NMFMarker?
  private static var destinationMarker: NMFMarker?
  private static var spotMarkers: [String: NMFMarker] = [:]
  private static let markerImageCache = NSCache<NSString, UIImage>()
  private static var selectedSpotID: String?
  private static var lastSyncedSpotID: String?
  private static var lastDestinationKey: String?
  private static var lastReturnToLocationTrigger: Int?
  private static var lastAutoFitKey: String?
  private static var routePath: NMFPath?

  public init(
    locationPermissionStatus: CLAuthorizationStatus,
    currentLocation: CLLocation?,
    routeInfo: RouteInfo? = nil,
    destination: Destination? = nil,
    travelStation: Destination? = nil,
    spots: [ExploreMapSpot] = [],
    selectedSpotID: String? = nil,
    returnToLocationTrigger: Int = 0,
    onSpotTapped: ((String) -> Void)? = nil,
    onMapTapped: (() -> Void)? = nil,
    onCameraIdle: ((CLLocationCoordinate2D) -> Void)? = nil
  ) {
    self.locationPermissionStatus = locationPermissionStatus
    self.currentLocation = currentLocation
    self.routeInfo = routeInfo
    self.destination = destination
    self.travelStation = travelStation
    self.spots = spots
    self.selectedSpotID = selectedSpotID
    self.returnToLocationTrigger = returnToLocationTrigger
    self.onSpotTapped = onSpotTapped
    self.onMapTapped = onMapTapped
    self.onCameraIdle = onCameraIdle
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

    // ☀️ 라이트 모드 설정
    mapView.mapType = .basic
    mapView.isNightModeEnabled = false

    // 🎯 네이버 지도 위치 오버레이 설정 (항상 기본 오버레이 사용)
    mapView.locationOverlay.hidden = false
    mapView.touchDelegate = context.coordinator
    mapView.addCameraDelegate(delegate: context.coordinator)

    let (initialLatitude, initialLongitude): (Double, Double) = {
      if let routeInfo = routeInfo,
         let currentLoc = currentLocation,
         let dest = destination {

        var locations: [(lat: Double, lng: Double)] = []

        // 1. 출발역이 있으면 추가
        if let station = travelStation {
          locations.append((lat: station.coordinate.latitude, lng: station.coordinate.longitude))
        }

        // 2. 현재 위치 (출발지) 추가
        locations.append((lat: currentLoc.coordinate.latitude, lng: currentLoc.coordinate.longitude))

        // 3. 목적지 추가
        locations.append((lat: dest.coordinate.latitude, lng: dest.coordinate.longitude))

        // 모든 위치의 중심점 계산
        let centerLat = locations.reduce(0.0) { $0 + $1.lat } / Double(locations.count)
        let centerLng = locations.reduce(0.0) { $0 + $1.lng } / Double(locations.count)

        return (centerLat, centerLng)
      } else {
        let lat = destination?.coordinate.latitude
          ?? currentLocation?.coordinate.latitude
          ?? 37.5666805
        let lng = destination?.coordinate.longitude
          ?? currentLocation?.coordinate.longitude
          ?? 126.9784147
        return (lat, lng)
      }
    }()

    // 🗺️ 경로 모드일 때는 더 넓은 범위를 보여주기 위해 줌 레벨 조정
    let zoomLevel: Double = routeInfo != nil ? 9.0 : 15.0

    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: initialLatitude, lng: initialLongitude),
      zoom: zoomLevel
    )
    let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
    mapView.moveCamera(cameraUpdate)

    return mapView
  }

  public static func dismantleUIView(_ uiView: NMFMapView, coordinator: Coordinator) {
    uiView.removeCameraDelegate(delegate: coordinator)

    // 경로와 destination 마커만 정리
    Self.currentMarker?.mapView = nil
    Self.destinationMarker?.mapView = nil
    Self.routePath?.mapView = nil
    Self.currentMarker = nil
    Self.destinationMarker = nil
    Self.routePath = nil

    Self.lastSyncedSpotID = nil
    Self.lastDestinationKey = nil
    Self.lastReturnToLocationTrigger = nil
    Self.lastAutoFitKey = nil
  }

  public func updateUIView(_ uiView: NMFMapView, context: Context) {
    context.coordinator.parent = self

    let shouldReturnToLocation =
      currentLocation != nil
      && Self.lastReturnToLocationTrigger != returnToLocationTrigger
    let shouldPrioritizeCurrentLocation = shouldReturnToLocation
    let autoFitKey = makeAutoFitKey(destination: destination, spots: spots)
    Self.routePath?.mapView = nil
    Self.routePath = nil

    // 위치 권한이 허용되었고 현재 위치가 있을 때 - 항상 현재 위치 마커 표시
    if (locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways),
       let location = currentLocation {

      // 현재 위치로 돌아가기 버튼이 눌렸을 때만 카메라 이동
      if shouldReturnToLocation {
        Self.lastReturnToLocationTrigger = returnToLocationTrigger
        Self.lastAutoFitKey = autoFitKey

        let target = NMGLatLng(
          lat: location.coordinate.latitude,
          lng: location.coordinate.longitude
        )

        let zoomLevel: Double = routeInfo != nil ? 9.0 : 16.0

        moveCamera(
          on: uiView,
          to: target,
          zoom: zoomLevel
        )
      }

      // 경로가 있을 때는 출발점에 startLocation 이미지 마커 표시
      if routeInfo != nil {
        if Self.currentMarker == nil {
          let currentMarker = NMFMarker()
          currentMarker.zIndex = 900 // 🎯 출발점 마커도 높은 z-index 설정 (destination보다 낮음)
          currentMarker.touchHandler = { _ in
            Self.setSelectedSpotID(nil)
            onMapTapped?()
            return true
          }
          currentMarker.mapView = uiView
          Self.currentMarker = currentMarker
        }

        if let currentMarker = Self.currentMarker {
          // 여러 방법으로 이미지 로딩 시도
          var startLocationImage: UIImage?

          // 방법 1: UIImage(assetName:)
          startLocationImage = UIImage(assetName: "startLocation")
          if startLocationImage == nil {
            // 방법 2: UIImage(.startLocation)
            startLocationImage = UIImage(.startLocation)
          }

          if let image = startLocationImage {

            // SVG를 PNG로 렌더링해서 사용
            if let pngImage = image.pngData().flatMap({ UIImage(data: $0) }) {
              currentMarker.iconImage = NMFOverlayImage(image: pngImage)
              currentMarker.width = 32
              currentMarker.height = 38
              // 커스텀 이미지 사용 시 틴트 색상 제거
              currentMarker.iconTintColor = UIColor.clear
            } else {
              // PNG 변환 실패시 원본 이미지 사용
              currentMarker.iconImage = NMFOverlayImage(image: image)
              currentMarker.width = 32
              currentMarker.height = 38
              currentMarker.iconTintColor = UIColor.clear
            }
          } else {
            currentMarker.iconTintColor = UIColor.systemBlue  // 파란색으로 구분
            currentMarker.width = CGFloat(NMF_MARKER_SIZE_AUTO)
            currentMarker.height = CGFloat(NMF_MARKER_SIZE_AUTO)
          }
        }

        Self.currentMarker?.position = NMGLatLng(
          lat: location.coordinate.latitude,
          lng: location.coordinate.longitude
        )
        Self.currentMarker?.mapView = uiView

      } else {
        Self.currentMarker?.mapView = nil
        Self.currentMarker = nil
      }
    } else {
      Self.currentMarker?.mapView = nil
      Self.currentMarker = nil
    }

    // 목적지 마커 추가 (경로 찾기일 때는 endLocation 이미지, 아니면 기본 네이버 마커)
    if let destination = destination {
      let destinationKey = "\(destination.coordinate.latitude),\(destination.coordinate.longitude),\(destination.name)"
      let isRouteMode = routeInfo != nil

      if Self.destinationMarker == nil {
        let destinationMarker = NMFMarker()
        destinationMarker.touchHandler = { _ in
          Self.setSelectedSpotID(nil)
          onMapTapped?()
          return true
        }
        destinationMarker.mapView = uiView
        Self.destinationMarker = destinationMarker
      }

      // 마커 스타일을 routeInfo 상태에 따라 업데이트
      if let destinationMarker = Self.destinationMarker {
        // 먼저 기존 설정 초기화
        destinationMarker.width = CGFloat(NMF_MARKER_SIZE_AUTO)
        destinationMarker.height = CGFloat(NMF_MARKER_SIZE_AUTO)

        if isRouteMode {
          // 경로 찾기 모드일 때는 endLocation 이미지 사용
          var endLocationImage: UIImage?

          // 방법 1: UIImage(assetName:)
          endLocationImage = UIImage(assetName: "endLocation")
          if endLocationImage == nil {
            // 방법 2: UIImage(.endLocation)
            endLocationImage = UIImage(.endLocation)
          }

          if let image = endLocationImage {

            // 강제로 새 마커 생성해서 확실히 적용
            let newDestinationMarker = NMFMarker()
            newDestinationMarker.iconImage = NMFOverlayImage(image: image)
            newDestinationMarker.width = 32
            newDestinationMarker.height = 38
            newDestinationMarker.zIndex = 1000 // 🎯 최우선 표시를 위해 높은 z-index 설정
            newDestinationMarker.position = NMGLatLng(
              lat: destination.coordinate.latitude,
              lng: destination.coordinate.longitude
            )
            newDestinationMarker.touchHandler = { _ in
              Self.setSelectedSpotID(nil)
              onMapTapped?()
              return true
            }

            // 기존 마커 제거 후 새 마커 추가
            Self.destinationMarker?.mapView = nil
            Self.destinationMarker = newDestinationMarker
            newDestinationMarker.mapView = uiView
          } else {
            destinationMarker.iconTintColor = UIColor.systemOrange  // 오렌지색으로 구분
            destinationMarker.width = CGFloat(NMF_MARKER_SIZE_AUTO)
            destinationMarker.height = CGFloat(NMF_MARKER_SIZE_AUTO)
          }
        } else {
          // 일반 모드일 때는 기본 네이버 지도 마커 (초록색)
          destinationMarker.iconTintColor = UIColor.systemGreen
          destinationMarker.width = CGFloat(NMF_MARKER_SIZE_AUTO)
          destinationMarker.height = CGFloat(NMF_MARKER_SIZE_AUTO)
        }
      }

      // 경로 모드가 아닐 때만 position 업데이트 (경로 모드에서는 새 마커에서 이미 설정됨)
      if !isRouteMode {
        Self.destinationMarker?.position = NMGLatLng(
          lat: destination.coordinate.latitude,
          lng: destination.coordinate.longitude
        )
        Self.destinationMarker?.mapView = uiView
      }

      // destination이 변경되면 항상 해당 역 중심으로 카메라 이동
      if Self.lastDestinationKey != destinationKey {
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
      Self.destinationMarker?.mapView = nil
      Self.destinationMarker = nil
      Self.lastDestinationKey = nil
    }

    let previousSpotID = Self.lastSyncedSpotID

    // 먼저 마커들을 동기화한 후에 선택 상태를 설정
    syncSpotMarkers(
      on: uiView,
      coordinator: context.coordinator,
      onSpotTapped: onSpotTapped
    )

    Self.setSelectedSpotID(selectedSpotID)
    Self.lastSyncedSpotID = Self.selectedSpotID

    if !spots.contains(where: { $0.id == Self.selectedSpotID }) {
      Self.setSelectedSpotID(nil)
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
    } else if !shouldPrioritizeCurrentLocation,
              routeInfo == nil,
              !spots.isEmpty,
              Self.lastAutoFitKey != autoFitKey {
      Self.lastAutoFitKey = autoFitKey
      adjustCameraToFitSpots(
        mapView: uiView,
        spots: spots,
        destination: destination
      )
    }

    // 도보 경로 그리기
    if let routeInfo = routeInfo, !routeInfo.paths.isEmpty {
      // 경로 좌표들을 NMGLatLng 배열로 변환
      let pathCoords = routeInfo.paths.map { coordinate in
        return NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
      }

      // 좌표가 부족한 경우 체크
      guard pathCoords.count >= 2 else {
        return
      }

      // 기존 실선 경로 먼저 그리기
      let pathOverlay = NMFPath()
      let lineString = NMGLineString(points: pathCoords)
      pathOverlay.path = lineString as! NMGLineString<AnyObject>

      // 경로 스타일 (실선으로 표시)
      pathOverlay.color = UIColor(hex: "#223B73", alpha: 1.0) // 메인 경로 색상
      pathOverlay.width = 8
      pathOverlay.outlineColor = UIColor(hex: "#4D6399", alpha: 1.0) // 외곽선 색상
      pathOverlay.outlineWidth = 2
      pathOverlay.mapView = uiView
      Self.routePath = pathOverlay

      // 🎯 경로 전체가 보이도록 카메라 조정 (중앙으로)
      adjustCameraToFitRoute(mapView: uiView, routeCoords: pathCoords, currentLocation: currentLocation)

    }
  }

  public final class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate {
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

    public func mapViewCameraIdle(_ mapView: NMFMapView) {
      let target = mapView.cameraPosition.target
      parent.onCameraIdle?(
        CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng)
      )
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
    case .shopping:
      asset = .shoppingPin
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

  private static func setSelectedSpotID(_ newValue: String?) {
    guard selectedSpotID != newValue else { return }

    let previousSpotID = selectedSpotID
    selectedSpotID = newValue

    if let previousSpotID, let previousMarker = spotMarkers[previousSpotID] {
      applySpotMarkerStyle(previousMarker, isSelected: false)
    }

    if let newValue, let selectedMarker = spotMarkers[newValue] {
      applySpotMarkerStyle(selectedMarker, isSelected: true)
    }
  }

  private func syncSpotMarkers(
    on mapView: NMFMapView,
    coordinator: Coordinator,
    onSpotTapped: ((String) -> Void)?
  ) {
    let currentSpotIDs = Set(spots.map(\.id))
    let isRouteMode = routeInfo != nil

    // 경로 찾기 모드일 때는 모든 spot 마커들 숨김 (데이터는 보존)
    if isRouteMode {
      for (_, marker) in Self.spotMarkers {
        marker.mapView = nil  // 지도에서만 숨김, 마커 객체는 유지
      }
      return  // spot 마커 처리 종료
    }

    // 일반 모드에서는 모든 기존 마커들을 지도에 재연결
    for (_, marker) in Self.spotMarkers {
      marker.mapView = mapView
    }

    // 🔧 핵심 수정: 현재 spots에 없는 마커들 먼저 숨김
    for (markerID, marker) in Self.spotMarkers {
      if !currentSpotIDs.contains(markerID) {
        marker.mapView = nil  // 필터링으로 제외된 마커 숨김
      }
    }

    for spot in spots {
      let marker: NMFMarker

      if let existingMarker = Self.spotMarkers[spot.id] {
        marker = existingMarker
      } else {
        let newMarker = NMFMarker()
        newMarker.anchor = CGPoint(x: 0.5, y: 1.0)
        Self.spotMarkers[spot.id] = newMarker
        marker = newMarker
      }

      // 마커를 지도에 확실히 연결
      marker.mapView = mapView

      marker.position = NMGLatLng(
        lat: spot.coordinate.latitude,
        lng: spot.coordinate.longitude
      )
      marker.iconImage = NMFOverlayImage(image: markerImage(for: spot.category))
      marker.mapView = mapView
      marker.touchHandler = { _ in
        coordinator.markMarkerTap()
        Self.setSelectedSpotID(spot.id)
        onSpotTapped?(spot.id)
        moveCamera(
          on: mapView,
          to: NMGLatLng(
            lat: spot.coordinate.latitude,
            lng: spot.coordinate.longitude
          ),
          zoom: 17
        )
        return true
      }
      Self.applySpotMarkerStyle(marker, isSelected: spot.id == Self.selectedSpotID)
    }

    // 선택된 스팟이 현재 spots 배열에 없더라도 마커 스타일 유지하고 표시
    if let selectedSpotID = Self.selectedSpotID,
       let selectedMarker = Self.spotMarkers[selectedSpotID] {

      if !currentSpotIDs.contains(selectedSpotID) {
        // 마커가 지도에서 제거되었을 수 있으므로 다시 추가
        selectedMarker.mapView = mapView

        // 선택된 스타일 적용
        Self.applySpotMarkerStyle(selectedMarker, isSelected: true)

        // 마커 터치 핸들러 재설정
        selectedMarker.touchHandler = { _ in
          coordinator.markMarkerTap()
          Self.setSelectedSpotID(selectedSpotID)
          onSpotTapped?(selectedSpotID)
          return true
        }
      } else {
        // spots 배열에 있는 경우는 정상적으로 선택된 스타일 적용
        Self.applySpotMarkerStyle(selectedMarker, isSelected: true)
      }
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

  private func makeAutoFitKey(
    destination: Destination?,
    spots: [ExploreMapSpot]
  ) -> String {
    let destinationKey = destination.map {
      "\($0.name)-\($0.coordinate.latitude)-\($0.coordinate.longitude)"
    } ?? "nil"
    let spotKey = spots
      .map { "\($0.id)-\($0.coordinate.latitude)-\($0.coordinate.longitude)" }
      .sorted()
      .joined(separator: "|")
    return "\(destinationKey)::\(spotKey)"
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
    currentLocation: CLLocation(latitude: 37.5666805, longitude: 126.9784147),
    routeInfo: nil as RouteInfo?,
    destination: nil as Destination?,
    travelStation: nil as Destination?,
    spots: [],
    selectedSpotID: nil as String?,
    returnToLocationTrigger: 0
  )
}
