//
//  RouteUseCaseImplTests.swift
//  UseCaseTests
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Testing
import CoreLocation
import Dependencies
@testable import UseCase
@testable import Entity
@testable import DomainInterface

@Suite("길찾기 UseCase 테스트", .tags(.domain, .usecase, .route))
struct RouteUseCaseImplTests {

  // MARK: - Test Data
  let testStartCoord = CLLocationCoordinate2D(latitude: 37.497942, longitude: 127.027621) // 강남역
  let testDestCoord = CLLocationCoordinate2D(latitude: 37.556785, longitude: 126.923011) // 홍대입구역

  let mockRouteInfo = RouteInfo(
    paths: [
      CLLocationCoordinate2D(latitude: 37.497942, longitude: 127.027621),
      CLLocationCoordinate2D(latitude: 37.527, longitude: 127.025),
      CLLocationCoordinate2D(latitude: 37.556785, longitude: 126.923011)
    ],
    distance: 1500,
    duration: 20
  )

  // MARK: - Mock DirectionRepository
  final class MockDirectionRepository: DirectionInterface, @unchecked Sendable {
    var shouldThrowError: DirectionError?
    var mockResult: RouteInfo?
    var callHistory: [(CLLocationCoordinate2D, CLLocationCoordinate2D, RouteOption)] = []

    func getRoute(
      from start: CLLocationCoordinate2D,
      to destination: CLLocationCoordinate2D,
      option: RouteOption
    ) async throws -> RouteInfo {
      // 호출 기록 저장
      callHistory.append((start, destination, option))

      // 에러 시뮬레이션
      if let error = shouldThrowError {
        throw error
      }

      // Mock 결과 반환
      guard let result = mockResult else {
        throw DirectionError.noRoute
      }

      return result
    }
  }

  // MARK: - Success Cases
  @Test("UseCase execute 메서드 정상 동작 확인", .tags(.success, .usecase))
  func executeSuccess() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.mockResult = mockRouteInfo

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    // When
    let result = try await useCase.execute(
      from: testStartCoord,
      to: testDestCoord,
      option: .walking
    )

    // Then
    #expect(result.distance == mockRouteInfo.distance)
    #expect(result.duration == mockRouteInfo.duration)
    #expect(result.paths.count == mockRouteInfo.paths.count)
    #expect(mockRepository.callHistory.count == 1)

    let lastCall = mockRepository.callHistory.last!
    #expect(lastCall.2 == .walking)
  }

  @Test("getRoute 메서드 Repository 위임 확인", .tags(.success, .usecase))
  func getRouteDelegation() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.mockResult = mockRouteInfo

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    // When
    let result = try await useCase.getRoute(
      from: testStartCoord,
      to: testDestCoord,
      option: .walking
    )

    // Then
    #expect(result == mockRouteInfo)
    #expect(mockRepository.callHistory.count == 1)
  }

  @Test("다양한 경로 옵션 처리 확인", .tags(.success, .route))
  func differentRouteOptions() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.mockResult = mockRouteInfo

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    let testOptions: [RouteOption] = [.walking, .trafast, .traoptimal]

    // When
    for option in testOptions {
      let _ = try await useCase.execute(
        from: testStartCoord,
        to: testDestCoord,
        option: option
      )
    }

    // Then
    #expect(mockRepository.callHistory.count == testOptions.count)
    for (index, option) in testOptions.enumerated() {
      #expect(mockRepository.callHistory[index].2 == option)
    }
  }

  // MARK: - Error Cases
  @Test("네트워크 에러 전파 확인", .tags(.error, .usecase))
  func networkErrorPropagation() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.shouldThrowError = DirectionError.networkError("Test network error")

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    // When & Then
    await #expect(throws: DirectionError.self) {
      try await useCase.execute(
        from: testStartCoord,
        to: testDestCoord,
        option: .walking
      )
    }
  }

  @Test("경로 없음 에러 처리 확인", .tags(.error, .route))
  func noRouteError() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.shouldThrowError = DirectionError.noRoute

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    // When & Then
    await #expect(throws: DirectionError.noRoute) {
      try await useCase.execute(
        from: testStartCoord,
        to: testDestCoord,
        option: .walking
      )
    }
  }

  @Test("잘못된 좌표 에러 처리 확인", .tags(.error, .route))
  func invalidCoordinatesError() async throws {
    // Given
    let mockRepository = MockDirectionRepository()
    mockRepository.shouldThrowError = DirectionError.invalidCoordinates

    let useCase = withDependencies {
      $0.directionRepository = mockRepository
    } operation: {
      RouteUseCaseImpl()
    }

    let invalidCoord = CLLocationCoordinate2D(latitude: 999, longitude: 999)

    // When & Then
    await #expect(throws: DirectionError.invalidCoordinates) {
      try await useCase.execute(
        from: invalidCoord,
        to: testDestCoord,
        option: .walking
      )
    }
  }

  // MARK: - Dependencies Tests
  @Test("Dependencies 주입 정상 동작 확인", .tags(.dependencies))
  func dependencies주입_정상동작() async throws {
    // Given & When & Then - withDependencies 블록으로 의존성 주입 테스트
    let result = withDependencies {
      $0.directionRepository = MockDirectionRepository()
    } operation: {
      let useCase = RouteUseCaseImpl()
      return useCase
    }

    #expect(result != nil)
  }
}
