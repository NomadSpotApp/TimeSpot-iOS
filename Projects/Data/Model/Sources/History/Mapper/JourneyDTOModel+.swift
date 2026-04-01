//
//  JourneyDTOModel+.swift
//  Model
//
//  Created by Wonji Suh  on 4/1/26.
//

import Entity
import Foundation

public extension JourneyResponseDTO {
  func toDomain() -> JourneyEntity {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // Fallback formatter without fractional seconds
    let fallbackFormatter = ISO8601DateFormatter()
    fallbackFormatter.formatOptions = [.withInternetDateTime]

    // Custom formatter for server response format (without Z suffix)
    let customFormatter = DateFormatter()
    customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    customFormatter.timeZone = TimeZone.current

    func parseDate(_ dateString: String) -> Date {
      return dateFormatter.date(from: dateString)
          ?? fallbackFormatter.date(from: dateString)
          ?? customFormatter.date(from: dateString)
          ?? Date()
    }

    return JourneyEntity(
      id: visitingHistoryId,
      stationId: stationId,
      stationName: stationName,
      stationAddress: stationAddress,
      placeId: placeId,
      placeName: placeName,
      placeCategory: placeCategory,
      placeAddress: placeAddress,
      placeLat: placeLat,
      placeLng: placeLng,
      startTime: parseDate(startTime),
      endTime: endTime.map(parseDate),
      trainDepartureTime: parseDate(trainDepartureTime),
      totalDurationMinutes: totalDurationMinutes,
      isInProgress: isInProgress,
      isSuccess: isSuccess,
      createdAt: parseDate(createdAt),
      startLat: startLat,
      startLng: startLng
    )
  }
}

