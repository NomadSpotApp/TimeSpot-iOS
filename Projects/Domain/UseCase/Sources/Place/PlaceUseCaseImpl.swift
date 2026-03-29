//
//  PlaceUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh  on 3/27/26.
//

import DomainInterface
import Entity

import ComposableArchitecture
import CoreLocation
import Utill
import LogMacro

public protocol PlaceUseCaseInterface: Sendable {
  func detailPlace(
    userSession: UserSession,
    placeId: Int
  ) async throws -> PlaceDetailEntity

  func fetchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> [PlaceEntity]

  func fetchInitialExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> ExploreSpotPageEntity

  func searchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sortBy: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity

  func searchExploreSpots(
    baseSpots: [ExploreMapSpot],
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sortBy: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity
}

public struct PlaceUseCaseImpl: PlaceUseCaseInterface {
  @Dependency(\.placeRepository) var repository
  @Dependency(\.locationUseCase) var locationUseCase

  public init() {}

  public func detailPlace(
    userSession: UserSession,
    placeId: Int
  ) async throws -> PlaceDetailEntity {
    let resolvedLocation: CLLocation?
    do {
      resolvedLocation = try await locationUseCase.requestCurrentLocation()
    } catch {
      resolvedLocation = nil
    }

    let input = PlaceDetailInput(
      placeId: placeId,
      stationId: Int(userSession.travelID) ?? 0,
      userLat: resolvedLocation?.coordinate.latitude ?? userSession.travelStationLat ?? 0,
      userLon: resolvedLocation?.coordinate.longitude ?? userSession.travelStationLng ?? 0,
      remainingMinutes: 250
    )

    return try await repository.detailPlaces(input)
  }

  public func fetchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> [PlaceEntity] {
    let input = PlaceInput(
      userLat: userLat,
      userLon: userLon,
      mapLat: userSession.travelStationLat ?? 0,
      mapLon: userSession.travelStationLng ?? 0,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250
    )

    return try await repository.fetchPlaces(input)
  }

  public func fetchInitialExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> ExploreSpotPageEntity {
    // 🚀 단순화: searchPlaces API 하나만 사용
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250,
      keyword: nil,
      category: nil,
      sortBy: "STATION_NEAREST",
      mapLat: userSession.travelStationLat,
      mapLon: userSession.travelStationLng,
      page: 0,
      size: 200,
      sort: ["MAP_NEAREST"]
    )

    let pageEntity = try await repository.searchPlaces(searchInput)

    #logDebug("🚀 [초기로딩] searchPlaces 응답: \(pageEntity.content.count)개")

    // 직접 마커 생성 (병합 없이)
    let spots = pageEntity.content.map { entity in
      makeDetailSpot(
        from: entity,
        coordinate: CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon),
        stationName: userSession.travelStationName,
        stationLat: userSession.travelStationLat,
        stationLon: userSession.travelStationLng
      )
    }

    #logDebug("🚀 [초기로딩] 최종 spots: \(spots.count)개")

    return ExploreSpotPageEntity(
      spots: spots,
      currentPage: pageEntity.page + 1,
      hasNextPage: !pageEntity.isLastPage
    )
  }

  public func searchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sortBy: String = "STATION_NEAREST",
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity {
    let input = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250,
      keyword: keyword,
      category: mapCategory(category),
      sortBy: sortBy,
      mapLat: mapLat,
      mapLon: mapLon,
      page: page,
      size: 200,
      sort: ["MAP_NEAREST"]
    )

    return try await repository.searchPlaces(input)
  }

  public func searchExploreSpots(
    baseSpots: [ExploreMapSpot],
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sortBy: String = "STATION_NEAREST",
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity {
    // 🔍 단순화: searchPlaces API 하나만 사용
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250,
      keyword: keyword,
      category: mapCategory(category),
      sortBy: sortBy,
      mapLat: mapLat,
      mapLon: mapLon,
      page: page,
      size: 30  // 더 많은 데이터 로딩
    )

    #logDebug("🔍 [API요청] searchExploreSpots - page: \(page), size: 30")

    let pageEntity = try await repository.searchPlaces(searchInput)

    #logDebug("🔍 [API응답] searchExploreSpots - 응답 size: \(pageEntity.content.count), hasNext: \(!pageEntity.isLastPage)")

    #logDebug("🔍 [필터링] searchPlaces 응답: \(pageEntity.content.count)개")

    // 직접 마커 생성 (병합 없이)
    let spots = pageEntity.content.map { entity in
      makeDetailSpot(
        from: entity,
        coordinate: CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon),
        stationName: userSession.travelStationName,
        stationLat: userSession.travelStationLat,
        stationLon: userSession.travelStationLng
      )
    }

    #logDebug("🔍 [필터링] 최종 spots: \(spots.count)개")

    return ExploreSpotPageEntity(
      spots: spots,
      currentPage: pageEntity.page + 1,
      hasNextPage: !pageEntity.isLastPage
    )
  }

  private func mapCategory(_ category: ExploreCategory?) -> String? {
    switch category {
    case .none, .some(.all):
      return nil
    case .some(.cafe):
      return "카페"
    case .some(.restaurant):
      return "음식점"
    case .some(.activity):
      return "액티비티"
    case .some(.etc):
      return "기타"
    }
  }

  private func makeBaseSpot(from entity: PlaceEntity) -> ExploreMapSpot {
    ExploreMapSpot(
      id: String(entity.placeId),
      name: "",
      category: entity.category,
      coordinate: CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon),
      hasDetail: false,
      imageURL: entity.imageURL,
      badgeText: "",
      subtitle: entity.category.title,
      statusText: "",
      closingText: "",
      distanceText: "",
      walkTimeText: "",
      address: entity.address
    )
  }

  private func makeDetailSpot(
    from entity: PlaceEntity,
    coordinate: CLLocationCoordinate2D,
    stationName: String,
    stationLat: Double?,
    stationLon: Double?
  ) -> ExploreMapSpot {
    let closingText: String
    if let closingTime = entity.closingTime, !closingTime.isEmpty {
      closingText = closingTime.formattedClosingTimeText()
    } else {
      closingText = entity.address
    }

    let distanceText: String
    let walkTimeText: String

    if let stationLat, let stationLon {
      let stationLocation = CLLocation(latitude: stationLat, longitude: stationLon)
      let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let distanceInMeters = stationLocation.distance(from: placeLocation)
      let roundedDistance = Int((distanceInMeters / 10).rounded() * 10)
      let walkingMinutes = max(Int(ceil(distanceInMeters / 67)), 1)

      distanceText = "\(roundedDistance)m"
      walkTimeText = "\(stationName)역에서 약 \(walkingMinutes)분"
    } else {
      distanceText = ""
      walkTimeText = ""
    }

    return ExploreMapSpot(
      id: String(entity.placeId),
      name: entity.name,
      category: entity.category,
      coordinate: coordinate,
      hasDetail: true,
      imageURL: entity.imageURL,
      badgeText: entity.stayableMinutes > 0 ? "\(entity.stayableMinutes)분 체류 가능" : "",
      subtitle: entity.category.title,
      statusText: entity.isOpen ? "영업 중" : "영업 종료",
      closingText: closingText,
      distanceText: distanceText,
      walkTimeText: walkTimeText,
      address: entity.address
    )
  }

  private func mergeSpots(
    baseSpots: [ExploreMapSpot],
    detailPage: PlaceSearchPageEntity,
    stationName: String,
    stationLat: Double?,
    stationLon: Double?
  ) -> [ExploreMapSpot] {
    let baseSpotsByID = Dictionary(uniqueKeysWithValues: baseSpots.map { ($0.id, $0) })
    var mergedSpots: [ExploreMapSpot] = []
    var resolvedIDs = Set<String>()

    for entity in detailPage.content {
      let id = String(entity.placeId)
      let coordinate = baseSpotsByID[id]?.coordinate
        ?? CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon)
      let detailSpot = makeDetailSpot(
        from: entity,
        coordinate: coordinate,
        stationName: stationName,
        stationLat: stationLat,
        stationLon: stationLon
      )

      mergedSpots.append(detailSpot)
      resolvedIDs.insert(id)
    }

    for baseSpot in baseSpots where !resolvedIDs.contains(baseSpot.id) {
      mergedSpots.append(baseSpot)
    }

    return mergedSpots
  }
}

extension PlaceUseCaseImpl: DependencyKey {
  public static var liveValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
  public static var testValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
  public static var previewValue: PlaceUseCaseInterface = PlaceUseCaseImpl()
}

public extension DependencyValues {
  var placeUseCase: PlaceUseCaseInterface {
    get { self[PlaceUseCaseImpl.self] }
    set { self[PlaceUseCaseImpl.self] = newValue }
  }
}
