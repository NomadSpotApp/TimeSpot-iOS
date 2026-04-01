//
//  ProfileNotificationDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/27/26.
//

import Foundation

public typealias ProfileNotificationDTO = BaseResponseDTO<ProfileNotificationResponseDTO>

// MARK: - DataClass
public struct ProfileNotificationResponseDTO: Decodable, Equatable {
  public let settings: [ProfileNotificationSettingDTO]
  public let updatedAt: String

  public init(
    settings: [ProfileNotificationSettingDTO],
    updatedAt: String
  ) {
    self.settings = settings
    self.updatedAt = updatedAt
  }
}

// MARK: - Setting
public struct ProfileNotificationSettingDTO: Decodable, Equatable {
  public let type: String
  public let isEnabled: Bool
  public let isEditable: Bool

  public init(
    type: String,
    isEnabled: Bool,
    isEditable: Bool
  ) {
    self.type = type
    self.isEnabled = isEnabled
    self.isEditable = isEditable
  }
}
