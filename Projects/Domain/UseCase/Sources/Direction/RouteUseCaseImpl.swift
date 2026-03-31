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
      #logDebug(" [GetRouteUseCase] 경로 검색 시작: \(option.displayName)")

        do {
            let routeInfo = try await getRoute(
                from: start,
                to: destination,
                option: option
            )

          #logDebug(" [GetRouteUseCase] 경로 검색 완료: \(routeInfo.distance)m, \(routeInfo.duration)분")
            return routeInfo
        } catch {
            #logDebug(" [GetRouteUseCase] 경로 검색 실패: \(error)")
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
    #logDebug(" [RouteUseCase] 길찾기 시작: \(destinationName) (\(mapType.description))")

    // 네이버 지도의 경우 앱 설치 여부를 먼저 확인
    if mapType == .naverMap {
      let isInstalled = await checkNaverMapInstallation()
      #logDebug(" [RouteUseCase] 네이버지도 앱 설치 상태: \(isInstalled)")
    }

    switch mapType {
    case .appleMap:
      await openAppleMap(destination: destination, destinationName: destinationName)

    case .googleMap:
      await openGoogleMap(lat: destination.latitude, lng: destination.longitude, destinationName: destinationName)

    case .naverMap:
      await openNaverMap(lat: destination.latitude, lng: destination.longitude, destinationName: destinationName)
    }
  }

  /// 네이버 지도 앱 설치 여부 확인 (강화된 디버깅)
  @MainActor
  private func checkNaverMapInstallation() -> Bool {
    let naverMapSchemes = ["nmap://", "nmapmobile://", "navermap://"]

    for scheme in naverMapSchemes {
      if let url = URL(string: scheme) {
        let canOpen = UIApplication.shared.canOpenURL(url)

        if canOpen {
          // 추가 테스트: 실제 간단한 URL로 테스트
          let testURL = scheme + "place?lat=37.5665&lng=126.9780"
          if let testUrl = URL(string: testURL) {
            let testCanOpen = UIApplication.shared.canOpenURL(testUrl)
            #logDebug(" [RouteUseCase] 테스트 URL \(testURL) canOpenURL: \(testCanOpen)")
          }

          return true
        }
      } else {
        #logDebug(" [RouteUseCase] URL 생성 실패: \(scheme)")
      }
    }

    #logDebug(" [RouteUseCase] 네이버지도 앱 미설치 (모든 스킴 실패)")

    // 설치되지 않은 경우 App Store로 이동
    let appStoreURL = "itms-apps://itunes.apple.com/app/311867728"


    if let url = URL(string: appStoreURL), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    return false
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

    let encodedName = destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName

    // 구글 지도 길찾기 URL 스킴 (바로 도보 길안내)
    let googleAppURLs = [
      // 1. 도보 길찾기 (목적지 + 이름)
      "comgooglemaps://?daddr=\(lat),\(lng)(\(encodedName))&directionsmode=walking",

      // 2. 기본 도보 길찾기
      "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking",

      // 3. 구글 지도 앱 (다른 스킴)
      "googlemaps://?daddr=\(lat),\(lng)&directionsmode=walking"
    ]

    var appOpened = false

    for urlString in googleAppURLs {
      if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
        appOpened = true
        break
      }
    }

    if !appOpened {
      // Google Maps 앱이 설치되어 있지 않으면 웹으로 실행 (길찾기 모드)
      let webURL = "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)&travelmode=walking"
      if let url = URL(string: webURL) {
        UIApplication.shared.open(url)
      }
    }
  }

  /// 네이버 지도 앱으로 길찾기 (블로그 패턴 적용)
  @MainActor
  private func openNaverMap(lat: Double, lng: Double, destinationName: String) {


    // 시뮬레이터에서는 웹으로 바로 이동
    #if targetEnvironment(simulator)
    #logDebug("⚠️ [RouteUseCase] 시뮬레이터에서는 외부 앱 연동 불가")
    openNaverMapWeb(lat: lat, lng: lng, destinationName: destinationName)
    return
    #endif

    // 길찾기 우선 실행 URL들 (바로 도보 네비게이션)
    let encodedName = destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName
    let naverMapURLs = [
      // 1. 도보 길찾기 (목적지 이름 포함) - 최우선
      "nmap://route/walk?dlat=\(lat)&dlng=\(lng)&dname=\(encodedName)",

      // 2. 네비게이션 모드 (바로 길안내)
      "nmap://navigation?dlat=\(lat)&dlng=\(lng)&dname=\(encodedName)",

      // 3. 길찾기 (일반)
      "nmap://route?dlat=\(lat)&dlng=\(lng)&dname=\(encodedName)",

      // 4. 백업: 장소 표시 (이름 포함)
      "nmap://place?lat=\(lat)&lng=\(lng)&name=\(encodedName)",

      // 5. 최종 백업: 기본 장소 표시
      "nmap://place?lat=\(lat)&lng=\(lng)",
    ]

    var appOpened = false

    for (index, urlString) in naverMapURLs.enumerated() {
      #logDebug(" [RouteUseCase] 시도 \(index + 1)/\(naverMapURLs.count): \(urlString)")

      if let openApp = URL(string: urlString),
         UIApplication.shared.canOpenURL(openApp) {
        UIApplication.shared.open(openApp, options: [:]) { success in
          Task { @MainActor in
            if !success && index == naverMapURLs.count - 1 {
              // 마지막 URL도 실패하면 웹으로 폴백
              self.openNaverMapWeb(lat: lat, lng: lng, destinationName: destinationName)
            }
          }
        }
        appOpened = true
        break // 첫 번째 성공한 URL에서 중단
      } else {
        #logDebug("[RouteUseCase] canOpenURL 실패")
      }
    }

    if !appOpened {
      let appStoreURL = "itms-apps://itunes.apple.com/app/311867728"
      if let openStore = URL(string: appStoreURL),
         UIApplication.shared.canOpenURL(openStore) {
        #logDebug(" [RouteUseCase] App Store로 이동")
        UIApplication.shared.open(openStore, options: [:], completionHandler: nil)
      } else {
        #logDebug(" [RouteUseCase] App Store 이동 실패, 웹으로 폴백")
        openNaverMapWeb(lat: lat, lng: lng, destinationName: destinationName)
      }
    }
  }


  /// 네이버 지도 웹으로 길찾기
  @MainActor
  private func openNaverMapWeb(lat: Double, lng: Double, destinationName: String) {
    // 인코딩된 목적지 이름
    let encodedName = destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName

    // 여러 웹 URL 형식 시도
    let webURLs = [
      // 1. 도보 길찾기 (정확한 형식)
      "https://map.naver.com/v5/directions/-/-,\(encodedName),\(lat),\(lng)/-/walk",

      // 2. 기본 지도에서 해당 위치 표시
      "https://map.naver.com/v5/search/\(encodedName)?c=\(lng),\(lat),15,0,0,0,dh",

      // 3. 간단한 좌표 중심 지도
      "https://map.naver.com/v5/?c=\(lng),\(lat),15,0,0,0,dh"
    ]

    // 첫 번째 유효한 URL로 실행
    for (index, urlString) in webURLs.enumerated() {
      #logDebug(" [RouteUseCase] 웹 URL 시도 \(index + 1): \(urlString)")

      if let url = URL(string: urlString) {
        UIApplication.shared.open(url, options: [:]) { success in
          Task { @MainActor in
            if success {
              #logDebug(" [RouteUseCase] 웹 열기 성공!")
            } else {
              #logDebug("❌ [RouteUseCase] 웹 열기 실패")
            }
          }
        }
        return // 첫 번째 성공한 URL로 종료
      }
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


