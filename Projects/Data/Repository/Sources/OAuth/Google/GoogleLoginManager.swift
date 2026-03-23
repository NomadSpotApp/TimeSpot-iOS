//
//  GoogleLoginManager.swift
//  Repository
//
//  Created by Wonji Suh  on 3/23/26.
//

import CryptoKit
import SwiftUI

struct GoogleLoginManager {
  static let shared = GoogleLoginManager()

  func getRootViewController()->UIViewController{
    guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{
      return .init()
    }
    guard let root = screen.windows.first?.rootViewController else{
      return .init()
    }
    return root
  }
}
