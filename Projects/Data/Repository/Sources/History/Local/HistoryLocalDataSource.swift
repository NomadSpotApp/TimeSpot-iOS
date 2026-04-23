//
//  HistoryLocalDataSource.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

public protocol HistoryLocalDataSourceProtocol: Actor {
  func loadHistory(sort: TravelHistorySort, size: Int) async throws -> HistoryEntity?
  func saveHistory(sort: TravelHistorySort, size: Int, history: HistoryEntity) async throws
  func clearAll() async throws
}

public actor HistoryLocalDataSource: HistoryLocalDataSourceProtocol {
  /// LRU 정리 임계값 — sort 종류만큼 (recent/oldest = 2개)이지만 size 변동까지 고려해 4개
  private static let cacheLimit = 4

  private let container: ModelContainer

  public init(container: ModelContainer? = nil) {
    if let container {
      self.container = container
    } else {
      let schema = Schema([
        HistoryListCacheEntity.self,
        HistoryItemCacheEntity.self
      ])
      do {
        self.container = try ModelContainer(
          for: schema,
          configurations: ModelConfiguration(
            isStoredInMemoryOnly: false
          )
        )
      } catch {
        fatalError("Failed to create History cache container: \(error)")
      }
    }
  }

  public func loadHistory(sort: TravelHistorySort, size: Int) async throws -> HistoryEntity? {
    let context = makeContext()
    let cacheKey = HistoryCacheKey.list(sort: sort, size: size)
    guard let cache = try fetchCache(cacheKey: cacheKey, in: context) else {
      return nil
    }
    if cache.isExpired {
      context.delete(cache)
      try context.save()
      return nil
    }
    cache.cachedAt = Date()  // LRU 갱신
    try context.save()
    return cache.toDomain()
  }

  public func saveHistory(
    sort: TravelHistorySort,
    size: Int,
    history: HistoryEntity
  ) async throws {
    // 첫 페이지만 캐시 (페이지네이션 캐시는 메모리 비용 큼)
    guard history.page <= 1 else { return }

    let context = makeContext()
    let cacheKey = HistoryCacheKey.list(sort: sort, size: size)
    if let existing = try fetchCache(cacheKey: cacheKey, in: context) {
      context.delete(existing)
    }

    let cache = history.toCacheModel(cacheKey: cacheKey, sort: sort)
    context.insert(cache)

    try pruneIfNeeded(in: context)
    try context.save()
  }

  public func clearAll() async throws {
    let context = makeContext()
    try context.delete(model: HistoryListCacheEntity.self)
    try context.save()
  }
}

private extension HistoryLocalDataSource {
  func makeContext() -> ModelContext {
    ModelContext(container)
  }

  func fetchCache(
    cacheKey: String,
    in context: ModelContext
  ) throws -> HistoryListCacheEntity? {
    var descriptor = FetchDescriptor<HistoryListCacheEntity>(
      predicate: #Predicate { $0.cacheKey == cacheKey }
    )
    descriptor.relationshipKeyPathsForPrefetching = [
      \HistoryListCacheEntity.items
    ]
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  func pruneIfNeeded(in context: ModelContext) throws {
    var descriptor = FetchDescriptor<HistoryListCacheEntity>(
      sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
    )
    descriptor.propertiesToFetch = [\.cacheKey, \.cachedAt]

    let all = try context.fetch(descriptor)
    let overflow = all.count - Self.cacheLimit
    guard overflow > 0 else { return }

    for cache in all.prefix(overflow) {
      context.delete(cache)
    }
  }
}
