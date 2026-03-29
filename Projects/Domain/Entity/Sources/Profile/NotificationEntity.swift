//
//  NotificationEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

public struct NotificationEntity: Equatable, Hashable {
  public let settings: [NotificationSettingEntity]
  public let updatedAt: String

  public init(
    settings: [NotificationSettingEntity],
    updatedAt: String
  ) {
    self.settings = settings
    self.updatedAt = updatedAt
  }
}

public struct NotificationSettingEntity: Equatable, Hashable, Identifiable {
  public let option: NotificationOption
  public let isEnabled: Bool
  public let isEditable: Bool

  public var id: NotificationOption { option }

  public init(
    option: NotificationOption,
    isEnabled: Bool,
    isEditable: Bool
  ) {
    self.option = option
    self.isEnabled = isEnabled
    self.isEditable = isEditable
  }
}
