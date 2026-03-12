import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeAppModule(
  name: "ome",
  bundleId: .appBundleID(name: ".ome"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [

  .Domain(implements: .UseCase),
  .Shared(implements: .DesignSystem),
  .SPM.composableArchitecture,
  ],
  sources: ["Sources/**"]
)
