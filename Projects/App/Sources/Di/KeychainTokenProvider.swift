//
//  KeychainTokenProvider.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import Foundation

import DomainInterface
import Foundations

struct KeychainTokenProvider: TokenProviding {
  private let keychainManager: KeychainManagingInterface

  init(keychainManager: KeychainManagingInterface) {
    self.keychainManager = keychainManager
  }

  func accessToken() -> String? {
    keychainManager.accessToken()
  }

  func saveAccessToken(_ token: String) {
    keychainManager.saveAccessToken(token)
  }
}
