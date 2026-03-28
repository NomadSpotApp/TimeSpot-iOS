//
//  LocationPermissionManager.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 3/28/26.
//

import Foundation
import CoreLocation
import UIKit

// MARK: - Location Errors
public enum LocationError: Error, LocalizedError, Equatable {
    case permissionDenied
    case locationUnavailable
    case timeout
    case networkError
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "위치 권한이 거부되었습니다."
        case .locationUnavailable:
            return "위치 정보를 가져올 수 없습니다."
        case .timeout:
            return "위치 요청 시간이 초과되었습니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - LocationPermissionManager Protocol
public protocol LocationPermissionManagerProtocol: Sendable {
    var authorizationStatus: CLAuthorizationStatus { get async }
    var currentLocation: CLLocation? { get async }
    var locationError: String? { get async }

    func requestLocationPermission() async -> CLAuthorizationStatus
    func requestFullAccuracy() async
    func startLocationUpdates() async
    func stopLocationUpdates() async
    func requestCurrentLocation() async throws -> CLLocation?
    func isLocationServicesEnabled() async -> Bool
    func openLocationSettings()

    // 콜백 설정
    func setLocationUpdateCallback(_ callback: @escaping @Sendable (CLLocation) -> Void) async
    func setLocationErrorCallback(_ callback: @escaping @Sendable (Error) -> Void) async
}

// MARK: - LocationPermissionManager Implementation
@MainActor
public final class LocationPermissionManager: NSObject, ObservableObject, LocationPermissionManagerProtocol {

    // 싱글톤 인스턴스
    public static let shared = LocationPermissionManager()
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var locationError: String?

    private let locationManager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    private var locationTimeoutTask: Task<Void, Never>?

    // 지속적인 위치 업데이트 콜백 (MainActor 격리)
    @MainActor
    public var onLocationUpdate: ((CLLocation) -> Void)?
    @MainActor
    public var onLocationError: ((Error) -> Void)?

    public override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터 이상 이동시 업데이트
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - LocationPermissionManagerProtocol Implementation

    public func setLocationUpdateCallback(_ callback: @escaping @Sendable (CLLocation) -> Void) async {
        self.onLocationUpdate = callback
    }

    public func setLocationErrorCallback(_ callback: @escaping @Sendable (Error) -> Void) async {
        self.onLocationError = callback
    }

    // async/await을 사용한 위치 권한 요청
    public func requestLocationPermission() async -> CLAuthorizationStatus {
        let isLocationServicesEnabled = await Task.detached {
            CLLocationManager.locationServicesEnabled()
        }.value

        guard isLocationServicesEnabled else {
            locationError = "위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해 주세요."
            return .denied
        }

        // authorizationStatus는 델리게이트에서 업데이트된 값 사용
        switch authorizationStatus {
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                self.authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            locationError = "위치 권한이 거부되었습니다. 설정에서 허용해 주세요."
            return authorizationStatus
        case .authorizedWhenInUse, .authorizedAlways:
            return authorizationStatus
        @unknown default:
            locationError = "알 수 없는 위치 권한 상태입니다."
            return authorizationStatus
        }
    }

    // iOS 14+ 정확한 위치 권한 요청
    public func requestFullAccuracy() async {
        if #available(iOS 14.0, *) {
          do {
            try await locationManager.requestTemporaryFullAccuracyAuthorization(
              withPurposeKey: "TimeSpotLocationAccuracy"
            )
          } catch {
            locationError = "정확한 위치 권한 요청에 실패했습니다."
          }
        }
    }

    // 위치 업데이트 시작
    public func startLocationUpdates() async {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "위치 권한이 없습니다."
            return
        }
        #else
        guard authorizationStatus == .authorizedAlways else {
            locationError = "위치 권한이 없습니다."
            return
        }
        #endif

        locationManager.startUpdatingLocation()
    }

    // 위치 업데이트 중지
    public func stopLocationUpdates() async {
        locationManager.stopUpdatingLocation()
    }

    // async/await을 사용한 현재 위치 가져오기
    public func requestCurrentLocation() async throws -> CLLocation? {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "위치 권한이 없습니다."
            throw LocationError.permissionDenied
        }
        #else
        guard authorizationStatus == .authorizedAlways else {
            locationError = "위치 권한이 없습니다."
            throw LocationError.permissionDenied
        }
        #endif

        if let currentLocation {
            return currentLocation
        }

        if let cachedLocation = locationManager.location {
            self.currentLocation = cachedLocation
            return cachedLocation
        }

        if locationContinuation != nil {
            resumeLocationContinuation(with: .failure(LocationError.locationUnavailable))
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationTimeoutTask?.cancel()
            self.locationTimeoutTask = Task { [weak self] in
                guard let self else { return }
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                self.resumeLocationContinuation(with: .failure(LocationError.timeout))
            }

            if #available(iOS 14.0, *) {
                locationManager.requestLocation()
            } else {
                // iOS 14 이전에서는 잠시 업데이트하고 중지
                locationManager.startUpdatingLocation()
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await self.stopLocationUpdates()
                }
            }
        }
    }

    // 위치 서비스 사용 가능 여부
    public func isLocationServicesEnabled() async -> Bool {
        await Task.detached {
            CLLocationManager.locationServicesEnabled()
        }.value
    }

    public func openLocationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }

    // 권한 상태 문자열
    public var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined:
            return "권한 미결정"
        case .restricted:
            return "권한 제한됨"
        case .denied:
            return "권한 거부됨"
        case .authorizedAlways:
            return "항상 허용"
        case .authorizedWhenInUse:
            return "사용 중 허용"
        @unknown default:
            return "알 수 없음"
        }
    }

    private func resumeLocationContinuation(with result: Result<CLLocation?, Error>) {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil

        guard let continuation = locationContinuation else { return }
        locationContinuation = nil

        switch result {
        case .success(let location):
            continuation.resume(returning: location)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationPermissionManager: CLLocationManagerDelegate {

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.locationError = nil

            // 지속적인 위치 업데이트 콜백 호출
            self.onLocationUpdate?(location)

            // continuation이 있으면 결과 반환 (일회성 요청용)
            self.resumeLocationContinuation(with: .success(location))
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = "위치 업데이트 실패: \(error.localizedDescription)"

            // 지속적인 위치 업데이트 에러 콜백 호출
            self.onLocationError?(error)

            // continuation이 있으면 에러 반환 (일회성 요청용)
            self.resumeLocationContinuation(with: .failure(error))
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.locationError = nil

            // continuation이 있으면 권한 상태 반환
            if let continuation = self.authorizationContinuation {
                self.authorizationContinuation = nil
                continuation.resume(returning: status)
            }
        }
    }
}
