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
}
