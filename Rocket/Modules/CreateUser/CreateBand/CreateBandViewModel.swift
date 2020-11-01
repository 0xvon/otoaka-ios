//
//  CreateBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Foundation
import Endpoint
import AWSS3

class CreateBandViewModel {
    enum Output {
        case create(Endpoint.Group)
        case error(String)
    }
    
    let idToken: String
    let apiEndpoint: String
    let s3Bucket: String
    let outputHandler: (Output) -> Void
    
    init(idToken: String, apiEndpoint: String, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.idToken = idToken
        self.apiEndpoint = apiEndpoint
        self.s3Bucket = s3Bucket
        self.outputHandler = outputHander
    }
    
    func create(name: String, englishName: String?, biography: String?,
                since: Date?, artwork: UIImage?, hometown: String?) {
        self.uploadImage(image: artwork) { (imageUrl, error) in
            let path = DevelopmentConfig.apiEndpoint + "/" + CreateGroup.pathPattern.joined(separator: "/")
            guard let url = URL(string: path) else { return }
            
            if let error = error {
                print("upload failed")
                self.outputHandler(.error(error))
            }
            
            guard let imageUrl = imageUrl else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = CreateGroup.method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("Bearer \(self.idToken)", forHTTPHeaderField: "Authorization")
            let body = CreateGroup.Request(name: name, englishName: englishName, biography: biography, since: since, artworkURL: URL(string: imageUrl), hometown: hometown)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try! encoder.encode(body)
            print(String(data: request.httpBody!, encoding: .utf8)!)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    self.outputHandler(.error("error in request task: \(error.localizedDescription)"))
                }
                
                guard let data = data else { return }
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let response = try decoder.decode(CreateGroup.Response.self, from: data)
                    self.outputHandler(.create(response))
                } catch let error {
                    print(String(data: data, encoding: .utf8)!)
                    self.outputHandler(.error("error in parsing response: \(error.localizedDescription)"))
                }
            }
            task.resume()
        }
    }
    
    func uploadImage(image: UIImage?, callback: @escaping ((String?, String?) -> Void)) {
        let transferUtility = AWSS3TransferUtility.default()
        let key = "\(UUID()).png"
        let contentType = "application/png"
        let im: UIImage = image ?? UIImage(named: "band")!
        guard let pngData = im.pngData() else {
            callback(nil, "cannot convert image to png data")
            return
        }
        
        let expression = AWSS3TransferUtilityUploadExpression()
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            DispatchQueue.main.async {
                if let error = error {
                    callback(nil, error.localizedDescription)
                }
                callback("https://\(self.s3Bucket).s3-ap-northeast-1.amazonaws.com/\(key)", nil)
            }
        }
        
        transferUtility.uploadData(
            pngData,
            bucket: s3Bucket,
            key: key,
            contentType: contentType,
            expression: expression,
            completionHandler: completionHandler
        ).continueWith { task in
            if let error = task.error {
                callback(nil, error.localizedDescription)
            }
            
            if let _ = task.result {
                DispatchQueue.main.async {
                    print("uploading...")
                }
            }
            
            return nil
        }
    }
}
