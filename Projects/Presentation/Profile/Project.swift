import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "Profile",
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.tcaCoordinator,
    .Domain(implements: .UseCase),
    .Shared(implements: .DesignSystem),
    .Presentation(implements: .Web)

  ],
  sources: ["Sources/**"]
)
