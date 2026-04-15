# TimeSpot DI (Dependency Injection) with WeaveDI 가이드

## 🚀 **TimeSpot 전용 의존성 주입 시스템**

WeaveDI 3.4.1과 고도화된 토큰 관리를 결합한 Clean Architecture 기반 DI 시스템

### 🎯 실제 AppDIManager 구조 (Projects/App/Sources/Di/DiRegister.swift)

```swift
/// 🚀 **앱 전역 DI 관리자**
@MainActor
public final class AppDIManager {
  public static let shared = AppDIManager()

  private init() {}

  /// 🎯 기본 의존성들을 등록
  public func registerDefaultDependencies() async {
    // 🏗️ 1. WeaveDI.builder 패턴으로 실제 구현체들 등록
    WeaveDI.builder
      .register { KeychainManager() as KeychainManagingInterface }
      .register {
        let keychainManager = UnifiedDI.resolve(KeychainManagingInterface.self) ?? KeychainManager()
        return KeychainTokenProvider(keychainManager: keychainManager) as TokenProviding
      }
      .register(DirectionInterface.self) { DirectionRepositoryImpl() }
    // MARK: - 로그인
      .register { AuthRepositoryImpl() as AuthInterface }
      .register { GoogleOAuthRepositoryImpl() as GoogleOAuthInterface }
      .register { GoogleOAuthProvider() as GoogleOAuthProviderInterface }
      .register { AppleLoginRepositoryImpl() as AppleAuthRequestInterface }
      .register { AppleOAuthRepositoryImpl() as AppleOAuthInterface }
      .register { AppleOAuthProvider() as AppleOAuthProviderInterface }
    // MARK: - 회원가입
      .register { SignUpRepositoryImpl() as SignUpInterface }
    // MARK: - 프로필
      .register(ProfileInterface.self) { ProfileRepositoryImpl() }
    // MARK: - 히스토리
      .register(HistoryInterface.self) { HistoryRepositoryImpl() }
    // MARK: - 역
      .register(StationInterface.self) { StationRepositoryImpl() }
    // MARK: - 장소
      .register(PlaceInterface.self) { PlaceRepositoryImpl() }

      .configure()
  }
}
```

## 🔥 TimeSpot 특화 DI 패턴

### 1. **고도화된 KeychainTokenProvider**
*실제 코드: Projects/App/Sources/Di/KeychainTokenProvider.swift*

```swift
final class KeychainTokenProvider: TokenProviding, @unchecked Sendable {
  private enum Constants {
    static let cachedAccessTokenKey = "cached_access_token"
  }

  private let keychainManager: KeychainManagingInterface

  init(keychainManager: KeychainManagingInterface) {
    self.keychainManager = keychainManager
  }

  func accessToken() -> String? {
    // 🚀 3단계 토큰 캐싱 전략
    // 1. 메모리 캐시 확인
    if let cached = TokenCache.shared.token {
      return cached
    }

    // 2. UserDefaults 확인
    if let persistedToken = UserDefaults.standard.string(forKey: Constants.cachedAccessTokenKey),
       !persistedToken.isEmpty {
      TokenCache.shared.token = persistedToken
      return persistedToken
    }

    // 3. Keychain에서 동기 읽기
    if let keychainToken = readAccessTokenFromKeychain(), !keychainToken.isEmpty {
      TokenCache.shared.token = keychainToken
      UserDefaults.standard.set(keychainToken, forKey: Constants.cachedAccessTokenKey)
      return keychainToken
    }

    // 4. 비동기 로드
    Task {
      let token = await keychainManager.accessToken()
      TokenCache.shared.token = token
      if let token, !token.isEmpty {
        UserDefaults.standard.set(token, forKey: Constants.cachedAccessTokenKey)
      }
    }

    return TokenCache.shared.token
  }

  func saveAccessToken(_ token: String) {
    // 캐시 업데이트
    TokenCache.shared.token = token
    UserDefaults.standard.set(token, forKey: Constants.cachedAccessTokenKey)

    // 백그라운드에서 비동기적으로 저장
    Task {
      do {
        try await keychainManager.saveAccessToken(token)
      } catch {
        #logError("Failed to save access token", "\(error)")
        // 저장 실패 시 캐시도 초기화
        TokenCache.shared.token = nil
        UserDefaults.standard.removeObject(forKey: Constants.cachedAccessTokenKey)
      }
    }
  }
}

// 🛡️ Thread-safe 토큰 캐시
private final class TokenCache: @unchecked Sendable {
  static let shared = TokenCache()

  private var _token: String?
  private let lock = NSLock()

  var token: String? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _token
    }
    set {
      lock.lock()
      _token = newValue
      lock.unlock()
    }
  }
}
```

### 2. **Repository 구현체에서 @Dependency 사용**
*실제 코드: Projects/Data/Repository/Sources/OAuth/Auth/Repository/AuthRepositoryImpl.swift*

```swift
final public class AuthRepositoryImpl: AuthInterface, @unchecked Sendable {
  @Dependency(\.keychainManager) private var keychainManager
  private let provider: MoyaProvider<AuthService>
  private let authProvider: MoyaProvider<AuthService>

  public init(
    provider: MoyaProvider<AuthService> = MoyaProvider<AuthService>.default,
    authProvider: MoyaProvider<AuthService> = MoyaProvider<AuthService>.authorized
  ) {
    self.provider = provider
    self.authProvider = authProvider
  }

  // MARK: - 로그인 API
  public func login(
    provider socialProvider: SocialType,
    token: String
  ) async throws -> LoginEntity {
    let reqeust = OAuthLoginRequest(provider: socialProvider.rawValue, idToken: token)
    let dto: LoginDTOModel = try await provider.request(.login(body: reqeust))
    let entity = dto.data.toDomain()
    APIHeader.updateAccessToken(entity.token.accessToken)
    return entity
  }

  // MARK: - 토큰 재발급 (비동기 keychainManager 사용)
  public func refresh() async throws -> AuthTokens {
    guard let refreshToken = await keychainManager.refreshToken(),
          !refreshToken.isEmpty else {
      #logDebug(" [AuthRepositoryImpl] Refresh token is nil or empty - cannot refresh")
      throw AuthError.refreshTokenExpired
    }

    let dto: TokenDTO = try await provider.request(.refresh(refreshToken: refreshToken))
    return dto.data.toDomain()
  }

  // MARK: - 로그아웃 (통합 토큰 클리어)
  public func logout() async throws -> LogoutEntity {
    let dto: LogoutDTOModel = try await authProvider.request(.logout)
    try await keychainManager.clear()

    // APIHeader tokenProvider도 함께 클리어
    APIHeader.clearAccessToken()

    return dto.toDomain()
  }
}
```

### 3. **TCA Feature에서 다양한 UseCase 의존성**
*실제 코드 패턴: Projects/Presentation/Home/Sources/*/

```swift
// ExploreFeature
@Reducer
public struct ExploreFeature {
  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.placeUseCase) var placeUseCase
  @Dependency(\.locationUseCase) var locationUseCase
}

// RouteFeature  
@Reducer
public struct RouteFeature {
  @Dependency(\.getRouteUseCase) var getRouteUseCase
  @Dependency(\.locationUseCase) var locationUseCase
  @Dependency(\.historyRepository) var historyRepository
  @Dependency(\.keychainManager) var keychainManager
}

// ExploreDetailFeature
@Reducer
public struct ExploreDetailFeature {
  @Dependency(\.placeUseCase) var placeUseCase
  @Dependency(\.analyticsUseCase) var analyticsUseCase
}
```

## 🎯 **TimeSpot DI 특화 기능들**

### 1. **3단계 토큰 캐싱 전략**

```swift
// 성능 최적화를 위한 계층적 캐싱
1. TokenCache.shared.token      // 메모리 캐시 (가장 빠름)
2. UserDefaults                 // 앱 재시작 시에도 유지
3. Keychain (비동기)            // 보안 저장소 (백그라운드 동기화)
```

### 2. **Thread-Safe 토큰 관리**

```swift
private final class TokenCache: @unchecked Sendable {
  private let lock = NSLock()  // 동시 접근 방지
  
  var token: String? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _token
    }
  }
}
```

### 3. **비동기 토큰 처리**

```swift
// 비동기 keychainManager 활용
guard let refreshToken = await keychainManager.refreshToken() else {
  throw AuthError.refreshTokenExpired
}

// 백그라운드 토큰 저장
Task {
  try await keychainManager.saveAccessToken(token)
}
```

### 4. **통합 토큰 클리어**

```swift
public func logout() async throws -> LogoutEntity {
  // 1. API 호출
  let dto: LogoutDTOModel = try await authProvider.request(.logout)
  
  // 2. Keychain 클리어
  try await keychainManager.clear()
  
  // 3. APIHeader 클리어  
  APIHeader.clearAccessToken()
  
  return dto.toDomain()
}
```

## 📋 TimeSpot DI 패턴 규칙

### Interface 네이밍 규칙

1. **Interface 접미사**: `KeychainManagingInterface` (DDDAttendance: `KeychainManaging`)
2. **등록 방식 혼재**: `.register { }` + `.register(Type.self) { }`  
3. **MARK 주석**: 기능별로 체계적 그룹화

### Repository Interface 예시

```swift
// Domain/DomainInterface/Sources/AuthInterface.swift
public protocol AuthInterface {
  func login(provider: SocialType, token: String) async throws -> LoginEntity
  func refresh() async throws -> AuthTokens
  func logout() async throws -> LogoutEntity
  func withDraw() async throws -> LogoutEntity
  func registerNotification(with deviceToken: String) async throws -> RegisterNotificationEntity
}
```

### 에러 처리 + 로깅

```swift
do {
  try await keychainManager.saveAccessToken(token)
} catch {
  #logError("Failed to save access token", "\(error)")
  // 실패 시 캐시 초기화로 일관성 보장
  TokenCache.shared.token = nil
  UserDefaults.standard.removeObject(forKey: Constants.cachedAccessTokenKey)
}
```

### 앱 초기화

```swift
@main
struct TimeSpotApp: App {
  init() {
    Task {
      await AppDIManager.shared.registerDefaultDependencies()
    }
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

## 🚀 성능 최적화 포인트

### 1. **캐시 히트율 최대화**
- 메모리 캐시 우선 → UserDefaults → Keychain 순서
- 앱 재시작 시에도 UserDefaults로 빠른 복원

### 2. **비동기 처리로 UI 블로킹 방지**
- 토큰 저장/삭제는 백그라운드 Task
- UI 스레드에서는 캐시된 값만 즉시 반환

### 3. **Thread-Safe 구현**
- NSLock으로 동시 접근 제어
- @unchecked Sendable로 컴파일러 경고 해결

### 4. **에러 복구 전략**
- 저장 실패 시 캐시 초기화로 일관성 유지
- 로그 기반 디버깅 지원

---

**🎯 이 가이드는 TimeSpot 프로젝트의 실제 DI 패턴을 분석한 것으로, ios-performance-optimizer와 ios-performance-pfw 에이전트들이 TimeSpot 최적화 시 참고하는 기준입니다.**