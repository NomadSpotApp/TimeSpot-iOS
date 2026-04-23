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
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity

  func fetchInitialExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> ExploreSpotPageEntity

  func searchExploreSpots(
    baseSpots: [ExploreMapSpot],
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity

  // MARK: - Cache APIs (cache-then-network)

  func loadCachedPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity?

  func loadCachedExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity?

  func loadCachedDetailPlace(
    userSession: UserSession,
    placeId: Int
  ) async throws -> PlaceDetailEntity?
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

    // 체류시간 계산을 위한 추정 도보시간 (좌표 기반으로 계산)
    let userLat = resolvedLocation?.coordinate.latitude ?? userSession.travelStationLat ?? 0
    let userLon = resolvedLocation?.coordinate.longitude ?? userSession.travelStationLng ?? 0

    // 역 좌표와 사용자 현재 위치 사이의 거리로 추정 도보시간 계산 (1분/67m 기준)
    let stationLat = userSession.travelStationLat ?? 0
    let stationLon = userSession.travelStationLng ?? 0
    let estimatedWalkTime = calculateEstimatedWalkTime(
      fromLat: stationLat,
      fromLon: stationLon,
      toLat: userLat,
      toLon: userLon
    )

    // 체류 가능 시간 계산
    let calculatedStayableMinutes = calculateStayableMinutes(
      remainingMinutes: userSession.remainingMinutes,
      walkTimeFromStation: estimatedWalkTime
    )

    let input = PlaceDetailInput(
      placeId: placeId,
      stationId: Int(userSession.travelID) ?? 0,
      userLat: userLat,
      userLon: userLon,
      remainingMinutes: calculatedStayableMinutes
    )

    return try await repository.detailPlaces(input)
  }

  public func fetchPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity {
    let input = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: userSession.remainingMinutes,
      keyword: keyword,
      category: mapCategory(category),
      mapLat: mapLat,
      mapLon: mapLon,
      page: page, // 서버도 1-based 페이지 사용
      size: 50,
      sort: sort
    )

    #logDebug("🌐 [API요청] fetchPlaces - page=\(page), size=50")

    return try await repository.fetchPlaces(input)
  }

  public func fetchInitialExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double
  ) async throws -> ExploreSpotPageEntity {
    // 🚀 단순화: fetchPlaces API 하나만 사용
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: userSession.remainingMinutes,
      keyword: nil,
      category: nil,
      mapLat: userSession.travelStationLat,
      mapLon: userSession.travelStationLng,
      page: 1, // 서버도 1-based 페이지 사용
      size: 200,
      sort: "distanceFromStation,ASC"
    )

    #logDebug("🚀 [초기로딩] fetchPlaces - page=1, size=200")

    let pageEntity = try await repository.fetchPlaces(searchInput)

    #logDebug("🚀 [초기로딩] fetchPlaces 응답: \(pageEntity.content.count)개")

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
      currentPage: pageEntity.page,
      hasNextPage: !pageEntity.isLastPage
    )
  }


  public func searchExploreSpots(
    baseSpots: [ExploreMapSpot],
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity {
    // 🔍 단순화: fetchPlaces API 하나만 사용
    let searchInput = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: userSession.remainingMinutes,
      keyword: keyword,
      category: mapCategory(category),
      mapLat: mapLat,
      mapLon: mapLon,
      page: page, // 서버도 1-based 페이지 사용
      size: 50,
      sort: sort
    )

    #logDebug("🔍 [API요청] searchExploreSpots - page=\(page), size=50")

    let pageEntity = try await repository.fetchPlaces(searchInput)

    #logDebug("🔍 [API응답] searchExploreSpots - 응답 size: \(pageEntity.content.count), hasNext: \(!pageEntity.isLastPage)")

    #logDebug("🔍 [필터링] fetchPlaces 응답: \(pageEntity.content.count)개")

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
      currentPage: pageEntity.page,
      hasNextPage: !pageEntity.isLastPage
    )
  }

  // MARK: - Cache APIs

  public func loadCachedPlaces(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> PlaceSearchPageEntity? {
    let input = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: userSession.remainingMinutes,
      keyword: keyword,
      category: mapCategory(category),
      mapLat: mapLat,
      mapLon: mapLon,
      page: page,
      size: 50,
      sort: sort
    )
    return try await repository.loadCachedPlaces(input)
  }

  public func loadCachedExploreSpots(
    userSession: UserSession,
    userLat: Double,
    userLon: Double,
    keyword: String?,
    category: ExploreCategory?,
    sort: String,
    mapLat: Double?,
    mapLon: Double?,
    page: Int
  ) async throws -> ExploreSpotPageEntity? {
    let input = PlaceSearchInput(
      userLat: userLat,
      userLon: userLon,
      stationId: Int(userSession.travelID) ?? 0,
      remainingMinutes: userSession.remainingMinutes,
      keyword: keyword,
      category: mapCategory(category),
      mapLat: mapLat ?? userSession.travelStationLat,
      mapLon: mapLon ?? userSession.travelStationLng,
      page: page,
      size: page == 1 && keyword == nil && category == nil ? 200 : 50,
      sort: sort
    )

    guard let pageEntity = try await repository.loadCachedPlaces(input) else {
      return nil
    }

    let spots = pageEntity.content.map { entity in
      makeDetailSpot(
        from: entity,
        coordinate: CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon),
        stationName: userSession.travelStationName,
        stationLat: userSession.travelStationLat,
        stationLon: userSession.travelStationLng
      )
    }

    return ExploreSpotPageEntity(
      spots: spots,
      currentPage: pageEntity.page,
      hasNextPage: !pageEntity.isLastPage
    )
  }

  public func loadCachedDetailPlace(
    userSession: UserSession,
    placeId: Int
  ) async throws -> PlaceDetailEntity? {
    let resolvedLocation = try? await locationUseCase.requestCurrentLocation()
    let userLat = resolvedLocation?.coordinate.latitude ?? userSession.travelStationLat ?? 0
    let userLon = resolvedLocation?.coordinate.longitude ?? userSession.travelStationLng ?? 0
    let stationLat = userSession.travelStationLat ?? 0
    let stationLon = userSession.travelStationLng ?? 0
    let estimatedWalkTime = calculateEstimatedWalkTime(
      fromLat: stationLat,
      fromLon: stationLon,
      toLat: userLat,
      toLon: userLon
    )
    let calculatedStayableMinutes = calculateStayableMinutes(
      remainingMinutes: userSession.remainingMinutes,
      walkTimeFromStation: estimatedWalkTime
    )
    let input = PlaceDetailInput(
      placeId: placeId,
      stationId: Int(userSession.travelID) ?? 0,
      userLat: userLat,
      userLon: userLon,
      remainingMinutes: calculatedStayableMinutes
    )
    return try await repository.loadCachedDetailPlace(input)
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
    case .some(.shopping):
      return "쇼핑"
    case .some(.etc):
      return "기타"
    }
  }

  private func makeBaseSpot(from entity: PlaceEntity) -> ExploreMapSpot {
    return ExploreMapSpot(
      id: String(entity.placeId),
      name: "",
      category: entity.category,
      coordinate: CLLocationCoordinate2D(latitude: entity.lat, longitude: entity.lon),
      hasDetail: false,
      imageURL: entity.imageURL,
      badgeText: "\(entity.stayableMinutes)분 체류 가능",
      subtitle: entity.category.title,
      statusText: "",
      closingText: "",
      distanceText: "",
      walkTimeText: "",
      address: entity.address,
      visitable: entity.visitable,
      stayableMinutes: entity.stayableMinutes
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

    if let distanceFromStation = entity.distanceFromStation {
      let roundedDistance = Int(distanceFromStation.rounded())
      distanceText = "\(roundedDistance)m"
    } else if let stationLat, let stationLon {
      let stationLocation = CLLocation(latitude: stationLat, longitude: stationLon)
      let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let distanceInMeters = stationLocation.distance(from: placeLocation)
      let roundedDistance = Int((distanceInMeters / 10).rounded() * 10)
      distanceText = "\(roundedDistance)m"
    } else {
      distanceText = ""
    }

    if let walkTime = entity.walkTimeFromStation {
      walkTimeText = "\(stationName)역에서 약 \(walkTime)분"
    } else if let stationLat, let stationLon, distanceText.isEmpty == false {
      let stationLocation = CLLocation(latitude: stationLat, longitude: stationLon)
      let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let distanceInMeters = stationLocation.distance(from: placeLocation)
      let walkingMinutes = max(Int(ceil(distanceInMeters / 67)), 1)
      walkTimeText = "\(stationName)역에서 약 \(walkingMinutes)분"
    } else {
      walkTimeText = ""
    }

    return ExploreMapSpot(
      id: String(entity.placeId),
      name: entity.name,
      category: entity.category,
      coordinate: coordinate,
      hasDetail: true,
      imageURL: entity.imageURL,
      badgeText: "\(entity.stayableMinutes)분 체류 가능",
      subtitle: entity.category.title,
      statusText: entity.visitable ? "영업 중" : "영업 종료",
      closingText: closingText,
      distanceText: distanceText,
      walkTimeText: walkTimeText,
      address: entity.address,
      visitable: entity.visitable,
      stayableMinutes: entity.stayableMinutes
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

  /// 좌표 기반 추정 도보시간 계산
  /// - Parameters:
  ///   - fromLat: 출발지 위도
  ///   - fromLon: 출발지 경도
  ///   - toLat: 목적지 위도
  ///   - toLon: 목적지 경도
  /// - Returns: 추정 도보시간 (분)
  private func calculateEstimatedWalkTime(
    fromLat: Double,
    fromLon: Double,
    toLat: Double,
    toLon: Double
  ) -> Int {
    let fromLocation = CLLocation(latitude: fromLat, longitude: fromLon)
    let toLocation = CLLocation(latitude: toLat, longitude: toLon)
    let distanceInMeters = fromLocation.distance(from: toLocation)

    // 도보 속도: 1분당 67m (평균 도보 속도 4km/h 기준)
    let walkingMinutes = max(Int(ceil(distanceInMeters / 67)), 1)
    return walkingMinutes
  }

  /// 체류 시간 계산 로직
  /// - Parameters:
  ///   - remainingMinutes: 전체 잔여 시간
  ///   - walkTimeFromStation: 편도 도보 시간
  /// - Returns: 실제 체류 가능 시간
  private func calculateStayableMinutes(
    remainingMinutes: Int,
    walkTimeFromStation: Int
  ) -> Int {
    // 왕복 도보 시간 = 편도 도보 시간 × 2
    let roundTripWalkTime = walkTimeFromStation * 2

    // 플랫폼 대기 시간 = 10분 (고정)
    let platformWaitTime = 10

    // 체류 가능 시간 = 남은 시간 - 왕복 도보 시간 - 플랫폼 대기 시간
    let stayableTime = remainingMinutes - roundTripWalkTime - platformWaitTime

    // 음수가 될 수 없으므로 0 이상으로 제한
    return max(0, stayableTime)
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
