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
  case fetchPlaces(body: PlaceRequest)
}


extension PlaceService: BaseTargetType {
  public typealias Domain = TimeSpotDomain

  public var domain: TimeSpotDomain {
    return .place
  }

  public var urlPath: String {
    switch self {
      case .fetchPlaces:
        return PlaceAPI.fetchPlace.description
    }
  }

  public var error: [Int : NetworkError]? {
    return nil
  }

  public var method: Moya.Method {
    switch self {
      case .fetchPlaces:
        return .get
    }
  }

  public var parameters: [String : Any]? {
    switch self {
      case .fetchPlaces(let body):
        return body.toDictionary
    }
  }

  public var headers: [String : String]? {
    return APIHeader.baseHeader
  }
}
