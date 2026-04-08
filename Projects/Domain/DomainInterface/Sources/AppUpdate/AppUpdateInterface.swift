//
//  AppUpdateInterface.swift
//  DomainInterface
//
//  Created by Roy on 2026-04-08.
//

import Foundation
import Entity
import ComposableArchitecture

/// App Update 관련 비즈니스 로직을 위한 Interface 프로토콜
public protocol AppUpdateInterface: Sendable {
    func checkForUpdate() async throws -> AppUpdateInfo
}

/// AppUpdate Repository의 DependencyKey 구조체
public struct AppUpdateRepositoryDependency: DependencyKey {
    public static var liveValue: AppUpdateInterface {
        AppUpdateRepositoryImpl()
    }

    public static var testValue: AppUpdateInterface {
        AppUpdateRepositoryImpl()
    }

    public static var previewValue: AppUpdateInterface = liveValue
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
    var appUpdateRepository: AppUpdateInterface {
        get { self[AppUpdateRepositoryDependency.self] }
        set { self[AppUpdateRepositoryDependency.self] = newValue }
    }
}

// MARK: - Default Implementation
public final class AppUpdateRepositoryImpl: AppUpdateInterface {
    private let urlSession: URLSession
    private let bundleId: String

    public init(
        urlSession: URLSession = .shared,
        bundleId: String? = nil
    ) {
        self.urlSession = urlSession
        self.bundleId = bundleId ?? Bundle.main.bundleIdentifier ?? ""
    }

    public func checkForUpdate() async throws -> AppUpdateInfo {
        guard !bundleId.isEmpty else {
            throw AppUpdateError.invalidBundleId
        }

        let currentVersion = getCurrentAppVersion()
        let appStoreInfo = try await fetchAppStoreInfo()

        return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: appStoreInfo.version,
            releaseNotes: appStoreInfo.releaseNotes,
            appStoreUrl: appStoreInfo.trackViewUrl,
            isUpdateAvailable: isNewerVersion(storeVersion: appStoreInfo.version, currentVersion: currentVersion)
        )
    }

    // MARK: - Private Methods

    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func isNewerVersion(storeVersion: String, currentVersion: String) -> Bool {
        return storeVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    private func fetchAppStoreInfo() async throws -> iTunesAppInfo {
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else {
            throw AppUpdateError.invalidBundleId
        }

        do {
            let (data, _) = try await urlSession.data(from: url)
            let response = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)

            guard let appInfo = response.results.first else {
                throw AppUpdateError.appNotFound
            }

            return appInfo
        } catch let decodingError as DecodingError {
            throw AppUpdateError.decodingError
        } catch {
            throw AppUpdateError.from(error)
        }
    }
}