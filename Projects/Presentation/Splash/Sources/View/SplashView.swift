//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 3/1/26.
//

import SwiftUI

import DesignSystem
import ComposableArchitecture


public struct SplashView: View {
  @Bindable var store: StoreOf<SplashReducer>
  @State private var symbolScale: CGFloat = 1.0
  @State private var symbolScaleX: CGFloat = 1.0
  @State private var symbolScaleY: CGFloat = 1.0
  @State private var symbolRotation: Double = 0
  @State private var symbolOffsetX: CGFloat = 0
  @State private var symbolOpacity: Double = 1
  @State private var wordmarkOpacity: Double = 0
  @State private var wordmarkOffsetX: CGFloat = 14

  private enum Constants {
    static let symbolLargeSize = CGSize(width: 84, height: 77)
    static let symbolSmallSize = CGSize(width: 30, height: 28)
    static let wordmarkSize = CGSize(width: 212, height: 38)
  }

  public init(store: StoreOf<SplashReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.gray100
        .ignoresSafeArea()

      ZStack {
        Image(asset: .appLogo)
          .resizable()
          .scaledToFit()
          .frame(
            width: Constants.symbolLargeSize.width,
            height: Constants.symbolLargeSize.height
          )
          .scaleEffect(x: symbolScale * symbolScaleX, y: symbolScale * symbolScaleY)
          .rotationEffect(.degrees(symbolRotation))
          .offset(x: symbolOffsetX)
          .opacity(symbolOpacity)

        Image(asset: .logo)
          .resizable()
          .scaledToFit()
          .frame(
            width: Constants.wordmarkSize.width,
            height: Constants.wordmarkSize.height
          )
          .opacity(wordmarkOpacity)
          .offset(x: wordmarkOffsetX)
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
      runAnimation()
    }
  }
}

private extension SplashView {
  func runAnimation() {
    symbolScale = 1.0
    symbolScaleX = 1.0
    symbolScaleY = 1.0
    symbolRotation = 0
    symbolOffsetX = 0
    symbolOpacity = 1
    wordmarkOpacity = 0
    wordmarkOffsetX = 14

    withAnimation(.easeInOut(duration: 0.32).delay(0.28)) {
      symbolRotation = 24
    }

    withAnimation(.spring(response: 0.28, dampingFraction: 0.82).delay(0.82)) {
      symbolRotation = 0
    }

    withAnimation(.easeInOut(duration: 0.26).delay(1.28)) {
      symbolScale = Constants.symbolSmallSize.width / Constants.symbolLargeSize.width
    }

    withAnimation(.easeInOut(duration: 0.26).delay(1.78)) {
      symbolOffsetX = -54
    }

    withAnimation(.easeOut(duration: 0.12).delay(1.96)) {
      symbolOpacity = 0
    }

    withAnimation(.easeOut(duration: 0.2).delay(2.04)) {
      wordmarkOpacity = 1
      wordmarkOffsetX = 0
    }
  }
}
