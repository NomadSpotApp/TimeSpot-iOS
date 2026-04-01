//
//  RouteNotificationView.swift
//  Home
//
//  Created by Wonji Suh  on 3/31/26.
//

import SwiftUI

import DesignSystem
import ComposableArchitecture


public struct RouteNotificationView: View {
  @Bindable var store: StoreOf<RouteNotificationFeature>

  public init(store: StoreOf<RouteNotificationFeature>) {
    self.store = store
  }

  public var body: some View {
    switch store.notificationType {
    case .fifteenMin:
      NotificationContentView(
        titlePart1: "역으로 출발하기까지\n",
        highlightText: "15분",
        titlePart3: " 남았어요!",
        subtitle: "지금 하는 활동을 차분히 마무리해 주세요.",
        image: .fifteenMinutesNotification,
        store: store,
        showBottomElements: true,
        isEndJourney: false
      )
    case .tenMin:
      NotificationContentView(
        titlePart1: "",
        highlightText: "10분",
        titlePart3: " 뒤면 역으로 출발해야 해요!",
        subtitle: "이제 슬슬 일어날 준비를 해볼까요?",
        image: .tenMinutesNotification,
        store: store,
        showBottomElements: true,
        isEndJourney: false
      )
    case .fiveMin:
      NotificationContentView(
        titlePart1: "",
        highlightText: "5분",
        titlePart3: " 뒤면 역으로 슬슬 일어날\n채비를 할 시간이에요.",
        subtitle: "잠시 후 출발할 수 있도록 미리 준비해주세요.",
        image: .fiveMinutesNotification,
        store: store,
        showBottomElements: true,
        isEndJourney: false
      )
    case .now:
      NotificationContentView(
        titlePart1: "",
        highlightText: "지금 바로",
        titlePart3: " 출발해야 해요!",
        subtitle: "지금 바로 역으로 향해야 15분 전에\n플랫폼에 도착할 수 있어요.",
        image: .startNotification,
        store: store,
        showBottomElements: true,
        isEndJourney: false
      )
    case .endJourney:
      NotificationContentView(
        titlePart1: "무사히 탑승하셨나요?",
        highlightText: "",
        titlePart3: "",
        subtitle: "오늘 대기 시간이 맞진 여행이 되었어요.\n이제 편안한 여정 되세요!",
        image: .endJourney,
        store: store,
        showBottomElements: false,
        isEndJourney: true
      )
    }
  }
}

