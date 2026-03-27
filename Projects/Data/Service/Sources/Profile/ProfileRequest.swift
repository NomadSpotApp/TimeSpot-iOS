//
//  ProfileRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//

import Entity

public struct ProfileRequest: Encodable {
  public let mapApi: String

  public init(
    mapApi: String
  ) {
    self.mapApi = mapApi
  }
}

public struct EditNotificationRequest: Encodable, Equatable {
  public let notificationSettings: [NotificationSettingRequest]

  public init(
    notificationSettings: [NotificationSettingRequest]
  ) {
    self.notificationSettings = notificationSettings
  }

  public init(
    options: [NotificationOption],
    enabledOptions: Set<NotificationOption>
  ) {
    self.notificationSettings = options.map {
      NotificationSettingRequest(
        option: $0,
        isEnabled: enabledOptions.contains($0)
      )
    }
  }
}

public struct NotificationSettingRequest: Encodable, Equatable {
  public let type: String
  public let isEnabled: Bool

  public init(
    type: String,
    isEnabled: Bool
  ) {
    self.type = type
    self.isEnabled = isEnabled
  }

  public init(
    option: NotificationOption,
    isEnabled: Bool
  ) {
    self.type = option.apiType
    self.isEnabled = isEnabled
  }
}
