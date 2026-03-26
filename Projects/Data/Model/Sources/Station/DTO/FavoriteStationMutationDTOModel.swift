//
//  FavoriteStationMutationDTOModel.swift
//  Model
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct FavoriteStationMutationDTOModel: Decodable, Equatable {
  public let code: Int
  public let message: String
  public let data: EmptyResponseDTO?

  public init(
    code: Int,
    message: String,
    data: EmptyResponseDTO? = nil
  ) {
    self.code = code
    self.message = message
    self.data = data
  }

  enum CodingKeys: String, CodingKey {
    case code
    case message
    case data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.code = try container.decode(Int.self, forKey: .code)
    self.message = try container.decode(String.self, forKey: .message)
    self.data = try container.decodeIfPresent(EmptyResponseDTO.self, forKey: .data)
  }
}
