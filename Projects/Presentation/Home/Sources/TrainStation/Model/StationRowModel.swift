//
//  StationRowModel.swift
//  Home
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation
import Entity

public struct StationRowModel: Identifiable, Equatable {
  public let id: String
  let station: Station
  let badges: [String]
  let distanceText: String?
  let isFavorite: Bool
}
