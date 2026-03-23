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

  // MARK: - Constants
  private enum Constants {
    static let secondsPerMinute: Double = 60.0
    static let multiOptions = "trafast:tracomfort:traoptimal"
  }

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
      #logDebug(" [DirectionRepositoryImpl] 하이브리드 경로 검색 (경로: 네이버 Directions 15 + 시간: Apple MapKit)")

      // 1-2. 병렬로 네이버 API와 Apple MapKit 호출 (성능 개선)
      #logDebug(" [DirectionRepositoryImpl] 병렬 API 호출 시작")
      async let pathResponse: NaverWalkingResponse = provider.request(.walking(start: startCoord, goal: goalCoord, option: Constants.multiOptions))
      async let appleResult = calculateWalkingTime(from: start, to: destination)

      #logDebug(" [DirectionRepositoryImpl] 네이버 Directions 15로 실시간 경로 조회")
      #logDebug(" [DirectionRepositoryImpl] Apple MapKit으로 도보 시간/거리 계산")
      let (naverResponse, appleData) = try await (pathResponse, appleResult)

      // 3. 하이브리드 결과 생성: 네이버 경로 + Apple 도보 시간/거리
      return createHybridRouteWithAppleTime(pathResponse: naverResponse, appleResult: appleData)

    } catch let moyaError as MoyaError {
      #logDebug(" [MoyaError] 네이버 API 호출 실패: \(moyaError.localizedDescription)")
      throw DirectionError.from(moyaError)
    } catch {
      #logDebug(" [UnknownError] 하이브리드 경로 검색 실패: \(error)")
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
    request.transportType = .walking  // ‍♂️ 도보 모드

    let directions = MKDirections(request: request)

    do {
      let response = try await directions.calculate()
      let route = response.routes.first
      let durationInMinutes = (route?.expectedTravelTime ?? 0) / Constants.secondsPerMinute
      let distanceInMeters = route?.distance ?? 0  // 미터 단위

      #logDebug(" [Apple MapKit] 도보 시간: \(durationInMinutes)분, 거리: \(distanceInMeters)m")
      return (duration: durationInMinutes, distance: distanceInMeters)

    } catch let mkError as MKError {
      #logDebug(" [MKError] Apple MapKit 경로 계산 실패: \(mkError.localizedDescription)")
      throw DirectionError.invalidResponse
    } catch {
      #logDebug(" [UnknownError] Apple MapKit 계산 실패: \(error)")
      throw DirectionError.invalidResponse
    }
  }

  /// 네이버 경로 + Apple 도보 시간/거리 하이브리드 결과 생성
  private func createHybridRouteWithAppleTime(
    pathResponse: NaverWalkingResponse,
    appleResult: (duration: Double, distance: Double)
  ) -> RouteInfo {
    let (naverInfo, appleInfo) = extractRouteData(from: pathResponse, and: appleResult)
    logRouteComparison(naver: naverInfo, apple: appleInfo)
    return buildFinalRoute(naverInfo: naverInfo, appleInfo: appleInfo)
  }

  /// 네이버와 Apple 경로 데이터 추출
  private func extractRouteData(
    from pathResponse: NaverWalkingResponse,
    and appleResult: (duration: Double, distance: Double)
  ) -> (naver: (distance: Int, duration: Int, paths: [CLLocationCoordinate2D]), apple: (distance: Int, duration: Int)) {
    let pathRouteInfo = pathResponse.toDomain()
    let naverInfo = (
      distance: pathRouteInfo?.distance ?? 0,
      duration: pathRouteInfo?.duration ?? 0,
      paths: pathRouteInfo?.paths ?? []
    )
    let appleInfo = (
      distance: Int(appleResult.distance),
      duration: Int(appleResult.duration)
    )
    return (naverInfo, appleInfo)
  }

  /// 네이버와 Apple 경로 비교 로그
  private func logRouteComparison(
    naver: (distance: Int, duration: Int, paths: [CLLocationCoordinate2D]),
    apple: (distance: Int, duration: Int)
  ) {
    #logDebug("==================================================")
    #logDebug("[네이버 Directions 15] 거리: \(naver.distance)m, 시간: \(naver.duration)분")
    #logDebug(" [Apple MapKit] 거리: \(apple.distance)m, 시간: \(apple.duration)분")
    #logDebug("==")
  }

  /// 최종 하이브리드 RouteInfo 생성
  private func buildFinalRoute(
    naverInfo: (distance: Int, duration: Int, paths: [CLLocationCoordinate2D]),
    appleInfo: (distance: Int, duration: Int)
  ) -> RouteInfo {
    let finalResult = RouteInfo(
      paths: naverInfo.paths,                      // 네이버 실시간 경로
      distance: naverInfo.distance,                // 네이버 거리
      duration: appleInfo.duration,                // Apple 도보 시간
      tollFare: 0,
      taxiFare: 0
    )

    #logDebug("✨ [최종 결과] 경로+거리: 네이버 (\(naverInfo.distance)m), 시간: Apple (\(appleInfo.duration)분)")
    return finalResult
  }

}


