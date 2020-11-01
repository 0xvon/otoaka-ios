//
//  CreateUserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import Foundation

import Endpoint
import AWSCognitoAuth
import AWSS3

class CreateUserViewModel {
    enum Output {
        case artist(User)
        case fan(User)
        case error(String)
    }
    
    let auth: AWSCognitoAuth
    let session: AWSCognitoAuthUserSession
    let apiEndpoint: String
    let s3Bucket: String
    let outputHandler: (Output) -> Void
    
    init(auth: AWSCognitoAuth, session: AWSCognitoAuthUserSession, apiEndpoint: String, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.auth = auth
        self.session = session
        self.apiEndpoint = apiEndpoint
        self.s3Bucket = s3Bucket
        self.outputHandler = outputHander
    }
    
    func signupAsFan(name: String, thumbnail: UIImage?) {
        self.uploadImage(image: thumbnail) { (imageUrl, error) in
            let path = DevelopmentConfig.apiEndpoint + "/" + Signup.pathPattern.joined(separator: "/")
            guard let url = URL(string: path) else { return }
            guard let token = self.session.idToken else { return }
            
            if let error = error {
                print("upload failed")
                self.outputHandler(.error(error))
            }
            
            guard let imageUrl = imageUrl else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = Signup.method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token.tokenString)", forHTTPHeaderField: "Authorization")
            let body = Signup.Request(name: name, thumbnailURL: imageUrl, role: .fan(Fan()))
            request.httpBody = try! JSONEncoder().encode(body)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    self.outputHandler(.error(error.localizedDescription))
                }
                
                guard let data = data else { return }
                do {
                    let response = try JSONDecoder().decode(Signup.Response.self, from: data)
                    self.outputHandler(.fan(response))
                } catch let error {
                    self.outputHandler(.error(error.localizedDescription))
                }
            }
            task.resume()
        }
    }
    
    func signupAsArtist(name: String, thumbnail: UIImage?, part: String) {
        self.uploadImage(image: thumbnail) { (imageUrl, error) in
            let path = DevelopmentConfig.apiEndpoint + "/" + Signup.pathPattern.joined(separator: "/")
            guard let url = URL(string: path) else { return }
            guard let token = self.session.idToken else { return }
            
            if let error = error {
                print("upload failed")
                self.outputHandler(.error(error))
            }
            
            guard let imageUrl = imageUrl else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = Signup.method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token.tokenString)", forHTTPHeaderField: "Authorization")
            let body = Signup.Request(name: name, thumbnailURL: imageUrl, role: .artist(Artist(part: part)))
            request.httpBody = try! JSONEncoder().encode(body)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    self.outputHandler(.error(error.localizedDescription))
                }
                
                guard let data = data else { return }
                do {
                    let response = try JSONDecoder().decode(Signup.Response.self, from: data)
                    self.outputHandler(.fan(response))
                } catch let error {
                    self.outputHandler(.error(error.localizedDescription))
                }
            }
            task.resume()
        }
    }
    
    func uploadImage(image: UIImage?, callback: @escaping ((String?, String?) -> Void)) {
        print("uploadImage called")
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
            completionHandler: completionHandler).continueWith { task in
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
