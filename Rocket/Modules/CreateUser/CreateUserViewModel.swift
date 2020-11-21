//
//  CreateUserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import Foundation

import Endpoint
import AWSS3

class CreateUserViewModel {
    enum Output {
        case artist(User)
        case fan(User)
        case error(String)
    }
    
    let idToken: String
    let apiEndpoint: String
    let s3Client: S3Client
    let outputHandler: (Output) -> Void
    
    
    init(idToken: String, apiEndpoint: String, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.idToken = idToken
        self.apiEndpoint = apiEndpoint
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.outputHandler = outputHander
    }
    
    func signupAsFan(name: String, thumbnail: UIImage?) {
        self.s3Client.uploadImage(image: thumbnail) { (imageUrl, error) in
            let signupAPIClient = APIClient<Signup>(baseUrl: self.apiEndpoint, idToken: self.idToken)
            let req: Signup.Request = Signup.Request(name: name, biography: nil, thumbnailURL: imageUrl, role: .fan(Fan()))
            
            signupAPIClient.request(req: req) { res in
                self.outputHandler(.fan(res))
            }
        }
    }
    
    func signupAsArtist(name: String, thumbnail: UIImage?, part: String) {
        self.s3Client.uploadImage(image: thumbnail) { (imageUrl, error) in
            let signupAPIClient = APIClient<Signup>(baseUrl: self.apiEndpoint, idToken: self.idToken)
            let req: Signup.Request = Signup.Request(name: name, biography: nil, thumbnailURL: imageUrl, role: .artist(Artist(part: part)))
            
            signupAPIClient.request(req: req) { res in
                self.outputHandler(.artist(res))
            }
        }
    }
}
