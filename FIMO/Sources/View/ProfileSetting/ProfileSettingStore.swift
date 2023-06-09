//
//  ProfileSettingStore.swift
//  PIMO
//
//  Created by Ok Hyeon Kim on 2023/02/16.
//  Copyright © 2023 pimo. All rights reserved.
//

import SwiftUI

import ComposableArchitecture

protocol NextButtonStateProtocol {
    var isActiveButton: Bool { get set }
}

protocol NextButtonActionProtocol {
    static var tappedNextButtonOnNickname: Self { get }
}

struct ProfileSettingStore: ReducerProtocol {
    struct State: Equatable, NextButtonStateProtocol {
        @BindingState var isShowToast: Bool = false
        var toastMessage: ToastModel = ToastModel(title: FIMOStrings.textCopyToastTitle,
                                                  message: FIMOStrings.textCopyToastMessage)

        // 회원가입 제출용 유저 식별자
        var userId: String = ""

        // MARK: 닉네임 설정
        @BindingState var nickname: String = ""
        var nicknameValidationType: CheckValidationType = .blank
        var isBlackNicknameField: Bool = true
        var isActiveButtonOnNickname: Bool = false
        var isActiveButton: Bool = false

        // MARK: 아카이브 설정
        @BindingState var archiveName: String = ""
        var archiveValidationType: CheckValidationType = .blank
        var isBlackArchiveField: Bool = true
        var isActiveButtonOnArchive: Bool = false

        // MARK: 프로필 이미지
        @BindingState var isShowImagePicker = false
        var selectedProfileImage: UIImage?
        var selectedImageURL: String?
        var isActiveButtonOnImage: Bool = false

        var isChangedInfo: Bool = false
    }

    enum Action: BindableAction, Equatable, NextButtonActionProtocol {
        case binding(BindingAction<State>)
        case onAppear
        case sendToast(ToastModel)
        case sendToastDone
        case checkDuplicateOnNickName
        case checkDuplicateOnNickNameDone(Result<Bool, NetworkError>)
        case tappedNextButtonOnNickname

        case tappedImagePickerButton
        case checkDuplicateOnArchive
        case checkDuplicateOnArchiveNameDone(Result<Bool, NetworkError>)
        case tappedNextButtonOnArchive

        case selectProfileImage(UIImage)
        case fetchImageURL
        case fetchImageURLDone(Result<ImgurImageModel, NetworkError>)
        case signUpOnProfilePicture
        case signUpDone(Result<FMServerDescriptionDTO, NetworkError>)

        case tappedCompleteButton

        case tappedCompleteModifyButton
        case modifyProfileDone(Result<FMProfileDTO, NetworkError>)
        case tappedBackButton

        case acceptBack
    }

    @Dependency(\.imgurImageClient) var imgurImageClient
    @Dependency(\.profileClient) var profileClient

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isBlackNicknameField = state.nickname == ""
                state.isBlackArchiveField = state.archiveName == ""
                return .none
            case let .sendToast(toastModel):
                if state.isShowToast {
                    return EffectTask<Action>(value: .sendToast(toastModel))
                        .delay(for: .milliseconds(1000), scheduler: DispatchQueue.main)
                        .eraseToEffect()
                } else {
                    state.isShowToast = true
                    state.toastMessage = toastModel
                    return EffectTask<Action>(value: .sendToastDone)
                        .delay(for: .milliseconds(2000), scheduler: DispatchQueue.main)
                        .eraseToEffect()
                }
            case .sendToastDone:
                state.isShowToast = false
                return .none
            case .binding(\.$nickname):
                state.isBlackNicknameField = state.nickname == ""
                state.isActiveButtonOnNickname = false

                let isKoreanEnglishAndNumber = !state.nickname.match(for: "^[가-힣a-zA-Z0-9]+$")
                let isBlack = state.nickname == ""
                let nicknameCount = state.nickname.replacingOccurrences(of: "[가-힣]", with: "00", options: .regularExpression)
                    .count

                state.nicknameValidationType = checkValidationOnTyping(isMatchCharactors: isKoreanEnglishAndNumber,
                                                                       isBlack: isBlack,
                                                                       charactorCount: nicknameCount,
                                                                       type: .nickname)

                return .none
            case .checkDuplicateOnNickName:
                guard state.nicknameValidationType == .beforeDuplicateCheck else {
                    return .none
                }

                return profileClient.isExistsNickname(state.nickname)
                    .map {
                        Action.checkDuplicateOnNickNameDone($0)
                    }
            case .checkDuplicateOnNickNameDone(let result):
                switch result {
                case .success(let isValidNickname):
                    state.nicknameValidationType = isValidNickname
                    ? .availableNickName
                    : .alreadyUsedNickname

                    state.isActiveButtonOnNickname = state.nicknameValidationType == .availableNickName
                    state.isChangedInfo = state.nicknameValidationType == .availableNickName
                case .failure(let error):
                    state.toastMessage = .init(title: error.errorDescription ?? "")
                    state.isShowToast = true
                }
                return .none
            case .binding(\.$archiveName):
                state.isBlackArchiveField = state.archiveName == ""
                state.isActiveButtonOnArchive = false

                let isKoreanEnglishAndNumber = !state.archiveName.match(for: "^[가-힣a-zA-Z0-9\\s]+$")
                let isBlack = state.archiveName == ""
                let archiveCharactorCount = state.archiveName.replacingOccurrences(of: "[가-힣]", with: "00", options: .regularExpression)
                    .count

                state.archiveValidationType = checkValidationOnTyping(isMatchCharactors: isKoreanEnglishAndNumber,
                                                                      isBlack: isBlack,
                                                                      charactorCount: archiveCharactorCount,
                                                                      type: .archiveName)

                return .none
            case .checkDuplicateOnArchive:
                guard state.archiveValidationType == .beforeDuplicateCheck else {
                    return .none
                }

                return profileClient.isExistsArchiveName(state.archiveName)
                    .map {
                        Action.checkDuplicateOnArchiveNameDone($0)
                    }
            case .checkDuplicateOnArchiveNameDone(let result):
                switch result {
                case .success(let isValidArchiveName):
                    state.archiveValidationType = isValidArchiveName
                    ? .availableArchiveName
                    : .alreadyUsedArchiveName

                    state.isActiveButtonOnArchive = state.archiveValidationType == .availableArchiveName
                    state.isChangedInfo = state.archiveValidationType == .availableArchiveName
                case .failure(let error):
                    state.toastMessage = .init(title: error.errorDescription ?? "")
                    state.isShowToast = true
                }
                return .none
            case .tappedImagePickerButton:
                state.isShowImagePicker = true
                return .none
            case .selectProfileImage(let image):
                state.selectedProfileImage = image

                return .init(value: Action.fetchImageURL)
            case .fetchImageURL:
                return imgurImageClient
                    .uploadImage(state.selectedProfileImage?.jpegData(compressionQuality: 0.9) ?? Data())
                    .map {
                        Action.fetchImageURLDone($0)
                    }
            case .fetchImageURLDone(let result):
                switch result {
                case .success(let imageModel):
                    state.selectedImageURL = imageModel.link
                    state.isActiveButtonOnImage = true
                    state.isChangedInfo = true
                    
                    return .none
                case .failure(let error):
                    state.toastMessage = .init(title: error.errorDescription ?? "")
                    state.isShowToast = true
                    return .none
                }
            case .tappedCompleteModifyButton:
                let result = profileClient.updateProfile(
                    state.nickname,
                    state.archiveName,
                    state.selectedImageURL ?? ""
                )

                return result.map {
                    Action.modifyProfileDone($0)
                }
            case .signUpOnProfilePicture:
                guard let imageURL = state.selectedImageURL else {
                    Log.error("이미지 URL이 없습니다.")
                    return .none
                }

                let signUpModel = FMSignUp(
                    identifier: state.userId,
                    nickname: state.nickname,
                    archiveName: state.archiveName,
                    profileImageUrl: imageURL
                )

                let signupResult = profileClient.signUp(signUpModel)

                return signupResult.map {
                    Action.signUpDone($0)
                }
            default:
                return .none
            }
        }
    }

    private func checkValidationOnTyping(isMatchCharactors: Bool,
                                         isBlack: Bool,
                                         charactorCount: Int,
                                         type: ProfileSettingFieldType) -> CheckValidationType {
        if isBlack {
            return .blank
        } else if isMatchCharactors {
            return .onlyKoreanEnglishAndNumber
        } else if charactorCount > 16 {
            return .exceededCharacters
        } else {
            return .beforeDuplicateCheck
        }
    }
}
