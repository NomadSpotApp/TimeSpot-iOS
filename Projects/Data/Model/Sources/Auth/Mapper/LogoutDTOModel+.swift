//
//  LogoutDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 3/25/26.
//

import Entity

public extension LogoutDTOModel {
  func toDomain() -> LogoutEntity  {
    LogoutEntity(
      code: code,
      message: message
    )
  }
}
