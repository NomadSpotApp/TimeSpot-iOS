//
//  CustomModalModifier.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 3/19/26.
//

import SwiftUI

public enum ModalHeight {
  case fraction(CGFloat)
  case fixed(CGFloat)
  case auto
}

public struct CustomModalModifier<Item: Identifiable, ModalContent: View>: ViewModifier {
  @Binding var item: Item?
  let height: ModalHeight
  let showDragIndicator: Bool
  let modalContent: (Item) -> ModalContent

  @State private var dragOffset: CGSize = .zero
  @State private var isDragging: Bool = false
  @State private var modalOffset: CGFloat = 0

  // MARK: - Animation Constants
  private let slideDistance: CGFloat = 300
  private let dismissThreshold: CGFloat = 100
  private let slideAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
  private let dragAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)

  public init(
    item: Binding<Item?>,
    height: ModalHeight = .auto,
    showDragIndicator: Bool = true,
    @ViewBuilder modalContent: @escaping (Item) -> ModalContent
  ) {
    self._item = item
    self.height = height
    self.showDragIndicator = showDragIndicator
    self.modalContent = modalContent
  }

  public func body(content: Content) -> some View {
    GeometryReader { geometry in
      content
        .overlay(
          Group {
            if item != nil {
              modalOverlay(geometry: geometry)
            }
          }
        )
    }
  }

  // MARK: - Private Views
  @ViewBuilder
  private func modalOverlay(geometry: GeometryProxy) -> some View {
    ZStack {
      backgroundView
      modalContentView(geometry: geometry)
    }
    .ignoresSafeArea(.container, edges: .bottom)
  }

  private var backgroundView: some View {
    Color.black.opacity(0.4)
      .ignoresSafeArea()
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
      .onTapGesture { dismissModal() }
  }

  @ViewBuilder
  private func modalContentView(geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      Spacer()

      if let currentItem = item {
        VStack(spacing: 0) {
          dragIndicatorView
          modalContent(currentItem)
            .frame(height: modalHeightValue(for: geometry))
          safeAreaSpacer(geometry: geometry)
        }
        .background(.white)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: 20,
            topTrailingRadius: 20
          )
        )
        .offset(y: modalOffset + max(0, dragOffset.height))
        .animation(isDragging ? nil : dragAnimation, value: dragOffset)
        .animation(slideAnimation, value: modalOffset)
        .onAppear { presentModal() }
        .gesture(dragGesture)
      }
    }
  }

  @ViewBuilder
  private var dragIndicatorView: some View {
    if showDragIndicator {
      RoundedRectangle(cornerRadius: 2)
        .fill(Color.gray.opacity(0.3))
        .frame(width: 36, height: 4)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
  }

  private func safeAreaSpacer(geometry: GeometryProxy) -> some View {
    Spacer()
      .frame(height: geometry.safeAreaInsets.bottom)
  }

  // MARK: - Gesture
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        isDragging = true
        if value.translation.height > 0 {
          dragOffset = value.translation
        }
      }
      .onEnded { value in
        isDragging = false

        if value.translation.height > dismissThreshold {
          dismissModal()
        } else {
          withAnimation(dragAnimation) {
            dragOffset = .zero
          }
        }
      }
  }

  // MARK: - Actions
  private func presentModal() {
    modalOffset = slideDistance
    withAnimation(slideAnimation) {
      modalOffset = 0
    }
  }

  private func dismissModal() {
    withAnimation(slideAnimation) {
      modalOffset = slideDistance
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      item = nil
      modalOffset = 0
      dragOffset = .zero
    }
  }

  // MARK: - Helper Methods
  private func modalHeightValue(for geometry: GeometryProxy) -> CGFloat? {
    let safeAreaBottom = geometry.safeAreaInsets.bottom
    let availableHeight = geometry.size.height - safeAreaBottom

    switch height {
      case .fraction(let fraction):
        return min(availableHeight * fraction, availableHeight)
      case .fixed(let points):
        return min(points, availableHeight)
      case .auto:
        return nil
    }
  }
}

public extension View {
  func presentDSModal<Item: Identifiable, ModalContent: View>(
    item: Binding<Item?>,
    height: ModalHeight = .auto,
    showDragIndicator: Bool = true,
    @ViewBuilder content: @escaping (Item) -> ModalContent
  ) -> some View {
    modifier(
      CustomModalModifier(
        item: item,
        height: height,
        showDragIndicator: showDragIndicator,
        modalContent: content
      )
    )
  }
}

