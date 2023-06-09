//
//  MyProfile.swift
//  FIMO
//
//  Created by Ok Hyeon Kim on 2023/06/22.
//  Copyright © 2023 pimo. All rights reserved.
//

import Foundation

struct FMProfile: Equatable {
    let id: String
    let nickname: String
    let archiveName: String
    let profileImageUrl: String
    let postCount: Int
}

extension FMProfile {
    static let EMPTY: FMProfile = FMProfile(
        id: "",
        nickname: "",
        archiveName: "",
        profileImageUrl: "",
        postCount: 0
    )
}
