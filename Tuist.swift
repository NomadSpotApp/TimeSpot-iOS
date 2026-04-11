import ProjectDescription

let tuist = Tuist(
  project: .tuist(
    compatibleXcodeVersions: .all,
    swiftVersion: .some("6.0.0"),
    plugins: [
      .local(path: .relativeToRoot("Plugins/ProjectTemplatePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPackagePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPlugin")),
    ],
    generationOptions: .options(
      // 🔒 패키지 버전 잠금 활성화 (빌드 속도 향상)
      disablePackageVersionLocking: false,

      // ⚠️ 사이드 이펙트 경고 최소화 (빌드 로그 단순화)
      staticSideEffectsWarningTargets: .none,

      // 📊 빌드 인사이트 활성화 (성능 모니터링)
      buildInsightsDisabled: false,

      // 🧯 Xcode 내 재생성 스킴 포함 (개발 편의성)
      includeGenerateScheme: true
    ),
    installOptions: .options()
  )
)
