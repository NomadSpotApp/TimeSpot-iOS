//
//  RegisterNotificationEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation

public struct RegisterNotificationEntity: Equatable {
  public let userId: String?
  public let deviceToken: String
  public let isActive: Bool

  public init(
    userId: String?,
    deviceToken: String,
    isActive: Bool
  ) {
    self.userId = userId
    self.deviceToken = deviceToken
    self.isActive = isActive
  }
}
