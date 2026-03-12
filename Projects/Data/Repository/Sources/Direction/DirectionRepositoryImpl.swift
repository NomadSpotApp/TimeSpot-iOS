//
//  DirectionRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

import DomainInterface
import Entity
import Service
import Model
import Moya
import LogMacro

import AsyncMoya

public final class DirectionRepositoryImpl: DirectionInterface, @unchecked Sendable {

  private let provider: MoyaProvider<NaverDirectionService>

  public init(
    provider: MoyaProvider<NaverDirectionService> = MoyaProvider<NaverDirectionService>.default
  ) {
    self.provider = provider
  }

  public func getRoute(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    option: RouteOption
  ) async throws -> RouteInfo {

    let startCoord = "\(start.longitude),\(start.latitude)"
    let goalCoord = "\(destination.longitude),\(destination.latitude)"

    do {
      #logDebug("🚶‍♂️ [DirectionRepositoryImpl] 하이브리드 경로 검색 (경로: 네이버 Directions 15 + 시간: Apple MapKit)")
      let multiOptions = "trafast:tracomfort:traoptimal"

      // 1. Directions 15에서 실시간 경로 좌표 가져오기
      #logDebug("📍 [DirectionRepositoryImpl] 네이버 Directions 15로 실시간 경로 조회")
      let pathResponse: NaverWalkingResponse = try await provider.request(.walking(start: startCoord, goal: goalCoord, option: multiOptions))

      // 2. Apple MapKit으로 도보 시간과 거리 계산하기
      #logDebug("⏱️ [DirectionRepositoryImpl] Apple MapKit으로 도보 시간/거리 계산")
      let appleResult = try await calculateWalkingTime(from: start, to: destination)

      // 3. 하이브리드 결과 생성: 네이버 경로 + Apple 도보 시간/거리
      return createHybridRouteWithAppleTime(pathResponse: pathResponse, appleResult: appleResult)

    } catch {
      #logDebug("❌ [DirectionRepositoryImpl] 하이브리드 경로 검색 실패: \(error)")
      throw DirectionError.from(error)
    }
  }

  /// Apple MapKit으로 정확한 도보 시간과 거리 계산
  private func calculateWalkingTime(
    from start: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D
  ) async throws -> (duration: Double, distance: Double) {

    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
    request.transportType = .walking  // 🚶‍♂️ 도보 모드

    let directions = MKDirections(request: request)

    do {
      let response = try await directions.calculate()
      let route = response.routes.first
      let durationInMinutes = (route?.expectedTravelTime ?? 0) / 60  // 초를 분으로 변환
      let distanceInMeters = route?.distance ?? 0  // 미터 단위

      #logDebug("🍎 [Apple MapKit] 도보 시간: \(durationInMinutes)분, 거리: \(distanceInMeters)m")
      return (duration: durationInMinutes, distance: distanceInMeters)

    } catch {
      #logDebug("❌ [Apple MapKit] 도보 시간/거리 계산 실패: \(error)")
      throw DirectionError.invalidResponse
    }
  }

  /// 네이버 경로 + Apple 도보 시간/거리 하이브리드 결과 생성
  private func createHybridRouteWithAppleTime(
    pathResponse: NaverWalkingResponse,
    appleResult: (duration: Double, distance: Double)
  ) -> RouteInfo {
    // 네이버 Directions 15에서 경로 좌표 추출
    let pathRouteInfo = pathResponse.toDomain()
    let naverDistance = pathRouteInfo?.distance ?? 0
    let naverDuration = pathRouteInfo?.duration ?? 0
    let appleDistance = Int(appleResult.distance)
    let appleDuration = Int(appleResult.duration)

    // 📊 상세 비교 로그
    #logDebug("==================================================")
    #logDebug("📍 [네이버 Directions 15] 거리: \(naverDistance)m, 시간: \(naverDuration)분")
    #logDebug("🍎 [Apple MapKit] 거리: \(appleDistance)m, 시간: \(appleDuration)분")
    #logDebug("==")

    // 하이브리드 결과: 네이버 경로 + Apple 도보 시간/거리
    let finalResult = RouteInfo(
      paths: pathRouteInfo?.paths ?? [],           // 네이버 실시간 경로
      distance: naverDistance,                     // Apple 거리
      duration: appleDuration,                     // Apple 도보 시간 
      tollFare: 0,
      taxiFare: 0
    )

    #logDebug("✨ [최종 결과] 경로+거리: 네이버 (\(naverDistance)m), 시간: Apple (\(appleDuration)분)")
    return finalResult
  }

}


