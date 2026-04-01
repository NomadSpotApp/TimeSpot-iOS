//
//  RemainingTimeCard.swift
//  Home
//
//  Created by Wonji Suh  on 3/30/26.
//

import SwiftUI
import DesignSystem
import Entity
import Utill

/// 예상 남은 시간 및 거리 정보를 표시하는 카드
public struct RemainingTimeCard: View {
  let routeInfo: RouteInfo
  let destinationName: String

  public init(
    routeInfo: RouteInfo,
    destinationName: String
  ) {
    self.routeInfo = routeInfo
    self.destinationName = destinationName
  }

  public var body: some View {
    VStack(spacing: 0) {
      cardContent()
    }
    .background(Color.white)
    .cornerRadius(20)
    .shadow(
      color: Color.black.opacity(0.1),
      radius: 10,
      x: 0,
      y: 2
    )
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
  }

  @ViewBuilder
  private func cardContent() -> some View {
    VStack(spacing: 16) {
      // 상단 목적지 정보
      headerSection()

      // 중앙 시간/거리 정보
      timeDistanceSection()

      // 하단 예상 도착 시간
      arrivalTimeSection()
    }
    .padding(20)
  }

  @ViewBuilder
  private func headerSection() -> some View {
    HStack {
      Image(systemName: "location.fill")
        .foregroundColor(.blue)
        .font(.system(size: 16, weight: .medium))

      Text(destinationName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.primary)

      Spacer()

      Text("도보")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
  }

  @ViewBuilder
  private func timeDistanceSection() -> some View {
    HStack(spacing: 32) {
      // 남은 시간 (가장 크게)
      VStack(alignment: .leading, spacing: 4) {
        Text("남은 시간")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)

        Text(routeInfo.duration.formattedDuration)
          .font(.system(size: 32, weight: .bold))
          .foregroundColor(.primary)
      }

      Spacer()

      // 남은 거리
      VStack(alignment: .trailing, spacing: 4) {
        Text("남은 거리")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)

        Text(routeInfo.distance.formattedDistance)
          .font(.system(size: 20, weight: .semibold))
          .foregroundColor(.blue)
      }
    }
  }

  @ViewBuilder
  private func arrivalTimeSection() -> some View {
    HStack {
      Image(systemName: "clock")
        .foregroundColor(.green)
        .font(.system(size: 14))

      Text("\(estimatedArrivalTime) 도착 예정")
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(.primary)

      Spacer()
    }
    .padding(.top, 8)
    .overlay(
      Rectangle()
        .frame(height: 1)
        .foregroundColor(Color.gray.opacity(0.2)),
      alignment: .top
    )
  }

  /// 예상 도착 시간 계산
  private var estimatedArrivalTime: String {
    let now = Date()
    let arrivalDate = now.addingTimeInterval(TimeInterval(routeInfo.duration * 60))

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "HH:mm"

    return formatter.string(from: arrivalDate)
  }
}

#Preview {
  VStack {
    Spacer()

    RemainingTimeCard(
      routeInfo: RouteInfo(
        paths: [],
        distance: 1250, // 1.25km로 표시됨
        duration: 15,   // 15분
        tollFare: 0,
        taxiFare: 0
      ),
      destinationName: "서울학도병참전기념비역"
    )
  }
  .background(Color.gray.opacity(0.1))
  .edgesIgnoringSafeArea(.all)
}

#Preview("Long Distance") {
  VStack {
    Spacer()

    RemainingTimeCard(
      routeInfo: RouteInfo(
        paths: [],
        distance: 2500, // 2.5km로 표시됨
        duration: 75,   // 1시간 15분으로 표시됨
        tollFare: 0,
        taxiFare: 0
      ),
      destinationName: "홍대입구역"
    )
  }
  .background(Color.gray.opacity(0.1))
  .edgesIgnoringSafeArea(.all)
}