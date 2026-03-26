//
//  HistoryRequest.swift
//  Service
//
//  Created by Wonji Suh  on 3/26/26.
//


import Foundation

public struct MyHistoryRequest: Encodable {
  public let page: Int
  public let size: Int
  public let sort: String

  public init(
    page: Int,
    size: Int,
    sort: String
  ) {
    self.page = page
    self.size = size
    self.sort = sort
  }
}
