//
//  LocationPermissionOverlay.swift
//  Home
//
//  Created by Roy on 2026-03-11
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import UIKit

// 위치 권한 거부 시 표시할 오버레이 컴포넌트
public struct LocationPermissionOverlay: View {
    let onSettingsButtonTapped: () -> Void
    let onRetryButtonTapped: () -> Void

    public init(
        onSettingsButtonTapped: @escaping () -> Void,
        onRetryButtonTapped: @escaping () -> Void
    ) {
        self.onSettingsButtonTapped = onSettingsButtonTapped
        self.onRetryButtonTapped = onRetryButtonTapped
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("위치 권한이 필요합니다")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("TimeSpot이 근처 장소를 찾고 지도에\n현재 위치를 표시하기 위해 위치 정보를 사용합니다.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            VStack(spacing: 12) {
                Button("설정에서 위치 권한 허용하기") {
                    onSettingsButtonTapped()
                }
                .buttonStyle(.borderedProminent)

                Button("다시 시도") {
                    onRetryButtonTapped()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}

// 설정 앱으로 이동하는 헬퍼 함수
extension LocationPermissionOverlay {
    public static func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

#Preview {
    LocationPermissionOverlay(
        onSettingsButtonTapped: {
            LocationPermissionOverlay.openSettings()
        },
        onRetryButtonTapped: {
            print("Retry tapped")
        }
    )
}