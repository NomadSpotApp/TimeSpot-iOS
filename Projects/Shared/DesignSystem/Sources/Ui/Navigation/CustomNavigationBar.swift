//
//  CustomNavigationBar.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 3/25/26.
//

import SwiftUI

public struct CustomNavigationBar: View {
  private var title: String
  private var leftImage: ImageAsset
  private var rightImage: ImageAsset
  private var leftAction: () -> Void
  private var rightAction: () -> Void

  public init(
    title: String,
    leftImage: ImageAsset,
    rightImage: ImageAsset,
    leftAction: @escaping () -> Void,
    rightAction: @escaping () -> Void
  ) {
    self.title = title
    self.leftImage = leftImage
    self.rightImage = rightImage
    self.leftAction = leftAction
    self.rightAction = rightAction
  }


  public var body: some View {
    HStack {
      Image(asset: leftImage)
        .resizable()
        .scaledToFit()
        .frame(width: 60, height: 60)
        .onTapGesture { leftAction() }


      Spacer()


      Text(title)
        .pretendardCustomFont(textStyle: .titleBold)
        .foregroundStyle(.staticBlack)


      Spacer()

      Image(asset: rightImage)
        .resizable()
        .scaledToFit()
        .frame(width: 60, height: 60)
        .onTapGesture { rightAction() }


    }
  }
}
