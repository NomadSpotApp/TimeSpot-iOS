//
//  BaseResponseDTO.swift
//  Model
//
//  Created by Wonji Suh  on 3/23/26.
//

import Foundation

// MARK: - BaseDTO
public struct BaseResponseDTO<DataDTO: Decodable>: Decodable {
  public let code: Int
  public let message: String
  public var data: DataDTO

  public init(
    code: Int,
    message: String,
    data: DataDTO
  ) {
    self.code    = code
    self.message = message
    self.data    = data
  }
}

extension BaseResponseDTO: Equatable where DataDTO: Equatable {}
