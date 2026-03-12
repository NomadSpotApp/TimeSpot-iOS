//
//  HomeView.swift
//  Home
//
//  Created by wonji suh on 2026-03-12
//  Copyright © 2026 TimeSpot, Ltd., All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CoreLocation
import Entity

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeReducer>

    public init(store: StoreOf<HomeReducer>) {
        self.store = store
    }

    public var body: some View {
      ZStack {
          // 네이버 지도 뷰
          NaverMapComponent(
              locationPermissionStatus: store.locationPermissionStatus,
              currentLocation: store.currentLocation,
              routeInfo: store.routeInfo,
              destination: store.selectedDestination,
              returnToLocation: store.shouldReturnToCurrentLocation
          )
          .ignoresSafeArea(.all)
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

          // 🎯 네이버 스타일 위치 버튼 (우측 하단)
          VStack {
              Spacer()
              HStack {
                  Spacer()

                  // 네이버 스타일 위치 버튼
                  Button(action: {
                      store.send(.view(.returnToCurrentLocation))
                  }) {
                      Image(systemName: "location.fill")
                          .font(.system(size: 18, weight: .medium))
                          .foregroundColor(.blue)
                          .frame(width: 44, height: 44)
                          .background(Color.white)
                          .clipShape(Circle())
                          .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                  }
                  .padding(.trailing, 16)
                  .padding(.bottom, 120)
              }
          }

          // 길찾기 컨트롤 UI
          VStack {
              // 경로 정보 표시 (상단으로 이동)
              if let routeInfo = store.routeInfo,
                 let destination = store.selectedDestination {
                  routeInfoCard(routeInfo: routeInfo, destination: destination)
                      .padding(.horizontal)
                      .padding(.top, 50) // 상단 패딩으로 변경
              }

              Spacer()

              // 길찾기 버튼들
              HStack(spacing: 12) {
                  if store.currentLocation != nil && !store.isLocationPermissionDenied {
                      // 강남역으로 도보 가기 버튼
                      Button(action: {
                          store.send(.view(.searchRouteToGangnam))
                      }) {
                          HStack(spacing: 6) {
                              Image(systemName: "figure.walk")
                              Text("강남역으로")
                          }
                          .font(.system(size: 14, weight: .semibold))
                          .foregroundColor(.white)
                          .padding(.horizontal, 16)
                          .padding(.vertical, 10)
                          .background(Color.blue)
                          .cornerRadius(20)
                      }
                      .disabled(store.isLoadingRoute)

                      // 경로 초기화 버튼 (경로가 있을 때만)
                      if store.routeInfo != nil {
                          Button(action: {
                              store.send(.view(.clearRoute))
                          }) {
                              Image(systemName: "xmark.circle.fill")
                                  .font(.system(size: 14))
                                  .foregroundColor(.red)
                                  .padding(10)
                                  .background(Color.white)
                                  .cornerRadius(18)
                                  .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                          }
                      }
                  }
              }
              .padding(.horizontal)
              .padding(.bottom, 50)

              // 로딩 상태
              if store.isLoadingRoute {
                  HStack {
                      ProgressView()
                          .scaleEffect(0.8)
                      Text("경로를 찾는 중...")
                          .font(.caption)
                          .foregroundColor(.gray)
                  }
                  .padding()
                  .background(Color.white.opacity(0.9))
                  .cornerRadius(10)
                  .padding(.bottom, 30)
              }

              // 에러 메시지
              if let error = store.routeError {
                  Text("❌ \(error)")
                      .font(.caption)
                      .foregroundColor(.red)
                      .padding()
                      .background(Color.white.opacity(0.9))
                      .cornerRadius(10)
                      .padding(.horizontal)
                      .padding(.bottom, 30)
              }
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

    // MARK: - 경로 정보 카드
    private func routeInfoCard(routeInfo: RouteInfo, destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.red)
                Text(destination.name)
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                        Text("거리: \(formatDistance(routeInfo.distance))")
                            .font(.system(size: 14))
                    }

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                        Text("도보: \(routeInfo.duration)분")
                            .font(.system(size: 14))
                    }
                }

                Spacer()

                if routeInfo.tollFare > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("톨비: \(formatCurrency(routeInfo.tollFare))")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)

                        if routeInfo.taxiFare > 0 {
                            Text("택시비: \(formatCurrency(routeInfo.taxiFare))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Methods
    private func formatDistance(_ meters: Int) -> String {
        if meters < 1000 {
            return "\(meters)m"
        } else {
            let kilometers = Double(meters) / 1000.0
            return String(format: "%.1fkm", kilometers)
        }
    }

    private func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")원"
    }

}


#Preview {
    HomeView(
        store: Store(initialState: HomeReducer.State()) {
            HomeReducer()
        }
    )
}
