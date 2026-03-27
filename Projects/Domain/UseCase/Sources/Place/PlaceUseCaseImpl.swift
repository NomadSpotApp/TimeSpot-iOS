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

public protocol PlaceUseCaseInterface: Sendable {
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
    markerLat: Double?,
    markerLon: Double?,
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
    markerLat: Double?,
    markerLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity
}

public struct PlaceUseCaseImpl: PlaceUseCaseInterface {
  @Dependency(\.placeRepository) var repository

  public init() {}

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
    let placeInput = PlaceInput(
      userLat: userLat,
      userLon: userLon,
      mapLat: userSession.travelStationLat ?? 0,
      mapLon: userSession.travelStationLng ?? 0,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250
    )
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250,
      keyword: nil,
      category: nil,
      sortBy: "MARKER_NEAREST",
      markerLat: userSession.travelStationLat,
      markerLon: userSession.travelStationLng,
      page: 1,
      size: 10
    )

    async let markerEntities = repository.fetchPlaces(placeInput)
    async let detailPage = repository.searchPlaces(searchInput)

    let fetchedMarkerEntities = try await markerEntities
    let fetchedDetailPage = try await detailPage

    let mergedSpots = mergeSpots(
      baseSpots: fetchedMarkerEntities.map { makeBaseSpot(from: $0) },
      detailPage: fetchedDetailPage,
      stationName: userSession.travelStationName,
      stationLat: userSession.travelStationLat,
      stationLon: userSession.travelStationLng
    )

    return ExploreSpotPageEntity(
      spots: mergedSpots,
      currentPage: fetchedDetailPage.page + 1,
      hasNextPage: !fetchedDetailPage.isLastPage
    )
  }

  public func searchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sortBy: String = "MARKER_NEAREST",
    markerLat: Double?,
    markerLon: Double?,
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
      markerLat: markerLat,
      markerLon: markerLon,
      page: page,
      size: 10
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
    sortBy: String = "MARKER_NEAREST",
    markerLat: Double?,
    markerLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity {
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: 250,
      keyword: keyword,
      category: mapCategory(category),
      sortBy: sortBy,
      markerLat: markerLat,
      markerLon: markerLon,
      page: page,
      size: 10
    )

    let pageEntity = try await repository.searchPlaces(searchInput)
    let mergedSpots = mergeSpots(
      baseSpots: baseSpots,
      detailPage: pageEntity,
      stationName: userSession.travelStationName,
      stationLat: userSession.travelStationLat,
      stationLon: userSession.travelStationLng
    )

    return ExploreSpotPageEntity(
      spots: mergedSpots,
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
      walkTimeText: ""
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
      walkTimeText: walkTimeText
    )
  }

  private func mergeSpots(
    baseSpots: [ExploreMapSpot],
    detailPage: PlaceSearchPageEntity,
    stationName: String,
    stationLat: Double?,
    stationLon: Double?
  ) -> [ExploreMapSpot] {
    var mergedSpots = baseSpots

    for entity in detailPage.content {
      let id = String(entity.placeId)
      let coordinate = mergedSpots.first(where: { $0.id == id })?.coordinate
        ?? CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon)
      let detailSpot = makeDetailSpot(
        from: entity,
        coordinate: coordinate,
        stationName: stationName,
        stationLat: stationLat,
        stationLon: stationLon
      )

      if let index = mergedSpots.firstIndex(where: { $0.id == id }) {
        mergedSpots[index] = detailSpot
      } else {
        mergedSpots.append(detailSpot)
      }
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
