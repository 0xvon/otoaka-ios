// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let accentColor = ColorAsset(name: "AccentColor")
  internal static let arrow = ImageAsset(name: "arrow")
  internal static let band = ImageAsset(name: "band")
  internal static let calendar = ImageAsset(name: "calendar")
  internal static let cassetteRole = ImageAsset(name: "cassetteRole")
  internal static let comment = ImageAsset(name: "comment")
  internal static let edit = ImageAsset(name: "edit")
  internal static let guitar = ImageAsset(name: "guitar")
  internal static let heart = ImageAsset(name: "heart")
  internal static let heartFill = ImageAsset(name: "heart_fill")
  internal static let human = ImageAsset(name: "human")
  internal static let human2 = ImageAsset(name: "human2")
  internal static let icon = ImageAsset(name: "icon")
  internal static let image = ImageAsset(name: "image")
  internal static let insta = ImageAsset(name: "insta")
  internal static let instaMargin = ImageAsset(name: "instaMargin")
  internal static let invitation = ImageAsset(name: "invitation")
  internal static let itunes = ImageAsset(name: "itunes")
  internal static let jacket = ImageAsset(name: "jacket")
  internal static let live = ImageAsset(name: "live")
  internal static let logout = ImageAsset(name: "logout")
  internal static let mail = ImageAsset(name: "mail")
  internal static let mailIcon = ImageAsset(name: "mailIcon")
  internal static let map = ImageAsset(name: "map")
  internal static let movie = ImageAsset(name: "movie")
  internal static let music = ImageAsset(name: "music")
  internal static let people = ImageAsset(name: "people")
  internal static let play = ImageAsset(name: "play")
  internal static let plus = ImageAsset(name: "plus")
  internal static let post = ImageAsset(name: "post")
  internal static let production = ImageAsset(name: "production")
  internal static let profile = ImageAsset(name: "profile")
  internal static let record = ImageAsset(name: "record")
  internal static let searchIcon = ImageAsset(name: "searchIcon")
  internal static let selectedMailIcon = ImageAsset(name: "selectedMailIcon")
  internal static let selectedSearchIcon = ImageAsset(name: "selectedSearchIcon")
  internal static let selectedTicketIcon = ImageAsset(name: "selectedTicketIcon")
  internal static let share = ImageAsset(name: "share")
  internal static let spotify = ImageAsset(name: "spotify")
  internal static let stopButton = ImageAsset(name: "stopButton")
  internal static let ticket = ImageAsset(name: "ticket")
  internal static let ticketIcon = ImageAsset(name: "ticketIcon")
  internal static let track = ImageAsset(name: "track")
  internal static let twitter = ImageAsset(name: "twitter")
  internal static let twitterMargin = ImageAsset(name: "twitterMargin")
  internal static let youtube = ImageAsset(name: "youtube")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
