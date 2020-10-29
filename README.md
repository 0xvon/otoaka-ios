## Rocket iOS 🚀

Rocket for BandsのiOS版です

### 環境

- Swift 5.2
- Xcode 12
- UIKit
- AWS SDK
- iOS 13

### セットアップ

#### 1. dependency

```
$ pod install
```

#### 2. open Xcode Workspace

```
$ open Rocket.xcworkspace
```

#### 3. set Environment Variables

```Swift
struct DevelopmentConfig: Config {
    
    static var poolId = "ap-northeast-1_xxxxx"
    
    static var appClientId = "xxxxxxxxxxxxxxxxx"

    static var appClientSecret = "xxxxxxxxxxxxxxxxx"

    static var scopes = Set(["xxxxxxxx.xxxxxx.xxxxxx"])

    static var signInRedirectUri = "dev.wall-of-death.Rocket://users/cognito/signin"

    static var signOutRedirectUri = "dev.wall-of-death.Rocket://users/cognito/signout"

    static var webDomain = "https://xxxxxxxx.auth.ap-northeast-1.amazoncognito.com"

    static var userPoolIdForEnablingASF = "ap-northeast-1_xxxxxxxxxxxx"

}

```

#### 4. Build and Run

cmd + r
