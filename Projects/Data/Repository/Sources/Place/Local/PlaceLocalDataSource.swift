//
//  PlaceLocalDataSource.swift
//  Repository
//
//  Created by Wonji Suh on 4/23/26.
//

import Foundation
import SwiftData
import Entity

public protocol PlaceLocalDataSourceProtocol: Actor {
  func loadList(cacheKey: String) async throws -> PlaceSearchPageEntity?
  func saveList(cacheKey: String, page: PlaceSearchPageEntity) async throws

  func loadDetail(cacheKey: String) async throws -> PlaceDetailEntity?
  func saveDetail(cacheKey: String, detail: PlaceDetailEntity) async throws

  func clearAll() async throws
}

public actor PlaceLocalDataSource: PlaceLocalDataSourceProtocol {
  /// LRU 정리 임계값 — 최대 보관 캐시 항목 수 (메모리/디스크 절감)
  private static let listCacheLimit = 10
  private static let detailCacheLimit = 30

  private let container: ModelContainer

  public init(container: ModelContainer? = nil) {
    if let container {
      self.container = container
    } else {
      let schema = Schema([
        PlaceListCacheEntity.self,
        PlaceCacheItemEntity.self,
        PlaceDetailCacheEntity.self
      ])
      do {
        self.container = try ModelContainer(
          for: schema,
          configurations: ModelConfiguration(
            isStoredInMemoryOnly: false
          )
        )
      } catch {
        fatalError("Failed to create Place cache container: \(error)")
      }
    }
  }

  // MARK: - List

  public func loadList(cacheKey: String) async throws -> PlaceSearchPageEntity? {
    let context = makeContext()
    guard let cache = try fetchListCache(cacheKey: cacheKey, in: context) else {
      return nil
    }
    if cache.isExpired {
      context.delete(cache)
      try context.save()
      return nil
    }
    // LRU 갱신: 마지막 접근 시각을 업데이트
    cache.cachedAt = Date()
    try context.save()
    return cache.toDomain()
  }

  public func saveList(cacheKey: String, page: PlaceSearchPageEntity) async throws {
    let context = makeContext()

    if let existing = try fetchListCache(cacheKey: cacheKey, in: context) {
      context.delete(existing)
    }

    let cache = page.toCacheModel(cacheKey: cacheKey)
    context.insert(cache)

    try pruneListCacheIfNeeded(in: context)
    try context.save()
  }

  // MARK: - Detail

  public func loadDetail(cacheKey: String) async throws -> PlaceDetailEntity? {
    let context = makeContext()
    guard let cache = try fetchDetailCache(cacheKey: cacheKey, in: context) else {
      return nil
    }
    if cache.isExpired {
      context.delete(cache)
      try context.save()
      return nil
    }
    // LRU 갱신
    cache.cachedAt = Date()
    try context.save()
    return cache.toDomain()
  }

  public func saveDetail(cacheKey: String, detail: PlaceDetailEntity) async throws {
    let context = makeContext()

    if let existing = try fetchDetailCache(cacheKey: cacheKey, in: context) {
      context.delete(existing)
    }

    context.insert(detail.toCacheModel(cacheKey: cacheKey))

    try pruneDetailCacheIfNeeded(in: context)
    try context.save()
  }

  // MARK: - Clear

  public func clearAll() async throws {
    let context = makeContext()
    try context.delete(model: PlaceListCacheEntity.self)
    try context.delete(model: PlaceDetailCacheEntity.self)
    try context.save()
  }
}

private extension PlaceLocalDataSource {
  func makeContext() -> ModelContext {
    ModelContext(container)
  }

  // MARK: List helpers

  func fetchListCache(
    cacheKey: String,
    in context: ModelContext
  ) throws -> PlaceListCacheEntity? {
    var descriptor = FetchDescriptor<PlaceListCacheEntity>(
      predicate: #Predicate { $0.cacheKey == cacheKey }
    )
    descriptor.relationshipKeyPathsForPrefetching = [
      \PlaceListCacheEntity.items
    ]
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  /// LRU 정리: 임계값 초과 시 가장 오래된 항목부터 삭제
  func pruneListCacheIfNeeded(in context: ModelContext) throws {
    var descriptor = FetchDescriptor<PlaceListCacheEntity>(
      sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
    )
    descriptor.propertiesToFetch = [\.cacheKey, \.cachedAt]

    let all = try context.fetch(descriptor)
    let overflow = all.count - Self.listCacheLimit
    guard overflow > 0 else { return }

    for cache in all.prefix(overflow) {
      context.delete(cache)
    }
  }

  // MARK: Detail helpers

  func fetchDetailCache(
    cacheKey: String,
    in context: ModelContext
  ) throws -> PlaceDetailCacheEntity? {
    var descriptor = FetchDescriptor<PlaceDetailCacheEntity>(
      predicate: #Predicate { $0.cacheKey == cacheKey }
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
  }

  func pruneDetailCacheIfNeeded(in context: ModelContext) throws {
    var descriptor = FetchDescriptor<PlaceDetailCacheEntity>(
      sortBy: [SortDescriptor(\.cachedAt, order: .forward)]
    )
    descriptor.propertiesToFetch = [\.cacheKey, \.cachedAt]

    let all = try context.fetch(descriptor)
    let overflow = all.count - Self.detailCacheLimit
    guard overflow > 0 else { return }

    for cache in all.prefix(overflow) {
      context.delete(cache)
    }
  }
}
