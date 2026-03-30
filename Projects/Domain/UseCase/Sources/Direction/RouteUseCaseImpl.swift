//
//  GetRouteUseCaseImpl.swift
//  UseCase
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit

import DomainInterface
import Entity
import ComposableArchitecture
import LogMacro

/// 경로 검색 비즈니스 로직을 처리하는 UseCase
public struct RouteUseCaseImpl: DirectionInterface {

    @Dependency(\.directionRepository) var repository

    public init() {}

    /// 경로를 검색합니다
    public func execute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        option: RouteOption = .walking
    ) async throws -> RouteInfo {
      #logDebug("🎯 [GetRouteUseCase] 경로 검색 시작: \(option.displayName)")

        do {
            let routeInfo = try await getRoute(
                from: start,
                to: destination,
                option: option
            )

          #logDebug("✅ [GetRouteUseCase] 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
            return routeInfo
        } catch {
            #logDebug("❌ [GetRouteUseCase] 경로 검색 실패: \(error)")
            throw error
        }
    }

  public func getRoute(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    option: Entity.RouteOption
  ) async throws -> Entity.RouteInfo {
    return try await repository
      .getRoute(
        from: start,
        to: destination,
        option: option
      )
  }

  /// 외부 지도 앱으로 길찾기 시작
  public func startNavigation(
    mapType: ExternalMapType,
    destination: CLLocationCoordinate2D,
    destinationName: String
  ) async {
    #logDebug("🧭 [RouteUseCase] 길찾기 시작: \(destinationName) (\(mapType.description))")

    switch mapType {
    case .appleMap:
      await openAppleMap(destination: destination, destinationName: destinationName)

    case .googleMap:
      await openGoogleMap(lat: destination.latitude, lng: destination.longitude, destinationName: destinationName)

    case .naverMap:
      await openNaverMap(lat: destination.latitude, lng: destination.longitude, destinationName: destinationName)
    }
  }

  /// Apple 지도 앱으로 길찾기
  @MainActor
  private func openAppleMap(destination: CLLocationCoordinate2D, destinationName: String) {
    #logDebug("🍎 [RouteUseCase] Apple Maps 실행")

    let placemark = MKPlacemark(coordinate: destination)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = destinationName

    let launchOptions = [
      MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
    ]

    mapItem.openInMaps(launchOptions: launchOptions)
  }

  /// Google Maps 앱으로 길찾기
  @MainActor
  private func openGoogleMap(lat: Double, lng: Double, destinationName: String) {
    #logDebug("🌏 [RouteUseCase] Google Maps 실행")

    let googleMapsURL = "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking"

    guard let url = URL(string: googleMapsURL) else { return }

    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
    } else {
      // Google Maps 앱이 설치되어 있지 않으면 웹으로 실행
      let webURL = "https://maps.google.com/maps?daddr=\(lat),\(lng)&dirflg=w"
      guard let webURL = URL(string: webURL) else { return }
      UIApplication.shared.open(webURL)
    }
  }

  /// 네이버 지도 앱으로 길찾기
  @MainActor
  private func openNaverMap(lat: Double, lng: Double, destinationName: String) {
    #logDebug("🗺️ [RouteUseCase] 네이버지도 실행")

    let naverMapURL = "nmap://route/walk?dlat=\(lat)&dlng=\(lng)&dname=\(destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName)"

    guard let url = URL(string: naverMapURL) else { return }

    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
    } else {
      // 네이버 지도 앱이 설치되어 있지 않으면 웹으로 실행
      let webURL = "https://map.naver.com/v5/directions/-/-/\(lat),\(lng),\(destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName)?c=14,0,0,0,dh"
      guard let webURL = URL(string: webURL) else { return }
      UIApplication.shared.open(webURL)
    }
  }
}


extension RouteUseCaseImpl: DependencyKey {
  public static var liveValue  = RouteUseCaseImpl()
  public static var testValue = RouteUseCaseImpl()
  public static var previewValue = liveValue
}

public extension DependencyValues {
  var getRouteUseCase: RouteUseCaseImpl {
    get { self[RouteUseCaseImpl.self] }
    set { self[RouteUseCaseImpl.self] = newValue }
  }
}


