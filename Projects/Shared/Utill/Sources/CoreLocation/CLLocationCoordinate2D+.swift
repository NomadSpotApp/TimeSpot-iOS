//
//  CLLocationCoordinate2D+.swift
//  Utill
//

import Foundation
import CoreLocation

public extension CLLocationCoordinate2D {
  var formattedCoordinateText: String {
    String(format: "%.6f, %.6f", latitude, longitude)
  }

  var approximateAddressText: String {
    "\(formattedCoordinateText) 부근"
  }

  // MARK: - Distance Utils
  func distanceInMeters(to coordinate: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
    let toLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return fromLocation.distance(from: toLocation)
  }

  func formattedDistanceText(to coordinate: CLLocationCoordinate2D) -> String {
    let distanceInMeters = self.distanceInMeters(to: coordinate)
    let roundedDistance = Int((distanceInMeters / 10).rounded() * 10)
    return "\(roundedDistance)m"
  }

  func walkingTimeText(to coordinate: CLLocationCoordinate2D, stationName: String) -> String {
    let distanceInMeters = self.distanceInMeters(to: coordinate)
    let walkingMinutes = max(Int(ceil(distanceInMeters / 67)), 1)
    return "\(stationName)역에서 약 \(walkingMinutes)분"
  }

  // MARK: - Coordinate Comparison
  static func isSameCoordinate(_ lhs: Double?, _ rhs: Double?, tolerance: Double = 0.000001) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
      return lhs == nil && rhs == nil
    }
    return abs(lhs - rhs) < tolerance
  }
}
