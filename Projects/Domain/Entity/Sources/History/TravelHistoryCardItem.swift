//
//  TravelHistoryCardItem.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public struct TravelHistoryCardItem: Identifiable, Hashable {
  public let id = UUID()
  public let visitedAt: Date
  public let placeName: String
  public let departureName: String
  public let durationText: String
  public let departureTimeText: String

  public init(
    visitedAt: Date,
    placeName: String,
    departureName: String,
    durationText: String,
    departureTimeText: String
  ) {
    self.visitedAt = visitedAt
    self.placeName = placeName
    self.departureName = departureName
    self.durationText = durationText
    self.departureTimeText = departureTimeText
  }
}
