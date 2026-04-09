//
//  AnalyticsUseCase.swift
//  UseCase
//
//  Created by Codex on 4/10/26.
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import Mixpanel

public enum AnalyticsEvent: Sendable {
  case auth(AuthEventType, AuthEventData)
  case place(PlaceEventType, PlaceEventData)
  case session(SessionEventType, SessionEventData)
}

public enum AuthEventType: String, Sendable {
  case loginSucceeded = "login_succeeded"
  case loginFailed = "login_failed"
  case signupSucceeded = "signup_succeeded"
  case signupFailed = "signup_failed"
}

public struct AuthEventData: Sendable {
  public let socialType: String?
  public let isNewUser: Bool?
  public let mapType: String?
  public let completedStepCount: Int?
  public let errorDescription: String?

  public init(
    socialType: String? = nil,
    isNewUser: Bool? = nil,
    mapType: String? = nil,
    completedStepCount: Int? = nil,
    errorDescription: String? = nil
  ) {
    self.socialType = socialType
    self.isNewUser = isNewUser
    self.mapType = mapType
    self.completedStepCount = completedStepCount
    self.errorDescription = errorDescription
  }
}

public enum PlaceEventType: String, Sendable {
  case exploreStarted = "explore_started"
  case listViewed = "place_list_viewed"
  case selected = "place_selected"
  case detailOpened = "place_detail_opened"
  case detailViewed = "place_detail_viewed"
  case routeStarted = "route_started"
}

public struct PlaceEventData: Sendable {
  public let placeID: String?
  public let placeName: String?
  public let category: String?
  public let placeType: String?
  public let stayableMinutes: Int?
  public let walkTimeFromStation: Int?
  public let visitable: Bool?
  public let source: String?
  public let resultCount: Int?
  public let stationID: String?
  public let stationName: String?

  public init(
    placeID: String? = nil,
    placeName: String? = nil,
    category: String? = nil,
    placeType: String? = nil,
    stayableMinutes: Int? = nil,
    walkTimeFromStation: Int? = nil,
    visitable: Bool? = nil,
    source: String? = nil,
    resultCount: Int? = nil,
    stationID: String? = nil,
    stationName: String? = nil
  ) {
    self.placeID = placeID
    self.placeName = placeName
    self.category = category
    self.placeType = placeType
    self.stayableMinutes = stayableMinutes
    self.walkTimeFromStation = walkTimeFromStation
    self.visitable = visitable
    self.source = source
    self.resultCount = resultCount
    self.stationID = stationID
    self.stationName = stationName
  }
}

public enum SessionEventType: String, Sendable {
  case logoutSucceeded = "logout_succeeded"
}

public struct SessionEventData: Sendable {
  public let provider: String
  public let wasGuest: Bool

  public init(provider: String, wasGuest: Bool) {
    self.provider = provider
    self.wasGuest = wasGuest
  }
}

public struct AnalyticsUseCase: Sendable {
  public var track: @Sendable (_ event: AnalyticsEvent) -> Void

  public init(track: @escaping @Sendable (_ event: AnalyticsEvent) -> Void) {
    self.track = track
  }
}

extension AnalyticsUseCase: DependencyKey {
  public static let liveValue = AnalyticsUseCase { event in
    let mixpanel = Mixpanel.mainInstance()

    switch event {
    case let .auth(type, data):
      if type == .loginSucceeded || type == .signupSucceeded {
        identifyIfPossible(mixpanel: mixpanel, socialType: data.socialType, isNewUser: data.isNewUser)
      }
      let properties = authProperties(data)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)

    case let .place(type, data):
      let properties = placeProperties(data)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)

    case let .session(type, data):
      let properties = sessionProperties(data)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)
      if type == .logoutSucceeded {
        mixpanel.reset()
      }
    }
  }

  public static let testValue = AnalyticsUseCase { _ in }
  public static let previewValue = testValue

  private static func identifyIfPossible(
    mixpanel: MixpanelInstance,
    socialType: String?,
    isNewUser: Bool?
  ) {
    let distinctID = "\(socialType ?? "unknown")-\(UUID().uuidString)"
    mixpanel.identify(distinctId: distinctID)

    var properties: Properties = [:]
    if let socialType {
      properties["provider"] = socialType
    }
    if let isNewUser {
      properties["is_new_user"] = isNewUser
    }

    guard !properties.isEmpty else { return }
    mixpanel.people.set(properties: properties)
  }

  private static func authProperties(_ data: AuthEventData) -> Properties {
    var properties: Properties = [:]
    if let socialType = data.socialType {
      properties["social_type"] = socialType
    }
    if let isNewUser = data.isNewUser {
      properties["is_new_user"] = isNewUser
    }
    if let mapType = data.mapType {
      properties["map_type"] = mapType
    }
    if let completedStepCount = data.completedStepCount {
      properties["completed_step_count"] = completedStepCount
    }
    if let errorDescription = data.errorDescription {
      properties["error_description"] = errorDescription
    }
    return properties
  }

  private static func placeProperties(_ data: PlaceEventData) -> Properties {
    var properties: Properties = [:]
    if let placeID = data.placeID {
      properties["place_id"] = placeID
    }
    if let placeName = data.placeName {
      properties["place_name"] = placeName
    }
    if let category = data.category {
      properties["category"] = category
    }
    if let placeType = data.placeType {
      properties["place_type"] = placeType
    }
    if let stayableMinutes = data.stayableMinutes {
      properties["stayable_minutes"] = stayableMinutes
    }
    if let walkTimeFromStation = data.walkTimeFromStation {
      properties["walk_time_from_station"] = walkTimeFromStation
    }
    if let visitable = data.visitable {
      properties["visitable"] = visitable
    }
    if let source = data.source {
      properties["source"] = source
    }
    if let resultCount = data.resultCount {
      properties["result_count"] = resultCount
    }
    if let stationID = data.stationID {
      properties["station_id"] = stationID
    }
    if let stationName = data.stationName {
      properties["station_name"] = stationName
    }
    return properties
  }

  private static func sessionProperties(_ data: SessionEventData) -> Properties {
    [
      "provider": data.provider,
      "was_guest": data.wasGuest
    ]
  }
}

public extension DependencyValues {
  var analyticsUseCase: AnalyticsUseCase {
    get { self[AnalyticsUseCase.self] }
    set { self[AnalyticsUseCase.self] = newValue }
  }
}
