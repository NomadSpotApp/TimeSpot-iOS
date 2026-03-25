//
//  LogoutEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 3/25/26.
//

import Foundation

public struct LogoutEntity: Equatable, Hashable {
  public let code: Int
  public let message: String

  public init(
    code: Int,
    message: String
  ) {
    self.code = code
    self.message = message
  }
}
