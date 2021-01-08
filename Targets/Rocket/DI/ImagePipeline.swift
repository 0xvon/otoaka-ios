//
//  ImagePipeline.swift
//  Rocket
//
//  Created by kateinoigakukun on 2021/01/09.
//

import Nuke
import ImagePipeline

class NukeImagePipeline: ImagePipelineProtocol {
    private static let dataCache = try? DataCache(name: "dev.wall-of-death.dev.Rocket")
    private static let imageCache = ImageCache()

    private let pipeline = Nuke.ImagePipeline { configuration in
        configuration.dataCacheOptions.storedItems = [.finalImage]
        configuration.dataCache = NukeImagePipeline.dataCache
        configuration.imageCache = NukeImagePipeline.imageCache
    }
    func loadImage(_ url: URL, handler: @escaping (Result<UIImage, Error>) -> Void) {
        pipeline.loadImage(with: url, queue: .main) { result in
            switch result {
            case .success(let response):
                handler(.success(response.image))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
    func loadImage(_ url: URL, into view: UIImageView) {
        var options = ImageLoadingOptions()
        options.pipeline = pipeline
        Nuke.loadImage(with: url, options: options, into: view)
    }
}
