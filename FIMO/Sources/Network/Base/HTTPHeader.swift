//
//  HTTPHeaderType.swift
//  PIMO
//
//  Created by Ok Hyeon Kim on 2023/01/21.
//  Copyright © 2023 pimo. All rights reserved.
//

import Foundation

enum HTTPHeaderType {
    case contentType
    case multiPartFormData
    case authorization
    case imgurClientID

    var header: String {
        switch self {
        case .contentType:
            return "application/json"
        case .multiPartFormData:
            return "multipart/form-data"
        case .authorization:
            return "Bearer \(UserUtill.shared.accessToken)"
        case .imgurClientID:
            guard let clientID = Bundle.main.infoDictionary?["ClientID"] as? String else {
                return ""
            }
            return "Client-ID \(clientID)"
        }
    }
}

enum HTTPFields: String, CustomStringConvertible {
    case contentType = "Content-Type"
    case accept = "Accept"
    case authorization = "Authorization"

    var description: String {
        return self.rawValue
    }
}
