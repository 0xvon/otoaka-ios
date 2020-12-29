import Foundation
import UIKit

class BundleReference {
    static func image(named name: String) -> UIImage {
        let bundle = Bundle(for: BundleReference.self)
        return UIImage(named: name, in: bundle, compatibleWith: nil)!
    }
}
