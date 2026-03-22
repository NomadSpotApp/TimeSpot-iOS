//
//  DiRegister.swift
//  NomadSpot
//
//  Created by Wonji Suh  on 3/1/26.
//

import Foundation

import DomainInterface
import Repository
import Foundations
import UseCase

import ComposableArchitecture
import WeaveDI


/// 🚀 **앱 전역 DI 관리자**
@MainActor
public final class AppDIManager {
  public static let shared = AppDIManager()

  private init() {}

  /// 🎯 기본 의존성들을 등록
  public func registerDefaultDependencies() async {
    // 🏗️ 1. WeaveDI.builder 패턴으로 실제 구현체들 등록
    WeaveDI.builder
      .register { KeychainManager() as KeychainManagingInterface }
      .register {
        let keychainManager = UnifiedDI.resolve(KeychainManagingInterface.self) ?? KeychainManager()
        return KeychainTokenProvider(keychainManager: keychainManager) as TokenProviding
      }
      .register(DirectionInterface.self) { DirectionRepositoryImpl() }
      .configure()
  }
}
