//
//  TravelHistoryCardView.swift
//  Profile
//
//  Created by Wonji Suh on 3/25/26.
//

import SwiftUI

import DesignSystem
import Utill
import Entity


public struct TravelHistoryCardView: View {
  let item: TravelHistoryCardItem

  public init(item: TravelHistoryCardItem) {
    self.item = item
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(item.visitedAt.formattedDateToString())
        .pretendardCustomFont(textStyle: .caption)
        .foregroundStyle(.gray800)

      Spacer()
        .frame(height: 10)

      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(item.placeName)
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.staticBlack)

          Text("방문 장소")
            .pretendardCustomFont(textStyle: .body2Medium)
            .foregroundStyle(.gray800)
        }

        Spacer()

        Image(asset: .travelLine)
          .resizable()
          .scaledToFit()
          .frame(width: 123, height: 6)
          .padding(.vertical, 9)

        Spacer()
          .frame(width: 24)

        VStack(alignment: .trailing, spacing: 4) {
          Text(item.departureName)
            .pretendardCustomFont(textStyle: .titleRegular)
            .foregroundStyle(.staticBlack)
            .lineLimit(1)
            .minimumScaleFactor(0.9)

          Text("출발역")
            .pretendardCustomFont(textStyle: .body2Medium)
            .foregroundStyle(.gray800)
            .lineLimit(1)
        }
        .frame(width: 72, alignment: .trailing)
      }

      Spacer()
        .frame(height: 20)

      Path { path in
        path.move(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: 330, y: 0.5))
      }
      .stroke(
        .gray400,
        style: StrokeStyle(
          lineWidth: 1,
          lineCap: .round,
          dash: [1, 4]
        )
      )
      .frame(height: 1)

      Spacer()
        .frame(height: 20)

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          Text("총 여정 시간")
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.gray800)

          Text(item.durationText)
            .pretendardCustomFont(textStyle: .bodyMedium)
            .foregroundStyle(.staticBlack)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 6) {
          Text("열차 출발")
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.gray800)

          Text(item.departureTimeText)
            .pretendardCustomFont(textStyle: .bodyBold)
            .foregroundStyle(.staticBlack)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.gray200)
        .overlay {
          RoundedRectangle(cornerRadius: 24)
            .stroke(.neutral200, style: .init(lineWidth: 1))
        }
    )
  }
}
