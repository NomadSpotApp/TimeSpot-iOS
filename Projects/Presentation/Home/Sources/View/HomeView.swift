//
//  HomeView.swift
//  Home
//
//  Created by Roy on 2026-03-11
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import NaverMapSDK
import ComposableArchitecture
import CoreLocation

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeReducer>

    public init(store: StoreOf<HomeReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            ZStack {
                // 네이버 지도 뷰
                NaverMapComponent(
                    locationPermissionStatus: store.locationPermissionStatus,
                    currentLocation: store.currentLocation
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 위치 권한 거부 시 오버레이
                if store.isLocationPermissionDenied {
                    LocationPermissionOverlay(
                        onSettingsButtonTapped: {
                            store.send(.view(.openSettings))
                        },
                        onRetryButtonTapped: {
                            store.send(.view(.retryLocationPermission))
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.locationPermissionStatus == .authorizedWhenInUse ||
                       store.locationPermissionStatus == .authorizedAlways {
                        Button("정확한 위치") {
                            store.send(.view(.requestFullAccuracy))
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                store.send(.view(.onAppear))
            }
            .onDisappear {
                store.send(.view(.onDisappear))
            }
            .alert($store.scope(state: \.alert, action: \.scope.alert))
        }
    }

}

// 네이버 지도를 SwiftUI에서 사용하기 위한 UIViewRepresentable 래퍼
struct NaverMapView: UIViewRepresentable {
    let locationPermissionStatus: CLAuthorizationStatus
    let currentLocation: CLLocation?

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()

        // 기본 지도 설정
        mapView.mapType = .basic
        mapView.isNightModeEnabled = false
        mapView.zoomLevel = 15

        // 위치 권한이 있으면 위치 표시 활성화
        if locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways {
            mapView.positionMode = .direction
            mapView.isLocationButtonEnabled = true
        }

        // 초기 위치 설정 (현재 위치가 있으면 현재 위치, 없으면 서울시청)
        let initialLocation: NMGLatLng
        if let location = currentLocation {
            initialLocation = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        } else {
            initialLocation = NMGLatLng(lat: 37.5666805, lng: 126.9784147) // 서울시청
        }

        let cameraPosition = NMFCameraPosition(initialLocation, zoom: 15)
        mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))

        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        // 위치 권한 상태에 따른 위치 표시 모드 업데이트
        if locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways {
            uiView.positionMode = .direction
            uiView.isLocationButtonEnabled = true

            // 현재 위치로 카메라 이동 (위치가 업데이트된 경우)
            if let location = currentLocation {
                let coordinate = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
                let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
                cameraUpdate.animation = .easeIn
                uiView.moveCamera(cameraUpdate)
            }
        } else {
            uiView.positionMode = .disabled
            uiView.isLocationButtonEnabled = false
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeReducer.State()) {
            HomeReducer()
        }
    )
}
