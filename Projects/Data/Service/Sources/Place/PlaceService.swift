//
//  PlaceService.swift
//  Service
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum PlaceService {
  case fetchPlace(body: FetchPlaceRequest)
  case detailPlaces(placeId: Int, body: PlaceDetailRequest)
}


extension PlaceService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    return .place
  }

  public var urlPath: String {
    switch self {
      case .fetchPlace:
        return PlaceAPI.fetchPlace.description
      case .detailPlaces(let placeId, _):
        return PlaceAPI.detailPlace(placeId: placeId).description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .fetchPlace, .detailPlaces:
        return .get
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .fetchPlace(let body):
        return body.toDictionary
      case .detailPlaces(_, let body):
        return body.toDictionary
    }
  }

  public var headers: [String : String]? {
    return APIHeader.baseHeader
  }
}
