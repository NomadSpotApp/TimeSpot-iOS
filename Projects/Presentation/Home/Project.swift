import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "Home",
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .SPM.composableArchitecture,
    .SPM.tcaCoordinator,
    .xcframework(path: "./Resources/framework/NMapsMap.xcframework"),
    .xcframework(path: "./Resources/framework/NMapsGeometry.xcframework")
  ],
  sources: ["Sources/**"],
  hasTests: true
)
