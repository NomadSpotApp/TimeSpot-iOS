//
//  AppDelegate.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import UIKit
import WeaveDI


class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    WeaveDI.Container.bootstrapInTask { @DIContainerActor _ in
      await AppDIManager.shared.registerDefaultDependencies()
    }

    return true
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
  }
}
