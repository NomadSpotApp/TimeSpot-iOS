//
//  RegisterNotificationDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/30/26.
//


import Foundation


public typealias RegisterNotificationDTO = BaseResponseDTO<RegisterNotificationResponseDTOModel>

public struct RegisterNotificationResponseDTOModel: Decodable, Equatable {
  let userID: String?
  let deviceToken: String
  let isActive: Bool

  enum CodingKeys: String, CodingKey {
    case userID = "userId"
    case deviceToken, isActive
  }
}
