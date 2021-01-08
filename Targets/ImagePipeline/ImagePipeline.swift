import Foundation
import UIKit

public typealias ImagePipelineProtocol = ImagePipeline

public protocol ImagePipeline {
    func loadImage(_ url: URL, handler: @escaping (Result<UIImage, Error>) -> Void)
    func loadImage(_ url: URL, into view: UIImageView)
}

extension ImagePipeline {
}
