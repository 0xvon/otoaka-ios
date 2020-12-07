//
//  DependencyProvider.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import AWSCognitoAuth
import AWSCore
import Endpoint
import Foundation

@dynamicMemberLookup
struct LoggedInDependencyProvider {
    let provider: DependencyProvider
    let user: User

    subscript<T>(dynamicMember keyPath: KeyPath<DependencyProvider, T>) -> T {
        provider[keyPath: keyPath]
    }
}

struct DependencyProvider {
    var auth: AWSCognitoAuth
    var apiClient: APIClient
    var youTubeDataApiClient: YouTubeDataAPIClient
    var s3Bucket: String
}

extension DependencyProvider {

    #if DEBUG
        static func make() -> DependencyProvider {
            .make(config: DevelopmentConfig.self)
        }
    #endif
    static func make(config: Config.Type) -> DependencyProvider {
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .APNortheast1,
            identityPoolId: config.identityPoolId
        )

        let configuration = AWSServiceConfiguration(
            region: .APNortheast1,
            credentialsProvider: credentialProvider
        )

        AWSServiceManager.default()?.defaultServiceConfiguration = configuration

        let cognitoConfiguration = AWSCognitoAuthConfiguration(
            appClientId: config.appClientId,
            appClientSecret: config.appClientSecret,
            scopes: config.scopes,
            signInRedirectUri: config.signInRedirectUri,
            signOutRedirectUri: config.signOutRedirectUri,
            webDomain: config.webDomain,
            identityProvider: nil,
            idpIdentifier: nil,
            userPoolIdForEnablingASF: config.userPoolIdForEnablingASF
        )

        let cognitoAuthKey = "dev.wall-of-death.Rocket.cognito-auth"
        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: cognitoAuthKey)
        let auth = AWSCognitoAuth(forKey: cognitoAuthKey)
        let wrapper = CognitoAuthWrapper(awsCognitoAuth: auth)
        let apiClient = APIClient(baseUrl: URL(string: config.apiEndpoint)!, tokenProvider: wrapper)
        let youTubeDataApiClient = YouTubeDataAPIClient(baseUrl: URL(string: "https://www.googleapis.com/youtube/v3")!, apiKey: config.youTubeApiKey)
        return DependencyProvider(auth: auth, apiClient: apiClient, youTubeDataApiClient: youTubeDataApiClient, s3Bucket: config.s3Bucket)
    }
}

class CognitoAuthWrapper: APITokenProvider {
    enum Error: Swift.Error {
        case unexpectedGetSessionResult
    }
    let auth: AWSCognitoAuth
    let queue = DispatchQueue(label: "dev.wall-of-death.Rocket.cognito-id-provider")
    init(awsCognitoAuth: AWSCognitoAuth) {
        self.auth = awsCognitoAuth
    }

    func provideIdToken(_ callback: @escaping (Result<String, Swift.Error>) -> Void) {
        queue.async { [auth] in
            let semaphore = DispatchSemaphore(value: 0)
            auth.getSession { (session, error) in
                semaphore.signal()
                if let session = session, let idToken = session.idToken {
                    callback(.success(idToken.tokenString))
                } else if let error = error {
                    callback(.failure(error))
                } else {
                    callback(.failure(Error.unexpectedGetSessionResult))
                }
            }
            semaphore.wait()
        }
    }
}
