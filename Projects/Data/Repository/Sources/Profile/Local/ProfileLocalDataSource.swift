//
//  ProfileLocalDataSource.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

public protocol ProfileLocalDataSourceProtocol: Actor {
  func loadUser() async throws -> ProfileEntity?
  func saveUser(_ profile: ProfileEntity) async throws
  func clear() async throws
}

public actor ProfileLocalDataSource: ProfileLocalDataSourceProtocol {
  private let container: ModelContainer

  public init(container: ModelContainer? = nil) {
    if let container {
      self.container = container
    } else {
      let schema = Schema([ProfileCacheEntity.self])
      do {
        self.container = try ModelContainer(
          for: schema,
          configurations: ModelConfiguration(
            isStoredInMemoryOnly: false
          )
        )
      } catch {
        fatalError("Failed to create Profile cache container: \(error)")
      }
    }
  }

  public func loadUser() async throws -> ProfileEntity? {
    let context = makeContext()
    guard let cache = try fetchCache(in: context) else {
      return nil
    }
    if cache.isExpired {
      context.delete(cache)
      try context.save()
      return nil
    }
    return cache.toDomain()
  }

  public func saveUser(_ profile: ProfileEntity) async throws {
    let context = makeContext()
    if let existing = try fetchCache(in: context) {
      context.delete(existing)
    }
    context.insert(profile.toCacheModel(cacheKey: ProfileCacheKey.user))
    try context.save()
  }

  public func clear() async throws {
    let context = makeContext()
    try context.delete(model: ProfileCacheEntity.self)
    try context.save()
  }
}

private extension ProfileLocalDataSource {
  func makeContext() -> ModelContext {
    ModelContext(container)
  }

  func fetchCache(in context: ModelContext) throws -> ProfileCacheEntity? {
    var descriptor = FetchDescriptor<ProfileCacheEntity>(
      predicate: #Predicate { $0.cacheKey == "profile.user.default" }
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }
}
