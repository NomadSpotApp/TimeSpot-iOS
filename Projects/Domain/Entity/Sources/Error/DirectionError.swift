//
//  DirectionError.swift
//  Entity
//
//  Created by Wonji Suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import Foundation

public enum DirectionError: Error, LocalizedError, Sendable, Equatable {
    case invalidResponse
    case noRoute
    case networkError(String)
    case invalidCoordinates
    case apiKeyError
    case decodingError
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .noRoute:
            return "경로를 찾을 수 없습니다."
        case .networkError(let errorMessage):
            return "네트워크 오류: \(errorMessage)"
        case .invalidCoordinates:
            return "잘못된 좌표입니다."
        case .apiKeyError:
            return "API 키 오류입니다."
        case .decodingError:
            return "데이터 파싱 오류가 발생했습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }

    public static func from(_ error: Error) -> DirectionError {
        if let directionError = error as? DirectionError {
            return directionError
        }
        return .networkError(error.localizedDescription)
    }
}