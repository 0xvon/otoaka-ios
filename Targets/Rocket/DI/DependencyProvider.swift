//
//  DependencyProvider.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

//import AWSCognitoAuth
import AWSCore
import Auth0
import Firebase
import Endpoint
import Foundation
import Networking
import ImagePipeline

@dynamicMemberLookup
struct LoggedInDependencyProvider {
    let provider: DependencyProvider
    var user: User

    subscript<T>(dynamicMember keyPath: KeyPath<DependencyProvider, T>) -> T {
        provider[keyPath: keyPath]
    }
}

struct DependencyProvider {
    var auth: WebAuth
    var credentialsManager: CredentialsManager
    var apiClient: APIClient
    var youTubeDataApiClient: YouTubeDataAPIClient
    var appleMusicApiClient: AppleMusicAPIClient
    var musixApiClient: MusixmatchAPIClient
    var s3Client: S3Client
    var viewHierarchy: ViewHierarchy
    var masterService: MasterSerivice
    var versioningService: VersioningSerivice
    var imagePipeline: ImagePipeline
    var urlScheme: URL?
}

extension DependencyProvider {

    static func make(windowScene: UIWindowScene, urlScheme: URL? = nil) -> DependencyProvider {
        return .make(config: EnvironmentConfig.self, windowScene: windowScene, urlScheme: urlScheme)
    }

    static func make(config: Config.Type, windowScene: UIWindowScene, urlScheme: URL?) -> DependencyProvider {

//        let cognitoConfiguration = AWSCognitoAuthConfiguration(
//            appClientId: config.cognitoAppClientId,
//            appClientSecret: config.cognitoAppClientSecret,
//            scopes: config.cognitoScopes,
//            signInRedirectUri: config.cognitoSignInRedirectUri,
//            signOutRedirectUri: config.cognitoSignOutRedirectUri,
//            webDomain: config.cognitoWebDomain,
//            identityProvider: nil,
//            idpIdentifier: nil,
//            userPoolIdForEnablingASF: nil
//        )
//        let cognitoAuthKey = Bundle.main.bundleIdentifier.map { "\($0).cognito-auth" } ?? "band.rocketfor.cognito-auth"
//        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: cognitoAuthKey)
        FirebaseApp.configure()
//        let auth = AWSCognitoAuth(forKey: cognitoAuthKey)
        
        let auth = Auth0.webAuth()
            .scope("openid profile")
            .audience("\(config.auth0ClientUrl)/userinfo")
            .useEphemeralSession()
        
        let credentialsManager = Auth0.CredentialsManager(authentication: Auth0.authentication())
            
        let wrapper = Auth0Wrapper(credentialsManager: credentialsManager)
        
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
        let appleMusicApiClient = HTTPClient<AppleMusicAPIAdapter>(
            baseUrl: URL(string: "https://api.music.apple.com")!,
            adapter: AppleMusicAPIAdapter(developerToken: config.appleMusicDeveloperToken),
            interceptor: httpInterceptor
        )
        let musixApiClient = HTTPClient<MusixmatchAPIAdapter>(
            baseUrl: URL(string: "https://api.musixmatch.com")!,
            adapter: MusixmatchAPIAdapter(apiKey: config.musixmatchApiKey),
            interceptor: httpInterceptor
        )
        
        let s3Client = S3Client(s3Bucket: config.s3Bucket, cognitoIdentityPoolCredentialProvider: credentialProvider)
        let masterServiceClient = HTTPClient<WebAPIAdapter>(
            baseUrl: URL(string: "https://\(s3Client.s3Bucket).s3-ap-northeast-1.amazonaws.com/items/SocialInputs.json")!,
            adapter: WebAPIAdapter()
        )
        let versionServiceClient = HTTPClient<WebAPIAdapter>(baseUrl: URL(string: "https://\(s3Client.s3Bucket).s3-ap-northeast-1.amazonaws.com/items/RequiredVersion.json")!, adapter: WebAPIAdapter())
        
        return DependencyProvider(
            auth: auth,
            credentialsManager: credentialsManager,
            apiClient: apiClient,
            youTubeDataApiClient: youTubeDataApiClient,
            appleMusicApiClient: appleMusicApiClient,
            musixApiClient: musixApiClient,
            s3Client: s3Client,
            viewHierarchy: ViewHierarchy(windowScene: windowScene),
            masterService: MasterSerivice(httpClient: masterServiceClient),
            versioningService: VersioningSerivice(httpClient: versionServiceClient),
            imagePipeline: NukeImagePipeline(),
            urlScheme: urlScheme
        )
    }
}

class Auth0Wrapper: APITokenProvider {
    enum Error: Swift.Error {
        case unexpectedGetSessionResult
    }
    let credentialsManager: CredentialsManager
    init(credentialsManager: CredentialsManager) {
        self.credentialsManager = credentialsManager
    }
    
    func provideIdToken(_ callback: @escaping (Swift.Result<String, Swift.Error>) -> Void) {
        credentialsManager
            .credentials(callback: { (error, credential) in
            if let error = error {
                callback(.failure(error))
            } else if let idToken = credential?.idToken {
                callback(.success(idToken))
            } else {
                callback(.failure(Error.unexpectedGetSessionResult))
            }
        })
    }
}
