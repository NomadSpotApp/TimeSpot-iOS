//
//  StationService.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum StationService {
  case allStation(body: StationRequest)
  case favoriteStation(body: FavoriteStationRequest)
  case addFavoriteStation(body: AddFavoriteStationRequest)
  case deleteFavoriteStation(deleteStationId: Int)
}


extension StationService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    switch self {
    case .allStation:
      return .station
    case .favoriteStation, .addFavoriteStation, .deleteFavoriteStation:
      return .favorite
    }
  }

  public var urlPath: String {
    switch self {
    case .allStation:
      return StationAPI.allStation.description
    case .favoriteStation:
      return StationAPI.favoriteStation.description
    case .addFavoriteStation:
      return StationAPI.addFavoriteStation.description
    case .deleteFavoriteStation(let deleteStationId):
      return StationAPI.deleteFavoriteStation(deleteStationId: deleteStationId).description
    }
  }

  public var error: [Int : NetworkError]? {
    nil
  }

  public var method: Moya.Method {
    switch self {
    case .allStation, .favoriteStation:
      return .get
    case .addFavoriteStation:
      return .post
    case .deleteFavoriteStation:
      return .delete
    }
  }

  public var parameters: [String : Any]? {
    switch self {
    case .allStation(let body):
      return body.toDictionary
    case .favoriteStation(let body):
      return body.toDictionary
    case .addFavoriteStation(let body):
      return body.toDictionary
    case .deleteFavoriteStation:
      return nil
    }
  }

  public var headers: [String : String]? {
    switch self {
    case .allStation:
      return APIHeader.notAccessTokenHeader
    case .favoriteStation, .addFavoriteStation, .deleteFavoriteStation:
      return APIHeader.baseHeader
    }
  }
}
