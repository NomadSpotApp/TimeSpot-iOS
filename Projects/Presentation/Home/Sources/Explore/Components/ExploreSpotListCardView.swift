//
//  ExploreSpotListCardView.swift
//  Home
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher
import Utill
import ComposableArchitecture
import LogMacro

struct ExploreSpotListCardView: View {
  let spot: ExploreMapSpot
  let store: StoreOf<ExploreListFeature>

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
          titleRow
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: titleMinHeight, alignment: .topLeading)
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
    .onAppear {
    }
    .onChange(of: spot.id) { _ in
    }
  }

  @ViewBuilder
  private var titleRow: some View {
    HStack(alignment: .top, spacing: 6) {
      Text(formattedDisplayName)
        .font(.pretendardFontFamily(family: .SemiBold, size: 18))
        .foregroundStyle(.staticBlack)
        .lineLimit(titleLineLimit)
        .layoutPriority(1)

      if !spot.subtitle.isEmpty {
        Text(spot.subtitle)
          .font(.pretendardFontFamily(family: .Medium, size: 14))
          .foregroundStyle(.gray700)
          .lineLimit(1)
          .fixedSize()
          .padding(.top, 2)
      }

      Spacer(minLength: 0)
    }
  }

  private var titleLineLimit: Int {
    spot.name.count > 7 ? 2 : 1
  }

  private var titleMinHeight: CGFloat {
    spot.name.count > 7 ? 48 : 24
  }

  private var formattedDisplayName: String {
    let formatted = spot.name.formattedPlaceNameForDisplay

    guard spot.name.count > 7 else {
      return formatted
    }

    let characters = Array(formatted)
    let threshold = min(7, characters.count)

    if let splitIndex = characters.indices.dropFirst(threshold).first(where: { characters[$0] == " " }) {
      let left = String(characters[..<splitIndex])
      let right = String(characters[characters.index(after: splitIndex)...])
      return "\(left)\n\(right)"
    }

    let splitIndex = formatted.index(formatted.startIndex, offsetBy: threshold)
    return "\(formatted[..<splitIndex])\n\(formatted[splitIndex...])"
  }

  @ViewBuilder
  private func spotImage(for spot: ExploreMapSpot) -> some View {
    if let url = imageURL(for: spot) {
      KFImage(url)
        .placeholder {
          imagePlaceholder()
        }
        .cacheMemoryOnly(false)
        .diskCacheExpiration(.days(7))
        .memoryCacheExpiration(.seconds(300))
        .loadDiskFileSynchronously()
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
    // 1. 기존 spot.imageURL이 있으면 우선 사용
    if let imageURL = spot.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
       !imageURL.isEmpty {
      if let url = URL(string: imageURL) {
        return url
      }
      let encoded = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      return encoded.flatMap(URL.init(string:))
    }


    return nil
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
