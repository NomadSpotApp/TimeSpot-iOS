//
//  RegisterNotificationDTO+.swift
//  Model
//
//  Created by Wonji Suh  on 3/30/26.
//

import Foundation
import Entity

public extension RegisterNotificationResponseDTOModel {
  func toDomain() -> RegisterNotificationEntity {
    return RegisterNotificationEntity(
      userId: self.userID,
      deviceToken: self.deviceToken,
      isActive: self.isActive
    )
  }
}
