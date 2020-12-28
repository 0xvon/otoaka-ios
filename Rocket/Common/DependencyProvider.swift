//
//  DependencyProvider.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import AWSCognitoAuth
import AWSCore
import Firebase
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
    var s3Client: S3Client
    var viewHierarchy: ViewHierarchy
}

extension DependencyProvider {

    #if DEBUG
        static func make(windowScene: UIWindowScene) -> DependencyProvider {
            .make(config: DevelopmentConfig.self, windowScene: windowScene)
        }
    #endif
    static func make(config: Config.Type, windowScene: UIWindowScene) -> DependencyProvider {

        let cognitoConfiguration = AWSCognitoAuthConfiguration(
            appClientId: config.cognitoAppClientId,
            appClientSecret: config.cognitoAppClientSecret,
            scopes: config.cognitoScopes,
            signInRedirectUri: config.cognitoSignInRedirectUri,
            signOutRedirectUri: config.cognitoSignOutRedirectUri,
            webDomain: config.cognitoWebDomain,
            identityProvider: nil,
            idpIdentifier: nil,
            userPoolIdForEnablingASF: nil
        )

        let cognitoAuthKey = "dev.wall-of-death.Rocket.cognito-auth"
        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: cognitoAuthKey)
        FirebaseApp.configure()
        let auth = AWSCognitoAuth(forKey: cognitoAuthKey)
        let wrapper = CognitoAuthWrapper(awsCognitoAuth: auth)
        
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .APNortheast1,
            identityPoolId: config.cognitoIdentityPoolId
        )
        let configuration = AWSServiceConfiguration(
            region: .APNortheast1,
            credentialsProvider: credentialProvider
        )

        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
        let apiClient = APIClient(baseUrl: URL(string: config.apiEndpoint)!, tokenProvider: wrapper)
        let youTubeDataApiClient = YouTubeDataAPIClient(baseUrl: URL(string: "https://www.googleapis.com")!, apiKey: config.youTubeApiKey)
        
        if credentialProvider.identityId == nil {
            credentialProvider.getIdentityId().continueWith(block: {(task) -> AnyObject? in
                if let error = task.error { fatalError(error.localizedDescription) }
                if let identityId = task.result {
                    print("Identity ID is: \(identityId)")
                }
                return task
            })
        }
        
        let s3Client = S3Client(s3Bucket: config.s3Bucket, cognitoIdentityPoolCredentialProvider: credentialProvider)
        
        return DependencyProvider(
            auth: auth, apiClient: apiClient,
            youTubeDataApiClient: youTubeDataApiClient,
            s3Client: s3Client,
            viewHierarchy: ViewHierarchy(windowScene: windowScene)
        )
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
