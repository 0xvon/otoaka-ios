//
//  RocketTests.swift
//  RocketTests
//
//  Created by kateinoigakukun on 2020/10/16.
//

import StubKit
import AWSCognitoAuth
import AWSCore
import Firebase
import Networking
import ImagePipeline
import Foundation
import Endpoint
import Combine
@testable import Rocket

class MockHTTPClient: HTTPClientProtocol {
    func request<E>(_ endpoint: E.Type, request: E.Request, uri: E.URI, file: StaticString, line: UInt) -> AnyPublisher<E.Response, Error> where E : EndpointProtocol {
        Just(try! Stub.make()).mapError { _ -> Error in }.eraseToAnyPublisher()
    }
    func request<E>(_ endpoint: E.Type, request: E.Request, uri: E.URI, file: StaticString, line: UInt,
                    callback: @escaping ((Result<E.Response, Error>) -> Void)) where E : EndpointProtocol {
        callback(.success(try! Stub.make()))
    }
}

extension UUID: Stubbable {
    public static func stub() -> UUID {
        UUID()
    }
}

extension DependencyProvider {
    
    static func makeStub(windowScene: UIWindowScene, urlScheme: URL? = nil) -> DependencyProvider {
        return .makeStub(config: EnvironmentConfig.self, windowScene: windowScene, urlScheme: urlScheme)
    }
    
    static func makeStub(config: Config.Type, windowScene: UIWindowScene, urlScheme: URL?) -> DependencyProvider {
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
        AWSCognitoAuth.registerCognitoAuth(with: cognitoConfiguration, forKey: cognitoAuthKey)
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
            auth: auth, apiClient: apiClient,
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
