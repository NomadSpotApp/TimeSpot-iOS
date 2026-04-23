//
//  StationLocalDataSource.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

public protocol StationLocalDataSourceProtocol: Actor {
  func load() async throws -> StationListEntity?
  func save(stations: StationListEntity) async throws
  func clear() async throws
}

public actor StationLocalDataSource: StationLocalDataSourceProtocol {
  private static let defaultCacheKey = "station.list.default"

  private let container: ModelContainer

  public init(container: ModelContainer? = nil) {
    if let container {
      self.container = container
    } else {
      let schema = Schema([
        StationCacheEntity.self,
        StationCacheItemEntity.self
      ])

      do {
        self.container = try ModelContainer(
          for: schema,
          configurations: ModelConfiguration(
            isStoredInMemoryOnly: false
          )
        )
      } catch {
        fatalError("Failed to create Station cache container: \(error)")
      }
    }
  }

  public func load() async throws -> StationListEntity? {
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

  public func save(stations: StationListEntity) async throws {
    let context = makeContext()

    if let existing = try fetchCache(in: context) {
      context.delete(existing)
    }

    let cache = stations.toCacheModel(cacheKey: Self.defaultCacheKey)
    context.insert(cache)
    try context.save()
  }

  public func clear() async throws {
    let context = makeContext()
    guard let cache = try fetchCache(in: context) else { return }
    context.delete(cache)
    try context.save()
  }
}

private extension StationLocalDataSource {
  func makeContext() -> ModelContext {
    ModelContext(container)
  }

  func fetchCache(in context: ModelContext) throws -> StationCacheEntity? {
    var descriptor = FetchDescriptor<StationCacheEntity>(
      predicate: #Predicate { $0.cacheKey == "station.list.default" }
    )
    descriptor.relationshipKeyPathsForPrefetching = [
      \StationCacheEntity.items
    ]
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }
}
