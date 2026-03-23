import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "Splash",
  bundleId: .appBundleID(name: ".Splash"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
  ],
  sources: ["Sources/**"],
  hasTests: true
)
