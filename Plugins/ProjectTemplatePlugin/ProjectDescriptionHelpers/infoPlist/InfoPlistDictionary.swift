//
//  InfoPlistDictionary.swift
//  Plugins
//
//  Created by Wonji Suh  on 3/22/25.
//

import Foundation
import ProjectDescription

public typealias InfoPlistDictionary = [String: Plist.Value]

extension InfoPlistDictionary {
  func setUIUserInterfaceStyle(_ value: String) -> InfoPlistDictionary {
    return self.merging(["UIUserInterfaceStyle": .string(value)]) { (_, new) in new }
  }
  
  func setCFBundleDevelopmentRegion(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleDevelopmentRegion": .string(value)]) { (_, new) in new }
  }
  
  func setCFBundleExecutable(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleExecutable": .string(value)]) { (_, new) in new }
  }

  func setCFBundleIdentifier(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleIdentifier": .string(value)]) { (_, new) in new }
  }
  
  func setCFBundleInfoDictionaryVersion(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleInfoDictionaryVersion": .string(value)]) { (_, new) in new }
  }
  
  func setCFBundleName(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleName": .string(value)]) { (_, new) in new }
  }

  func setCFBundleDisplayName(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleDisplayName": .string(value)]) { (_, new) in new }
  }

  func setCFBundlePackageType(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundlePackageType": .string(value)]) { (_, new) in new }
  }
  
  func setCFBundleShortVersionString(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleShortVersionString": .string(value)]) { (_, new) in new }
  }
  
  // 매개변수 없는 경우, 기본 지역을 "ko"로 설정
  func setCFBundleDevelopmentRegion() -> InfoPlistDictionary {
    return self.merging(["CFBundleDevelopmentRegion": .string("ko")]) {
      (_, new) in new
    }
  }

  func setCFBundleURLTypes(_ value: [[String: Any]]) -> InfoPlistDictionary {
    func convertToPlistValue(_ value: Any) -> Plist.Value {
      switch value {
      case let string as String:
        return .string(string)
      case let array as [Any]:
        return .array(array.map { convertToPlistValue($0) })
      case let dictionary as [String: Any]:
        return .dictionary(dictionary.mapValues { convertToPlistValue($0) })
      case let bool as Bool:
        return .boolean(bool)
      default:
        return .string("\(value)")
      }
    }
    let dict: [String: Plist.Value] = [
      "CFBundleURLTypes": .array(value.map { .dictionary($0.mapValues { convertToPlistValue($0) }) })
    ]
    return self.merging(dict) { (_, new) in new }
  }
  
  func setCFBundleVersion(_ value: String) -> InfoPlistDictionary {
    return self.merging(["CFBundleVersion": .string(value)]) { (_, new) in new }
  }
  
  func setGIDClientID(_ value: String) -> InfoPlistDictionary {
    return self.merging(["GIDClientID": .string(value)]) { (_, new) in new }
  }
  
  func setLSRequiresIPhoneOS(_ value: Bool) -> InfoPlistDictionary {
    return self.merging(["LSRequiresIPhoneOS": .boolean(value)]) { (_, new) in new }
  }
  
  func setUIAppFonts(_ value: [String]) -> InfoPlistDictionary {
    return self.merging(["UIAppFonts": .array(value.map { .string($0) })]) { (_, new) in new }
  }
  
  func setAppTransportSecurity() -> InfoPlistDictionary {
    let dict: [String: Plist.Value] = [
      "NSAppTransportSecurity": .dictionary([
        "NSAllowsArbitraryLoads": .boolean(true)
      ])
    ]
    return self.merging(dict) { (_, new) in new }
  }

  // 매개변수 없는 URL 타입 (예: 카카오)
  func setCFBundleURLTypes() -> InfoPlistDictionary {
    let dict: [String: Plist.Value] = [
      "CFBundleURLTypes": .array([
        .dictionary([
          "CFBundleURLSchemes": .array([
            .string("${REVERSED_CLIENT_ID}")
//            .string("com.googleusercontent.apps.882277748169-glpolfiecue4lqqps6hmgj9t8lm1g5qp")
          ])
        ])
      ])
    ]
    return self.merging(dict) { (_, new) in new }
  }
  
  func setUIApplicationSceneManifest(_ value: [String: Any]) -> InfoPlistDictionary {
    func convertToPlistValue(_ value: Any) -> Plist.Value {
      switch value {
      case let string as String:
        return .string(string)
      case let array as [Any]:
        return .array(array.map { convertToPlistValue($0) })
      case let dictionary as [String: Any]:
        return .dictionary(dictionary.mapValues { convertToPlistValue($0) })
      case let bool as Bool:
        return .boolean(bool)
      default:
        return .string("\(value)")
      }
    }
    let dict: [String: Plist.Value] = [
      "UIApplicationSceneManifest": convertToPlistValue(value)
    ]
    return self.merging(dict) { (_, new) in new }
  }
  
  func setUILaunchStoryboardName(_ value: String) -> InfoPlistDictionary {
    return self.merging(["UILaunchStoryboardName": .string(value)]) { (_, new) in new }
  }
  
  func setUIRequiredDeviceCapabilities(_ value: [String]) -> InfoPlistDictionary {
    return self.merging(["UIRequiredDeviceCapabilities": .array(value.map { .string($0) })]) { (_, new) in new }
  }
  
  func setUISupportedInterfaceOrientations(_ value: [String]) -> InfoPlistDictionary {
    return self.merging(["UISupportedInterfaceOrientations": .array(value.map { .string($0) })]) { (_, new) in new }
  }
  
  func setNSCameraUsageDescription(_ value: String) -> InfoPlistDictionary {
    return self.merging(["NSCameraUsageDescription": .string(value)]) { (_, new) in new }
  }
  
  func setUILaunchScreens() -> InfoPlistDictionary {
    let dict: InfoPlistDictionary = [
      "UILaunchScreen": .dictionary([
        "UIColorName": .string(""),
        "UIImageName": .string("")
      ])
    ]
    return self.merging(dict) { _, new in new }
  }
  
  func setAppUseExemptEncryption(value: Bool) -> InfoPlistDictionary {
    return self.merging(["ITSAppUsesNonExemptEncryption": .boolean(value)]) { (_, new) in new }
  }
  
  func setFirebaseAnalyticsCollectionEnabled() -> InfoPlistDictionary {
    return self.merging(["FIREBASE_ANALYTICS_COLLECTION_ENABLED": .boolean(false)]) { (_, new) in new }
  }
  
  func setCalenderUsage(_ description: String) -> InfoPlistDictionary {
    return self.merging(["NSCalendarsUsageDescription": .string(description)]) { (_, new) in new }
  }
  
  func setGoogleReversedClientID(_ value: String) -> InfoPlistDictionary {
    return self.merging(["REVERSED_CLIENT_ID": .string(value)]) { (_, new) in new }
  }
  
  func setGoogleClientID(_ value: String) -> InfoPlistDictionary {
    return self.merging(["GOOGLE_CLIENT_ID": .string(value)]) { (_, new) in new }
  }
  
  func setBaseURL(_ value: String) -> InfoPlistDictionary {
    return self.merging(["BASE_URL": .string(value)]) { (_, new) in new }
  }



  func setLocationPermissions() -> InfoPlistDictionary {
    let locationDict: InfoPlistDictionary = [
      // iOS 11+ 위치 권한
      "NSLocationWhenInUseUsageDescription": .string("TimeSpot이 근처 장소를 찾고 지도에 현재 위치를 표시하기 위해 위치 정보를 사용합니다."),
      "NSLocationAlwaysAndWhenInUseUsageDescription": .string("TimeSpot이 백그라운드에서도 위치 기반 서비스를 제공하기 위해 위치 정보를 사용합니다."),
      // iOS 11 이전 호환성
      "NSLocationAlwaysUsageDescription": .string("TimeSpot이 백그라운드에서도 위치 기반 서비스를 제공하기 위해 위치 정보를 사용합니다."),
      // iOS 8 이전 호환성
      "NSLocationUsageDescription": .string("TimeSpot이 위치 기반 서비스를 제공하기 위해 위치 정보를 사용합니다."),
      // 위치 정확도 감소 권한 (iOS 14+)
      "NSLocationTemporaryUsageDescriptionDictionary": .dictionary([
        "TimeSpotLocationAccuracy": .string("더 정확한 위치 정보를 위해 정확한 위치 접근이 필요합니다.")
      ])
    ]
    return self.merging(locationDict) { (_, new) in new }
  }

  // 네이버 지도 API 키 설정
  func setNMFGovClientId(_ value: String) -> InfoPlistDictionary {
    return self.merging(["NMFGovClientId": .string(value)]) { (_, new) in new }
  }

  func setNMFGovClientSecret(_ value: String) -> InfoPlistDictionary {
    return self.merging(["NMFGovClientSecret": .string(value)]) { (_, new) in new }
  }
}
