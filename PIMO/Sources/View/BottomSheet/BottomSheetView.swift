//
//  BottomSheetView.swift
//  PIMO
//
//  Created by 김영인 on 2023/03/21.
//  Copyright © 2023 pimo. All rights reserved.
//

import SwiftUI

import ComposableArchitecture

struct BottomSheetView: View {
    let store: StoreOf<BottomSheetStore>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(alignment: .center) {
                Spacer()
                    .frame(height: 32)
                
                if viewStore.bottomSheetType == .me {
                    bottomSheetText(text: "수정하기")
                        .onTapGesture {
                            viewStore.send(.editButtonDidTap)
                        }
                    
                    Spacer()
                        .frame(height: 26)
                    
                    bottomSheetText(text: "삭제하기")
                        .onTapGesture {
                            viewStore.send(.deleteButtonDidTap)
                        }
                } else {
                    bottomSheetText(text: "신고하기")
                        .onTapGesture {
                            viewStore.send(.declationButtonDidTap)
                        }
                }
            }
        }
    }
    
    func bottomSheetText(text: String) -> some View {
        Text(text)
            .font(Font(PIMOFontFamily.Pretendard.regular.font(size: 18)))
    }
}
