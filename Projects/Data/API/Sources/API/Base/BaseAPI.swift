//
//  BaseAPI.swift
//  API
//
//  Created by Wonji Suh  on 3/12/26.
//

import Foundation

public enum BaseAPI : String {
  case base
  case naver

  public var apiDescription: String {
    switch self {
    case .base:
      return "https://\(Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? "")"
    case .naver:
      return "https://maps.apigw.ntruss.com"
    }
  }
}
