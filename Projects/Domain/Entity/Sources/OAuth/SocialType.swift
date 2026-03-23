//
//  SocialType.swift
//  Entity
//
//  Created by Wonji Suh  on 3/19/26.
//

import Foundation

public enum SocialType: String, CaseIterable, Identifiable, Hashable, Equatable {
  case apple
  case google

  public var id: String { rawValue }

  public var description: String {
    switch self {
      case .apple:
        return "Apple"
      case .google:
        return "Google"
    }
  }

  public var image: String {
    switch self {
      case .apple:
        return "apple.logo"
      case .google:
        return "google"
    }
  }
}
