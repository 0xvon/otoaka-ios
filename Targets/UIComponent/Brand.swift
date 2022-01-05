import UIKit

public enum Brand {
    // FIXME: Use `UIColor(dynamicProvider:)`
    public static func color(for color: Color) -> UIColor {
        switch color {
        case .brand(.primary):             return #colorLiteral(red: 0.9019607843, green: 0.3294117647, blue: 0.2235294118, alpha: 1) // #E65439
        case .brand(.secondary):           return #colorLiteral(red: 0.9333333333, green: 0.5333333333, blue: 0.4588235294, alpha: 1) // #EE8875
        case .brand(.google):              return #colorLiteral(red: 0.9843137255, green: 0.737254902, blue: 0.01960784314, alpha: 1) // #FBBC05
        case .brand(.facebook):            return #colorLiteral(red: 0.231372549, green: 0.3490196078, blue: 0.5960784314, alpha: 1) // #3B5998
        case .brand(.twitter):             return #colorLiteral(red: 0.1137254902, green: 0.631372549, blue: 0.9490196078, alpha: 1) // #1DA1F2
        case .brand(.apple):               return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) // #FFFFFF
        
        case .background(.primary):        return #colorLiteral(red: 0.05490196078, green: 0.05490196078, blue: 0.05490196078, alpha: 1) // #0E0E0E
        case .background(.secondary):      return #colorLiteral(red: 0.5647058824, green: 0.5647058824, blue: 0.5647058824, alpha: 1) // #909090
        case .background(.button):         return #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1) // #1C1C1E
        case .background(.cell):           return #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1) // #1C1C1E
        case .background(.cellSelected):   return #colorLiteral(red: 0.3137254902, green: 0.3137254902, blue: 0.3137254902, alpha: 1) // #414045
        case .background(.navigationBar):  return #colorLiteral(red: 0.1568627451, green: 0.1568627451, blue: 0.1607843137, alpha: 1) // #282829
        case .background(.searchBar):      return #colorLiteral(red: 0.07058823529, green: 0.07058823529, blue: 0.07058823529, alpha: 1) // #121212
        
        case .text(.primary):              return #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1) // #F0F0F0
        case .ranking(.first):             return #colorLiteral(red: 0.8235294118, green: 0.2156862745, blue: 0.1019607843, alpha: 1) // #D2371A
        case .ranking(.second):            return #colorLiteral(red: 0.9176470588, green: 0.431372549, blue: 0.3411764706, alpha: 1) // #EA6E57
        case .ranking(.other):             return #colorLiteral(red: 0.9529411765, green: 0.6862745098, blue: 0.6352941176, alpha: 1) // #F3AFA2
        }
    }

    public enum Color {

        case brand(BrandColor)
        case background(BackgroundColor)
        case text(TextColor)
        case ranking(RankingColor)
        
        public enum BrandColor: CaseIterable {
            case primary, secondary, google, facebook, twitter, apple
        }

        public enum BackgroundColor: CaseIterable {
            case primary, secondary, button, cell, cellSelected,
                 navigationBar, searchBar
        }
        public enum TextColor: CaseIterable {
            case primary
        }
        
        public enum RankingColor: CaseIterable {
            case first, second, other
        }
    }
    
    public static func font(for typography: Typography) -> UIFont {
        .systemFont(ofSize: fontSize(for: typography),
                    weight: fontWeight(for: typography))
    }

    private static func fontSize(for typography: Typography) -> CGFloat {
        switch typography {
        case .xxlarge, .xxlargeStrong:
            return 24.0
        case .xlarge, .xlargeStrong:
            return 20.0
        case .large, .largeStrong:
            return 17.0
        case .medium, .mediumStrong:
            return 15.0
        case .small, .smallStrong:
            return 14.0
        case .xsmall, .xsmallStrong:
            return 12.0
        case .xxsmall, .xxsmallStrong:
            return 11.0
        }
    }
    private static func fontWeight(for typography: Typography) -> UIFont.Weight {
        switch typography {
        case .xxlargeStrong, .xlargeStrong, .largeStrong, .mediumStrong, .smallStrong, .xsmallStrong, .xxsmallStrong:
            return .semibold
        case .xxlarge, .xlarge, .large, .medium, .small, .xsmall, .xxsmall:
            return .regular
        }
    }

    public enum Typography: String, CaseIterable {
        case xxlarge, xlarge, large,
             medium,
             small, xsmall, xxsmall,
             xxlargeStrong, xlargeStrong, largeStrong,
             mediumStrong,
             smallStrong, xsmallStrong, xxsmallStrong
    }

    public enum Spacing: String, CaseIterable {
        case xxsmall,
        xsmall,
        small,
        medium,
        large,
        xlarge,
        xxlarge,
        xxxlarge,
        keyline,
        divider
    }

    public static func space(for spacing: Spacing) -> CGFloat {
        switch spacing {
        case .xxsmall:
            return 4.0
        case .xsmall:
            return 8.0
        case .small:
            return 12.0
        case .keyline:
            return 16.0
        case .medium:
            return 24.0
        case .large:
            return 32.0
        case .xlarge:
            return 40.0
        case .xxlarge:
            return 48.0
        case .xxxlarge:
            return 56.0
        case .divider:
            return 1.0
        }
    }
}

extension UIColor {
    // MARK: Color variations

    public func pressed() -> UIColor {
        var r: CGFloat = 0.0
        var g: CGFloat  = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat  = 0.0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        // blend #000000 alpha 0.1
        return UIColor(red: r*0.8, green: g*0.8, blue: b*0.8, alpha: a * 0.8 + 0.1)
    }
}

@available(*, deprecated)
struct style {
    enum color {
        case main
        case second
        case background
        case subBackground
        case sub

        func get() -> UIColor {
            switch self {
            case .main:
                return UIColor.white
            case .second:
                return UIColor.systemGreen
            case .background:
                return UIColor.black
            case .subBackground:
                return UIColor.darkGray
            case .sub:
                return UIColor.systemGray
            }
        }
    }

    //    一応書いとくけどIB内で設定するから使わない(迷ったら見てね的な)
    enum margin: Int {
        case box = 12
        case area = 16
        case letter = 8
    }

    enum font {
        case xlarge
        case large
        case regular
        case small

        func get() -> UIFont {
            switch self {
            case .xlarge:
                return UIFont.systemFont(ofSize: CGFloat(22), weight: UIFont.Weight(500))
            case .large:
                return UIFont.systemFont(ofSize: CGFloat(18), weight: UIFont.Weight(300))
            case .regular:
                return UIFont.systemFont(ofSize: CGFloat(14), weight: UIFont.Weight(100))
            case .small:
                return UIFont.systemFont(ofSize: CGFloat(10), weight: UIFont.Weight(100))
            }
        }
    }
}

extension UIColor {
    var image: UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(self.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension String {
    func toFormatString(from: String, to: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = from
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let _date = dateFormatter.date(from: self) // format to date
        dateFormatter.dateFormat = to
        return _date.map(dateFormatter.string(from:)) // format to string again
    }
}

extension Date {
    func toFormatString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "ja_JP")
        return dateFormatter.string(from: self)
    }
}
