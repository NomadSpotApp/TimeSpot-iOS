import Foundation
import ProjectDescription
import DependencyPlugin
import ProjectTemplatePlugin
import ProjectTemplatePlugin
import DependencyPackagePlugin

let project = Project.makeModule(
  name: "ThirdParty",
  bundleId: .appBundleID(name: ".ThirdParty"),
  product: .staticFramework,
  settings:  .settings(),
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.sdWebImage,
    .SPM.kingfisher
  ],
  sources: ["Sources/**"]
)
