//
//  ProfileNotificationDTO+.swift
//  Model
//
//  Created by Wonji Suh  on 3/27/26.
//

import Entity

public extension ProfileNotificationDTO {
  func toDomain() -> NotificationEntity {
    data.toDomain()
  }
}

public extension ProfileNotificationResponseDTO {
  func toDomain() -> NotificationEntity {
    NotificationEntity(
      settings: settings.compactMap { setting in
        setting.toDomain()
      },
      updatedAt: updatedAt
    )
  }
}

public extension ProfileNotificationSettingDTO {
  func toDomain() -> NotificationSettingEntity? {
    guard let option = NotificationOption(apiType: type) else {
      return nil
    }

    return NotificationSettingEntity(
      option: option,
      isEnabled: isEnabled,
      isEditable: isEditable
    )
  }
}
