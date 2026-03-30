//
//  StationRowModel.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation
import Entity
import Utill
import IdentifiedCollections

public struct StationRowModel: Identifiable, Equatable, Hashable {
  public let stationEntity: StationEntity
  public let distanceText: String?

  // UI 편의 속성들
  public var id: String {
    "\(rowType)-\(stationEntity.id)"
  }
  public var favoriteID: Int? {
    stationEntity.favoriteID
  }
  public var station: Station? {
    stationEntity.station
  }
  public var stationID: Int {
    stationEntity.id
  }
  public var stationName: String {
    stationEntity.name
  }
  public var badges: [String] {
    stationEntity.badges
  }
  public var lat: Double? {
    stationEntity.latitude
  }
  public var lng: Double? {
    stationEntity.longitude
  }
  public var isFavorite: Bool {
    stationEntity.isFavorite
  }

  private let rowType: String

  public init(
    stationEntity: StationEntity,
    distanceText: String? = nil,
    rowType: String = "station"
  ) {
    self.stationEntity = stationEntity
    self.distanceText = distanceText
    self.rowType = rowType
  }

  // 편의 생성자 (기존 코드 호환성을 위해)
  public init(
    id: String,
    favoriteID: Int? = nil,
    station: Station?,
    stationID: Int,
    stationName: String,
    badges: [String],
    lat: Double? = nil,
    lng: Double? = nil,
    distanceText: String?,
    isFavorite: Bool
  ) {
    let entity = StationEntity(
      id: stationID,
      favoriteID: favoriteID,
      station: station,
      name: stationName,
      badges: badges,
      latitude: lat,
      longitude: lng,
      isFavorite: isFavorite
    )

    let rowType = id.components(separatedBy: "-").first ?? "station"

    self.init(
      stationEntity: entity,
      distanceText: distanceText,
      rowType: rowType
    )
  }
}

// MARK: - Mapping Functions
extension StationRowModel {
  static func makeFavoriteRows(from stations: [StationSummaryEntity]) -> IdentifiedArrayOf<StationRowModel> {
    let uniqueStations = Array(
      Dictionary(
        stations.map { station in
          (station.name.normalizedStationName, station)
        },
        uniquingKeysWith: { first, _ in first }
      ).values
    )
    .sorted { $0.name.normalizedStationName < $1.name.normalizedStationName }

    let rows = uniqueStations.map { station in
      let normalizedName = station.name.normalizedStationName
      let stationEnum = Station(displayName: normalizedName)
      let displayName = stationEnum?.displayName ?? normalizedName

      let entity = StationEntity(
        id: station.stationID,
        favoriteID: station.favoriteID ?? station.stationID,
        station: stationEnum,
        name: displayName,
        badges: station.lines,
        latitude: station.lat,
        longitude: station.lng,
        isFavorite: true
      )

      return StationRowModel(
        stationEntity: entity,
        distanceText: nil,
        rowType: "favorite"
      )
    }

    return IdentifiedArray(uniqueElements: rows)
  }

  static func makeNearbyRows(from stations: [StationSummaryEntity]) -> IdentifiedArrayOf<StationRowModel> {
    let rows = Array(stations.sorted { $0.name.normalizedStationName < $1.name.normalizedStationName }.prefix(3)).map { station in
      let normalizedName = station.name.normalizedStationName
      let stationEnum = Station(displayName: normalizedName)
      let displayName = stationEnum?.displayName ?? normalizedName

      let entity = StationEntity(
        id: station.stationID,
        favoriteID: nil,
        station: stationEnum,
        name: displayName,
        badges: station.lines,
        latitude: station.lat,
        longitude: station.lng,
        isFavorite: false
      )

      return StationRowModel(
        stationEntity: entity,
        distanceText: "2.3km",
        rowType: "nearby"
      )
    }

    return IdentifiedArray(uniqueElements: rows)
  }

  static func makeMajorRows(from stations: [StationSummaryEntity]) -> IdentifiedArrayOf<StationRowModel> {
    let rows = stations
      .sorted { $0.name.normalizedStationName < $1.name.normalizedStationName }
      .map { station in
      let normalizedName = station.name.normalizedStationName
      let stationEnum = Station(displayName: normalizedName)
      let displayName = stationEnum?.displayName ?? normalizedName

      let entity = StationEntity(
        id: station.stationID,
        favoriteID: nil,
        station: stationEnum,
        name: displayName,
        badges: station.lines,
        latitude: station.lat,
        longitude: station.lng,
        isFavorite: false
      )

      return StationRowModel(
        stationEntity: entity,
        distanceText: nil,
        rowType: "station"
      )
    }

    return IdentifiedArray(uniqueElements: rows)
  }

  // 비회원용 기본 주요 역 데이터
  static func makeDefaultMajorStations() -> IdentifiedArrayOf<StationRowModel> {
    let defaultStations = [
      ("강남", 1, Station.gangnam, ["2호선", "신분당선"]),
      ("홍대입구", 2, Station.hongdaeEntrance, ["2호선", "6호선", "공항철도"]),
      ("신촌", 3, Station.sinchon, ["2호선"]),
      ("이태원", 4, Station.itaewon, ["6호선"]),
      ("명동", 5, Station.myeongdong, ["4호선"]),
      ("건대입구", 6, Station.konkukUniversityEntrance, ["2호선", "7호선"]),
      ("잠실", 7, Station.jamsil, ["2호선", "8호선"]),
      ("종각", 8, Station.jonggak, ["1호선"]),
      ("고속터미널", 9, Station.expressBusTerminal, ["3호선", "7호선", "9호선"]),
      ("노원", 10, Station.nowon, ["4호선", "7호선"])
    ]

    let rows = defaultStations.map { (name, id, station, badges) in
      let entity = StationEntity(
        id: id,
        favoriteID: nil,
        station: station,
        name: name,
        badges: badges,
        latitude: nil,
        longitude: nil,
        isFavorite: false
      )

      return StationRowModel(
        stationEntity: entity,
        distanceText: nil,
        rowType: "station"
      )
    }

    return IdentifiedArray(uniqueElements: rows)
  }

  static func applyFavoriteState(
    favoriteRows: IdentifiedArrayOf<StationRowModel>,
    nearbyRows: inout IdentifiedArrayOf<StationRowModel>,
    majorRows: inout IdentifiedArrayOf<StationRowModel>
  ) {
    let favoriteNameMap: [String: Int] = Dictionary(
      uniqueKeysWithValues: favoriteRows.compactMap { row -> (String, Int)? in
        let identifier = row.favoriteID ?? row.stationID
        return (row.stationName.normalizedStationName, identifier)
      }
    )

    let updatedNearbyRows = nearbyRows.map { row in
      let favoriteID = favoriteNameMap[row.stationName.normalizedStationName]

      let updatedEntity = StationEntity(
        id: row.stationEntity.id,
        favoriteID: favoriteID,
        station: row.stationEntity.station,
        name: row.stationEntity.name,
        badges: row.stationEntity.badges,
        latitude: row.stationEntity.latitude,
        longitude: row.stationEntity.longitude,
        isFavorite: favoriteID != nil
      )

      return StationRowModel(
        stationEntity: updatedEntity,
        distanceText: row.distanceText,
        rowType: "nearby"
      )
    }
    nearbyRows = IdentifiedArray(uniqueElements: updatedNearbyRows)

    let updatedMajorRows = majorRows.map { row in
      let favoriteID = favoriteNameMap[row.stationName.normalizedStationName]

      let updatedEntity = StationEntity(
        id: row.stationEntity.id,
        favoriteID: favoriteID,
        station: row.stationEntity.station,
        name: row.stationEntity.name,
        badges: row.stationEntity.badges,
        latitude: row.stationEntity.latitude,
        longitude: row.stationEntity.longitude,
        isFavorite: favoriteID != nil
      )

      return StationRowModel(
        stationEntity: updatedEntity,
        distanceText: row.distanceText,
        rowType: "station"
      )
    }
    majorRows = IdentifiedArray(uniqueElements: updatedMajorRows)
  }
}
