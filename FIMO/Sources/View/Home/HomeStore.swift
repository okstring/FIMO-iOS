//
//  HomeStore.swift
//  PIMO
//
//  Created by Ok Hyeon Kim on 2023/01/21.
//  Copyright © 2023 pimo. All rights reserved.
//

import SwiftUI

import ComposableArchitecture

enum HomeScene: Hashable {
    case home
    case setting
    case openSourceLicence
    case modifyProfile
}

struct HomeStore: ReducerProtocol {
    struct State: Equatable {
        @BindingState var path: [HomeScene] = []
        @BindingState var isShowToast: Bool = false
        @BindingState var isBottomSheetPresented: Bool = false
        var isLoading: Bool = false
        var toastMessage: ToastModel = ToastModel(title: FIMOStrings.textCopyToastTitle,
                                                  message: FIMOStrings.textCopyToastMessage)
        var feeds: IdentifiedArrayOf<FeedStore.State> = []
        var setting: SettingStore.State?
        var bottomSheet: BottomSheetStore.State?
        var profile: ProfileSettingStore.State?
        var audioPlayingFeedId: Int?
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case refresh
        case sendToast(ToastModel)
        case sendToastDone
        case fetchFeeds(Result<[FeedDTO], NetworkError>)
        case fetchFeedProfile(Result<Profile, NetworkError>)
        case feed(id: FeedStore.State.ID, action: FeedStore.Action)
        case settingButtonDidTap
        case receiveProfileInfo(FMProfile)
        case setting(SettingStore.Action)
        case onboarding(OnboardingStore.Action)
        case bottomSheet(BottomSheetStore.Action)
        case profile(ProfileSettingStore.Action)
        case dismissBottomSheet(Feed)
        case deleteFeed(Result<Bool, NetworkError>)
    }
    
    @Dependency(\.homeClient) var homeClient
    
    private let pasteboard = UIPasteboard.general
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
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
            case .onAppear:
                state.isLoading = true
                return homeClient.fetchFeeds().map {
                    Action.fetchFeeds($0)
                }
            case .refresh:
                return homeClient.fetchFeeds().map {
                    Action.fetchFeeds($0)
                }
            case let .fetchFeeds(result):
                switch result {
                case let .success(feeds):
                    var firstFeed = 0
                    if !feeds.isEmpty { firstFeed = feeds[0].id }
                    state.feeds = IdentifiedArrayOf(
                        uniqueElements: feeds.map { $0.toModel() }.map { feed in
                            FeedStore.State(
                                textImage: feed.textImages[0],
                                id: feed.id,
                                feed: feed,
                                isFirstFeed: (feed.id == firstFeed) ? true : false,
                                clapCount: feed.clapCount,
                                isClapped: feed.isClapped
                            )
                        }
                    )
                default:
                    break
                }
                state.isLoading = false
            case let .feed(id: id, action: action):
                switch action {
                case let .copyButtonDidTap(text):
                    pasteboard.string = text
                    state.isShowToast = true
                case let .moreButtonDidTap(id):
                    state.isBottomSheetPresented = true
                    state.bottomSheet = BottomSheetStore.State(feedId: id,
                                                               feed: state.feeds[id: id]?.feed ?? Feed.EMPTY,
                                                               bottomSheetType: .me)
                case .audioButtonDidTap:
                    guard let feedId = state.audioPlayingFeedId else {
                        state.audioPlayingFeedId = id
                        break
                    }
                    if state.feeds[id: feedId]?.audioButtonDidTap ?? false && feedId != id {
                        state.feeds[id: feedId]?.audioButtonDidTap.toggle()
                    }
                    state.audioPlayingFeedId = id
                default:
                    break
                }
            case let .bottomSheet(action):
                switch action {
                case let  .editButtonDidTap(feed):
                    state.isBottomSheetPresented = false
                    return EffectTask<Action>(value: .dismissBottomSheet(feed))
                        .delay(for: .seconds(0.3), scheduler: DispatchQueue.main)
                        .eraseToEffect()
                case .deleteButtonDidTap:
                    state.isBottomSheetPresented = false
                case .declationButtonDidTap:
                    state.isBottomSheetPresented = false
                }
            case let .deleteFeed(result):
                switch result {
                case .success:
                    return .send(.onAppear)
                default:
                    print("error")
                }
            case .receiveProfileInfo(let profile):
                state.setting = SettingStore.State(profile: profile)
                state.path.append(.setting)
            case .setting(.tappedLicenceButton):
                state.path.append(.openSourceLicence)
            case .setting(.tappedProfileManagementButton):
                state.profile = ProfileSettingStore.State(
                    nickname: state.setting?.profile.nickname ?? "",
                    archiveName: state.setting?.profile.archiveName ?? "",
                    selectedImageURL: state.setting?.profile.profileImageUrl ?? ""
                )
                state.path.append(.modifyProfile)
            default:
                break
            }
            return .none
        }
        .ifLet(\.setting, action: /Action.setting) {
            SettingStore()
        }
        .ifLet(\.bottomSheet, action: /Action.bottomSheet) {
            BottomSheetStore()
        }
        .forEach(\.feeds, action: /Action.feed(id:action:)) {
            FeedStore()
        }
        .ifLet(\.profile, action: /Action.profile) {
            ProfileSettingStore()
        }
    }
}
