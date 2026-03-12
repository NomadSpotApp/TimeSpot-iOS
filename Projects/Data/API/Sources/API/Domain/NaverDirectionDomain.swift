//
//  NaverDirectionDomain.swift
//  API
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

import AsyncMoya

public enum NaverDirectionDomain {
  case direction
  case walking
}

extension NaverDirectionDomain: DomainType {
  public var baseURLString: String {
    return BaseAPI.naver.apiDescription
  }

  public var url: String {
    switch self {
    case .direction:
      return "map-direction/v1"
    case .walking:
      return "map-direction-15/v1"
    }
  }
}