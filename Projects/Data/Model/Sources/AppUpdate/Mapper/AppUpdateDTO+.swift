//
//  AppUpdateDTO+.swift
//  Model
//
//  Created by Roy on 2026-04-08.
//

import Foundation
import Entity

public extension AppStoreInfoDTO {
    func toEntity(currentVersion: String) -> AppUpdateInfo {
        let isUpdateAvailable = isNewerVersion(
            storeVersion: version,
            currentVersion: currentVersion
        )

        return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: version,
            releaseNotes: releaseNotes,
            appStoreUrl: trackViewUrl,
            isUpdateAvailable: isUpdateAvailable
        )
    }

    private func isNewerVersion(storeVersion: String, currentVersion: String) -> Bool {
        return storeVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
}