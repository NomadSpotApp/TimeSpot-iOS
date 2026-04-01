//
//  NotificationContentView.swift
//  Home
//
//  Created by Wonji Suh  on 4/1/26.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture

public struct NotificationContentView: View {
  private let titlePart1: String
  private let highlightText: String
  private let titlePart3: String
  private let subtitle: String
  private let image: ImageAsset
  private let store: StoreOf<RouteNotificationFeature>
  private let showBottomElements: Bool
  private let isEndJourney: Bool

  public init(
    titlePart1: String,
    highlightText: String,
    titlePart3: String,
    subtitle: String,
    image: ImageAsset,
    store: StoreOf<RouteNotificationFeature>,
    showBottomElements: Bool,
    isEndJourney: Bool = false
  ) {
    self.titlePart1 = titlePart1
    self.highlightText = highlightText
    self.titlePart3 = titlePart3
    self.subtitle = subtitle
    self.image = image
    self.store = store
    self.showBottomElements = showBottomElements
    self.isEndJourney = isEndJourney
  }

  public var body: some View {
    VStack(alignment: .center, spacing: 0) {
      // 상단 여백
      Spacer()
        .frame(height: 80)


      // 메인 타이틀
      if isEndJourney {
        // 여정 종료: 단순한 텍스트
        Text(titlePart1)
          .pretendardCustomFont(textStyle: .heading1)
          .foregroundStyle(.gray900)
          .multilineTextAlignment(.center)
      } else {
        // 기존 로직
        VStack(spacing: 0) {
          // titlePart1이 있고 줄바꿈이 있는 경우 (15분 케이스)
          if !titlePart1.isEmpty && titlePart1.contains("\n") {
            Text(titlePart1.replacingOccurrences(of: "\n", with: ""))
              .pretendardCustomFont(textStyle: .heading1)
              .foregroundStyle(.gray900)
              .multilineTextAlignment(.center)

            HStack(spacing: 0) {
              Text(highlightText)
                .pretendardCustomFont(textStyle: .heading1)
                .foregroundStyle(.orange800)

              Text(titlePart3)
                .pretendardCustomFont(textStyle: .heading1)
                .foregroundStyle(.gray900)
            }
          }
          // titlePart3가 있고 줄바꿈이 있는 경우 (5분 케이스)
          else if titlePart3.contains("\n") {
            let parts = titlePart3.components(separatedBy: "\n")

            HStack(spacing: 0) {
              Text(highlightText)
                .pretendardCustomFont(textStyle: .heading1)
                .foregroundStyle(.orange800)

              if parts.count > 0 {
                Text(parts[0])
                  .pretendardCustomFont(textStyle: .heading1)
                  .foregroundStyle(.gray900)
              }
            }

            if parts.count > 1 {
              Text(parts[1])
                .pretendardCustomFont(textStyle: .heading1)
                .foregroundStyle(.gray900)
                .multilineTextAlignment(.center)
            }
          }
          // 그 외의 경우 (10분, 지금 바로 케이스) - 한 줄로 표시
          else {
            HStack(spacing: 0) {
              Text(highlightText)
                .pretendardCustomFont(textStyle: .heading1)
                .foregroundStyle(.orange800)

              if !titlePart3.isEmpty {
                Text(titlePart3)
                  .pretendardCustomFont(textStyle: .heading1)
                  .foregroundStyle(.gray900)
              }
            }
          }
        }
        .multilineTextAlignment(.center)
      }


      Spacer()
        .frame(height: 16)

      // 서브 타이틀
      Text(subtitle)
        .pretendardCustomFont(textStyle: .bodyMedium)
        .foregroundStyle(.gray800)
        .multilineTextAlignment(.center)
        .lineLimit(nil)

      Spacer()
        .frame(height: 24)

      Image(asset: image)
        .resizable()
        .scaledToFit()

      if isEndJourney {
        // 여정 종료: 종료하기 버튼만 표시
        Spacer()
          .frame(height: 40)

        RouteNotificationButton(
          title: "종료하기",
          backgroundColor: .navy900,
          foregroundColor: .white,
          action: { store.send(.view(.closeButtonTapped)) }
        )
        .padding(.horizontal, 24)

        Spacer()
          .frame(height: 40)
      } else if showBottomElements {
        Spacer()
          .frame(height: 28)

        // 열차 시간
        Text(store.formattedDepartureTime)
          .pretendardCustomFont(textStyle: .bodyMedium)
          .foregroundStyle(.gray800)

        Spacer()
          .frame(height: 16)

        // 버튼들
        VStack(spacing: 12) {
          RouteNotificationButton(
            title: "역으로 출발하기",
            backgroundColor: .navy900,
            foregroundColor: .white,
            action: { store.send(.view(.departureButtonTapped)) }
          )

          RouteNotificationButton(
            title: "종료하기",
            backgroundColor: .gray200,
            foregroundColor: .gray800,
            action: { store.send(.view(.closeButtonTapped)) }
          )
        }
        .padding(.horizontal, 16)

        Spacer()
          .frame(height: 32)
      } else {
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.white)
    .edgesIgnoringSafeArea(.all)
  }
}
