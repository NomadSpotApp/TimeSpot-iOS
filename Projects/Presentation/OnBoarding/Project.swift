import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "OnBoarding",
  bundleId: .appBundleID(name: ".OnBoarding"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
    .SPM.composableArchitecture,
    .SPM.tcaCoordinator,
  ],
  sources: ["Sources/**"],
  hasTests: true
)
