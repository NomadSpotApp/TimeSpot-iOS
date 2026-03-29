//
//  SettingMenuRowView.swift
//  Profile
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

import DesignSystem

public struct SettingMenuRowView: View {
  enum Accessory: Equatable {
    case chevron
    case dropdown
    case none
  }

  private let title: String
  private let trailingText: String?
  private let accessory: Accessory
  private let showsDivider: Bool
  private let action: () -> Void

   init(
    title: String,
    trailingText: String? = nil,
    accessory: Accessory = .chevron,
    showsDivider: Bool = true,
    action: @escaping () -> Void = {}
  ) {
    self.title = title
    self.trailingText = trailingText
    self.accessory = accessory
    self.showsDivider = showsDivider
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Text(title)
            .pretendardCustomFont(textStyle: .bodyMedium)
            .foregroundStyle(.gray900)

          Spacer(minLength: 12)

          if let trailingText {
            Text(trailingText)
              .pretendardCustomFont(textStyle: .bodyMedium)
              .foregroundStyle(.gray550)
              .lineLimit(1)
          }

          accessoryView
        }
        .frame(height: 52)

        if showsDivider {
          Rectangle()
            .fill(.gray300)
            .frame(height: 1)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var accessoryView: some View {
    switch accessory {
    case .chevron:
      Image(systemName: "chevron.right")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.gray550)
        .frame(width: 8, height: 12)

    case .dropdown:
      Image(systemName: "chevron.down")
        .font(.system(size: 15, weight: .medium))
        .frame(width: 8, height: 12)
        .foregroundStyle(.gray550)

    case .none:
      EmptyView()
    }
  }
}
