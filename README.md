## Rocket for bands iOS 🚀

Rocket for BandsのiOS版です

### Environment

#### 1. Runtime & IDE
- Swift 5.2
- Xcode 12
- iOS 13, 14

#### 2. UI Components
- UIKit
- SwiftUI (Xcode Previews)
- Combine

#### 3. External Frameworks
- AWS SDK
- Firebase SDK
- XcodeGen
- Fastlane
- Cocoapods

### Setup

#### 1. dependency

```
$ pod install
```

#### 2. open Xcode Workspace

```
$ xcodegen
$ open Rocket.xcworkspace
```

#### 3. set Environment Variables

```Swift
struct DevelopmentConfig: Config {
    ...
}

```

#### 4. Build and Run

set Target as Rocket-Development and enter `cmd + r`

#### 5. Deploy

```
$ fastlane release
```
