//
//  APIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import Endpoint
import Foundation

class APIClient<E: EndpointProtocol> {
    var baseUrl: String
    var idToken: String
    
    init(baseUrl: String, idToken: String) {
        self.baseUrl = baseUrl
        self.idToken = idToken
    }
    
    public func request(req: E.Request, callback: @escaping ((E.Response) -> Void)) {
        let url = try! E.URI().encode(baseURL: URL(string: self.baseUrl)!)
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = E.method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.idToken)", forHTTPHeaderField: "Authorization")
        if E.method != .get {
            let body = req
            request.httpBody = try! JSONEncoder().encode(body)
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error { print(error); return }
            guard let data = data else { return }
            
            do {
                let response: E.Response = try JSONDecoder().decode(E.Response.self, from: data)
                callback(response)
            } catch let error { print(error); return }
        }
        task.resume()
    }
}
