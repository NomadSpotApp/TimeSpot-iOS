//
//  ExploreSpotListCardView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher

struct ExploreSpotListCardView: View {
  let spot: ExploreMapSpot

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      VStack(alignment: .leading, spacing: 0) {
        if !spot.badgeText.isEmpty {
          Text(spot.badgeText)
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.orange800)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.orange200)
            .clipShape(Capsule())
            .padding(.bottom, 12)
        }

        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text(spot.name)
            .pretendardFont(family: .SemiBold, size: 17)
            .foregroundStyle(.staticBlack)
            .lineLimit(2)
            .layoutPriority(1)

          Text(spot.subtitle)
            .pretendardCustomFont(textStyle: .caption)
            .foregroundStyle(.gray500)
            .lineLimit(1)
            .fixedSize()
        }
        .padding(.bottom, 8)

        HStack(spacing: 10) {
          if !spot.statusText.isEmpty {
            Text(spot.statusText)
              .pretendardCustomFont(textStyle: .body2Medium)
              .foregroundStyle(.gray700)
          }

          if !spot.closingText.isEmpty {
            Text(spot.closingText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray500)
              .lineLimit(1)
              .minimumScaleFactor(0.9)
          }
        }
        .padding(.bottom, 10)

        HStack(spacing: 8) {
          if !spot.distanceText.isEmpty {
            Text(spot.distanceText)
              .pretendardFont(family: .SemiBold, size: 15)
              .foregroundStyle(.staticBlack)
          }

          if !spot.walkTimeText.isEmpty {
            Text(spot.walkTimeText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray650)
              .lineLimit(1)
              .minimumScaleFactor(0.9)
          }
        }

      }
      .frame(maxWidth: .infinity, alignment: .leading)

      spotImage(for: spot)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 22))
    .overlay {
      RoundedRectangle(cornerRadius: 22)
        .stroke(.gray300.opacity(0.9), lineWidth: 1)
    }
  }

  @ViewBuilder
  private func spotImage(for spot: ExploreMapSpot) -> some View {
    if let url = imageURL(for: spot) {
      KFImage(url)
        .placeholder {
          imagePlaceholder()
        }
        .cancelOnDisappear(true)
        .fade(duration: 0.2)
        .resizable()
        .scaledToFill()
        .frame(width: 92, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    } else {
      imagePlaceholder()
    }
  }

  private func imageURL(for spot: ExploreMapSpot) -> URL? {
    guard let imageURL = spot.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
          !imageURL.isEmpty else {
      return nil
    }

    if let url = URL(string: imageURL) {
      return url
    }

    let encoded = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    return encoded.flatMap(URL.init(string:))
  }

  private func imagePlaceholder() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(.gray200)

      Image(systemName: "photo")
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(.gray500)
    }
    .frame(width: 92, height: 112)
  }
}
