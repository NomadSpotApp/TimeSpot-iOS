//
//  ProfileDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

public typealias ProfileDTOModel = BaseResponseDTO<ProfileResponseDTO>

// MARK: - DataClass
public struct ProfileResponseDTO: Decodable, Equatable {
    let userID, email, nickname, mapAPI: String
    let role, providerType, createdAt: String
    let totalVisitCount,  totalJourneyMinutes: Int

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case email, nickname
        case mapAPI = "mapApi"
        case role, providerType, createdAt
        case totalVisitCount, totalJourneyMinutes
    }

  public init(
    userID: String,
    email: String,
    nickname: String,
    mapAPI: String,
    role: String,
    providerType: String,
    createdAt: String,
    totalJourneyMinutes: Int,
    totalVisitCount: Int
  ) {
    self.userID = userID
    self.email = email
    self.nickname = nickname
    self.mapAPI = mapAPI
    self.role = role
    self.providerType = providerType
    self.createdAt = createdAt
    self.totalVisitCount = totalVisitCount
    self.totalJourneyMinutes = totalJourneyMinutes
  }
}
