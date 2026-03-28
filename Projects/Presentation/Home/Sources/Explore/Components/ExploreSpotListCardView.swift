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

        VStack(alignment: .leading, spacing: 6) {
          titleText
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 8)

        HStack(spacing: 10) {
          if !spot.statusText.isEmpty {
            Text(spot.statusText)
              .pretendardCustomFont(textStyle: .body2Medium)
              .foregroundStyle(.gray700)
              .fixedSize()
          }

          if !spot.closingText.isEmpty {
            Text(spot.closingText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray750)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .truncationMode(.tail)
          }
        }
        .padding(.bottom, 10)

        HStack(spacing: 8) {
          if !spot.distanceText.isEmpty {
            Text(spot.distanceText)
              .pretendardFont(family: .SemiBold, size: 16)
              .foregroundStyle(.staticBlack)
              .fixedSize()
          }

          if !spot.walkTimeText.isEmpty {
            Text(spot.walkTimeText)
              .pretendardCustomFont(textStyle: .body2Regular)
              .foregroundStyle(.gray830)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .truncationMode(.tail)
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
        .stroke(.enableColor, lineWidth: 1)
    }
  }

  private var titleText: Text {
    let nameText = Text(spot.name)
      .font(.pretendardFontFamily(family: .SemiBold, size: 18))
      .foregroundColor(.staticBlack)

    guard !spot.subtitle.isEmpty else {
      return nameText
    }

    let subtitleText = Text(" \(spot.subtitle)")
      .font(.pretendardFontFamily(family: .Medium, size: 14))
      .foregroundColor(.gray700)

    return nameText + subtitleText
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
