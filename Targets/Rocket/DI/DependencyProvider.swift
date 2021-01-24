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
import Networking
import ImagePipeline

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
    var masterService: MasterSerivice
    var versioningService: VersioningSerivice
    var imagePipeline: ImagePipeline
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
        let cognitoAuthKey = Bundle.main.bundleIdentifier.map { "\($0).cognito-auth" } ?? "band.rocketfor.cognito-auth"
        print(cognitoAuthKey)
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
        let httpInterceptor: HTTPClientInterceptor = {
            #if DEBUG
            return LoggingInterceptor(logger: ConsoleLogger())
            #else
            return NopHTTPClientInterceptor()
            #endif
        }()

        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
        let apiClient = HTTPClient<RocketAPIAdapter>(
            baseUrl: URL(string: config.apiEndpoint)!,
            adapter: RocketAPIAdapter(tokenProvider: wrapper),
            interceptor: httpInterceptor
        )
        let youTubeDataApiClient = HTTPClient<YoutubeDataAPIAdapter>(
            baseUrl: URL(string: "https://www.googleapis.com")!,
            adapter: YoutubeDataAPIAdapter(apiKey: config.youTubeApiKey),
            interceptor: httpInterceptor
        )
        
        let s3Client = S3Client(s3Bucket: config.s3Bucket, cognitoIdentityPoolCredentialProvider: credentialProvider)
        let masterServiceClient = HTTPClient<WebAPIAdapter>(
            baseUrl: URL(string: "https://\(s3Client.s3Bucket).s3-ap-northeast-1.amazonaws.com/items/SocialInputs.json")!,
            adapter: WebAPIAdapter()
        )
        let versionServiceClient = HTTPClient<WebAPIAdapter>(baseUrl: URL(string: "https://\(s3Client.s3Bucket).s3-ap-northeast-1.amazonaws.com/items/RequiredVersion.json")!, adapter: WebAPIAdapter())
        
        return DependencyProvider(
            auth: auth, apiClient: apiClient,
            youTubeDataApiClient: youTubeDataApiClient,
            s3Client: s3Client,
            viewHierarchy: ViewHierarchy(windowScene: windowScene),
            masterService: MasterSerivice(httpClient: masterServiceClient),
            versioningService: VersioningSerivice(httpClient: versionServiceClient),
            imagePipeline: NukeImagePipeline()
        )
    }
}

class CognitoAuthWrapper: APITokenProvider {
    enum Error: Swift.Error {
        case unexpectedGetSessionResult
    }
    let auth: AWSCognitoAuth
    let queue = DispatchQueue(label: Bundle.main.bundleIdentifier.map { "\($0).cognito-id-provider" } ?? "band.rocketfor.cognito-id-provider")
    init(awsCognitoAuth: AWSCognitoAuth) {
        self.auth = awsCognitoAuth
    }

    func provideIdToken(_ callback: @escaping (Result<String, Swift.Error>) -> Void) {
        queue.async { [auth] in
            let semaphore = DispatchSemaphore(value: 0)
            auth.getSession { (session, error) in
                if let session = session, let idToken = session.idToken {
                    callback(.success(idToken.tokenString))
                } else if let error = error {
                    callback(.failure(error))
                } else {
                    callback(.failure(Error.unexpectedGetSessionResult))
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
