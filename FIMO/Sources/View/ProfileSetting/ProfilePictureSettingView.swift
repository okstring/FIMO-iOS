//
//  ProfilePictureSettingView.swift
//  PIMO
//
//  Created by Ok Hyeon Kim on 2023/02/17.
//  Copyright © 2023 pimo. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Kingfisher

struct ProfilePictureSettingView: View {
    let store: StoreOf<ProfileSettingStore>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                CustomNavigationBar(
                    title: "프로필 생성",
                    trailingItemType: .page(3, 3),
                    isShadowed: false
                )

                ProgressView(value: 100, total: 100)
                    .tint(Color(FIMOAsset.Assets.red1.color))

                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("프로필 사진을 등록해주세요")
                            .padding(.top, 42)
                            .font(.system(size: 20, weight: .semibold))
                    }

                    profileImageButton(viewStore)

                    nextButton(viewStore)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: viewStore.binding(\.$isShowImagePicker)) {
                ImagePicker { uiImage in
                    viewStore.send(.selectProfileImage(uiImage))
                }
            }
            .toast(isShowing: viewStore.binding(\.$isShowToast),
                   title: viewStore.toastMessage.title,
                   message: viewStore.toastMessage.message)
        }
    }

    func profileImageButton(_ viewStore: ViewStore<ProfileSettingStore.State, ProfileSettingStore.Action>) -> some View {
        VStack {
            Button(action: {
                viewStore.send(.tappedImagePickerButton)
            }, label: {
                if viewStore.selectedImageURL == nil {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(FIMOAsset.Assets.gray1.color), style: StrokeStyle(lineWidth: 1))
                            .aspectRatio(1.0, contentMode: .fit)
                            .foregroundColor(.clear)

                        Image(uiImage: FIMOAsset.Assets.image.image)
                    }
                } else {
                    ZStack {
                        KFImage(URL(string: viewStore.selectedImageURL ?? ""))
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .cornerRadius(4)

                        ZStack {
                            Rectangle()

                            Circle()
                                .blendMode(.destinationOut)
                        }
                        .aspectRatio(1.0, contentMode: .fit)
                        .compositingGroup()
                        .foregroundColor(.black)
                        .opacity(0.6)
                    }

                }
            })
            .frame(maxWidth: .infinity)
            .padding(.top, 44)
        }
    }

    func nextButton(_ viewStore: ViewStore<ProfileSettingStore.State, ProfileSettingStore.Action>) -> some View {
        Button {
            viewStore.send(.signUpOnProfilePicture)
        } label: {
            Text("완료")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    viewStore.isActiveButtonOnImage
                    ? Color(FIMOAsset.Assets.red2.color)
                    : Color(FIMOAsset.Assets.gray1.color)
                    )
                .cornerRadius(2)
        }
        .disabled(!viewStore.isActiveButtonOnImage)
        .padding(.top, 34)
    }
}

struct ProfilePictureSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePictureSettingView(
            store: Store(
                initialState: ProfileSettingStore.State(),
                reducer: ProfileSettingStore()
            )
        )
    }
}
