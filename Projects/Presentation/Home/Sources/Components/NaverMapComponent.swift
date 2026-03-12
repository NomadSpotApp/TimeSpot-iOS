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
import Entity

// 네이버 맵을 SwiftUI에서 사용하기 위한 컴포넌트
public struct NaverMapComponent: UIViewRepresentable {
  let locationPermissionStatus: CLAuthorizationStatus
  let currentLocation: CLLocation?
  let routeInfo: RouteInfo?
  let destination: Destination?
  let returnToLocation: Bool // 현재 위치로 돌아가기 트리거

  // 마커와 경로를 저장할 변수들
  private static var currentMarker: NMFMarker?
  private static var destinationMarker: NMFMarker?
  private static var routePath: NMFPath?

  public init(
    locationPermissionStatus: CLAuthorizationStatus,
    currentLocation: CLLocation?,
    routeInfo: RouteInfo? = nil,
    destination: Destination? = nil,
    returnToLocation: Bool = false
  ) {
    self.locationPermissionStatus = locationPermissionStatus
    self.currentLocation = currentLocation
    self.routeInfo = routeInfo
    self.destination = destination
    self.returnToLocation = returnToLocation
  }

  public func makeUIView(context: Context) -> NMFMapView {
    let mapView = NMFMapView()

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

    // 현재 위치가 있으면 그 위치로, 없으면 서울로 초기 설정
    let initialLatitude = currentLocation?.coordinate.latitude ?? 37.5666805
    let initialLongitude = currentLocation?.coordinate.longitude ?? 126.9784147

    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: initialLatitude, lng: initialLongitude),
      zoom: 15
    )
    let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
    mapView.moveCamera(cameraUpdate)

    return mapView
  }

  public func updateUIView(_ uiView: NMFMapView, context: Context) {
    // 기존 마커들과 경로 제거
    Self.currentMarker?.mapView = nil
    Self.destinationMarker?.mapView = nil
    Self.routePath?.mapView = nil

    // 위치 권한이 허용되었고 현재 위치가 있을 때 - 항상 현재 위치 마커 표시
    if (locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways),
       let location = currentLocation {

      // 현재 위치로 돌아가기 버튼이 눌렸을 때만 카메라 이동
      if returnToLocation {
        let cameraPosition = NMFCameraPosition(
          NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude),
          zoom: 16
        )
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animationDuration = 0.8
        uiView.moveCamera(cameraUpdate)
      }

      // 경로가 있을 때는 출발점에 빨간색 마커도 추가로 표시
      if routeInfo != nil {
        let currentMarker = NMFMarker()
        currentMarker.position = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)

        // 네이버 기본 마커 (빨간색)
        currentMarker.iconTintColor = UIColor.red
        currentMarker.mapView = uiView
        Self.currentMarker = currentMarker

        print("🔴 [NaverMap] 출발점 빨간색 마커 추가 (텍스트 없이)")
      } else {
        print("🎯 [NaverMap] 네이버 기본 위치 오버레이만 사용")
      }
    }

    // 목적지 마커 추가 (네이버 3D 기본 마커 - 초록색)
    if let destination = destination {
      let destinationMarker = NMFMarker()
      destinationMarker.position = NMGLatLng(
        lat: destination.coordinate.latitude,
        lng: destination.coordinate.longitude
      )

      // 네이버 기본 마커 (초록색)
      destinationMarker.iconTintColor = UIColor.systemGreen
      destinationMarker.mapView = uiView
      Self.destinationMarker = destinationMarker

      print("🗺️ [NaverMap] 목적지 3D 마커 추가 (32x32): \(destination.name)")
    }

    // 도보 경로 그리기
    if let routeInfo = routeInfo, !routeInfo.paths.isEmpty {
      print("🗺️ [NaverMap] 경로 정보: \(routeInfo.paths.count)개 좌표, 거리: \(routeInfo.distance)m")

      // 경로 좌표들을 NMGLatLng 배열로 변환
      let pathCoords = routeInfo.paths.map { coordinate in
        print("📍 좌표: \(coordinate.latitude), \(coordinate.longitude)")
        return NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
      }

      // 좌표가 부족한 경우 체크
      guard pathCoords.count >= 2 else {
        print("🚨 [NaverMap] 경로 좌표가 부족합니다: \(pathCoords.count)개")
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

      print("🔵 [NaverMap] 경로 표시 및 카메라 조정 완료")
    }
  }

  // MARK: - Helper Functions

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

    print("📹 [NaverMap] 경로 전체가 보이도록 카메라 조정 완료")
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
