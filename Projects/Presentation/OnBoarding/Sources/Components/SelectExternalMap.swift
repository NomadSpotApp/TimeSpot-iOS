//
//  SelectExternalMap.swift
//  OnBoarding
//
//  Created by Wonji Suh  on 3/22/26.
//

import SwiftUI
import DesignSystem

public struct SelectExternalMap: View {
  private let title: String
  private let imageName: String
  private var isSelected: Bool = false


  public init(
    title: String,
    imageName: String,
    isSelected: Bool
  ) {
    self.title = title
    self.imageName = imageName
    self.isSelected = isSelected
  }

  public var body: some View {
    HStack {
      Image(assetName: imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 48, height: 48)

      Spacer()
        .frame(width: 20)

      Text(title)
        .pretendardCustomFont(textStyle: .titleRegular)
        .foregroundColor(.gray900)

      Spacer()

    }
    .padding(15)
    .background {
      RoundedRectangle(cornerRadius: 28)
        .fill(.clear)
        .stroke(isSelected ? .orange500 : .gray400, style: .init(lineWidth: 1))
        .background(isSelected ? .orange200 : .white)
        .cornerRadius(28)
    }

  }
}

