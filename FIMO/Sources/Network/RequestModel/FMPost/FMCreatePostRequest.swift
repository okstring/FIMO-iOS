//
//  FMCreatePostRequest.swift
//  FIMO
//
//  Created by Ok Hyeon Kim on 2023/06/22.
//  Copyright © 2023 pimo. All rights reserved.
//

import Foundation

import Alamofire

struct FMCreatePostRequest: Requestable {
    typealias Response = FMPostDTO
    let newPostItems: FMUpdatedPost

    var path: String {
        return "/post/create"
    }

    var method: HTTPMethod {
        return .post
    }

    var parameters: Parameters {
        return [
            "items": newPostItems.items.map({
                [
                    "imageUrl": $0.imageUrl,
                    "content": $0.content
                ]
            })
        ]
    }

    var header: [HTTPFields: String] {
        return [
            HTTPFields.authorization: HTTPHeaderType.authorization.header
        ]
    }
}
