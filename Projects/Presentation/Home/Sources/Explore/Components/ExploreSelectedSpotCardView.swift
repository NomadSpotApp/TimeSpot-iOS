//
//  ExploreSelectedSpotCardView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher

struct ExploreSelectedSpotCardView: View {
  let currentSpot: ExploreMapSpot
  let adjacentSpot: ExploreMapSpot?
  let currentOffset: CGFloat
  let adjacentOffset: CGFloat?
  let cardOpacity: Double
  let onRouteTap: () -> Void
  let onDragChanged: (DragGesture.Value) -> Void
  let onDragEnded: (DragGesture.Value) -> Void

  var body: some View {
    ZStack {
      if let adjacentSpot, let adjacentOffset {
        cardContent(for: adjacentSpot)
          .offset(x: adjacentOffset)
          .allowsHitTesting(false)
      }

      cardContent(for: currentSpot)
        .offset(x: currentOffset)
        .opacity(cardOpacity)
    }
    .gesture(
      DragGesture(minimumDistance: 20)
        .onChanged(onDragChanged)
        .onEnded(onDragEnded)
    )
  }

  private func cardContent(for spot: ExploreMapSpot) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          if !spot.badgeText.isEmpty {
            Text(spot.badgeText)
              .pretendardCustomFont(textStyle: .caption)
              .foregroundStyle(.orange800)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(.orange200)
              .clipShape(Capsule())
              .padding(.bottom, 8)
          }

          HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(spot.name)
              .pretendardFont(family: .SemiBold, size: 18)
              .foregroundStyle(.staticBlack)
              .lineLimit(1)

            Text(spot.subtitle)
              .pretendardCustomFont(textStyle: .caption)
              .foregroundStyle(.gray650)
              .lineLimit(1)
          }
          .padding(.bottom, 10)

          if !spot.statusText.isEmpty || !spot.closingText.isEmpty {
            HStack(spacing: 12) {
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
              }
            }
            .padding(.bottom, 10)
          }

          if !spot.distanceText.isEmpty || !spot.walkTimeText.isEmpty {
            HStack(spacing: 8) {
              if !spot.distanceText.isEmpty {
                Text(spot.distanceText)
                  .pretendardCustomFont(textStyle: .bodyBold)
                  .foregroundStyle(.staticBlack)
              }

              if !spot.walkTimeText.isEmpty {
                Text(spot.walkTimeText)
                  .pretendardCustomFont(textStyle: .bodyRegular)
                  .foregroundStyle(.gray650)
                  .lineLimit(1)
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        spotImage(for: spot)
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 20)

      Button(action: onRouteTap) {
        Text("경로 확인하기")
          .pretendardCustomFont(textStyle: .bodyBold)
          .foregroundStyle(.staticWhite)
          .frame(maxWidth: .infinity)
          .frame(height: 55)
          .background(.navy900)
          .clipShape(RoundedRectangle(cornerRadius: 25))
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
    }
    .background(.staticWhite)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
    .transaction { transaction in
      transaction.animation = nil
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
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(.gray500)
    }
    .frame(width: 92, height: 112)
  }
}
