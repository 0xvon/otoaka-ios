//
//  S3Client.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/21.
//

import AWSS3
import Foundation

class S3Client {
    let s3Bucket: String

    init(s3Bucket: String) {
        self.s3Bucket = s3Bucket
    }

    public func uploadImage(image: UIImage?, callback: @escaping ((String?, String?) -> Void)) {
        let transferUtility = AWSS3TransferUtility.default()
        let key = "\(UUID()).png"
        let contentType = "application/png"
        let im: UIImage = image ?? UIImage(named: "band")!
        guard let pngData = im.pngData() else {
            callback(nil, "cannot convert image to png data")
            return
        }

        let expression = AWSS3TransferUtilityUploadExpression()
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = {
            (task, error) -> Void in
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
