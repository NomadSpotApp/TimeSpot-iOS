//
//  SwipeBackModifier.swift
//  DesignSystem
//
//  Created by Codex on 4/11/26.
//

import SwiftUI
import UIKit

private struct SwipeBackEnabler: UIViewControllerRepresentable {
  static let tag = 0xD5EED1

  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()

    DispatchQueue.main.async {
      guard let navigationController = viewController.navigationController else { return }
      if navigationController.view.tag == Self.tag { return }

      navigationController.view.tag = Self.tag
      navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
      navigationController.interactivePopGestureRecognizer?.isEnabled = true
    }

    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      true
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      otherGestureRecognizer is UIPanGestureRecognizer
      && !(gestureRecognizer is UIScreenEdgePanGestureRecognizer)
    }
  }
}

public extension View {
  func enableSwipeBack() -> some View {
    background(SwipeBackEnabler())
  }
}
