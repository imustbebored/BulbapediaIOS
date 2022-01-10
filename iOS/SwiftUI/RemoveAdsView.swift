//
//  RemoveAdsView.swift
//  iOS
//
//  Created by Big Sur on 08/01/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RemoveAdsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        content
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    var content: some View {
        ZStack {
            Color(.white).opacity(0.2).edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("icn_close")
                            .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                    }
                    Spacer()
                }
                
                Image("img_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                Text("Upgrade to Pro!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Text("Going Pro removes all ads AND allows you to download the entire wiki for offline viewing without any internet.")
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: {
                        print("Clicked left")
                    }) {
                        Text("₹320.00 / YEAR")
                            .foregroundColor(.white)
                    }
                    .background(Color.green)
                    
                    Button(action: {
                        print("Clicked right")
                    }) {
                        Text("₹450.00 / ONE TIME")
                            .foregroundColor(.white)
                    }
                    .background(Color.green)
                }
                .frame(height: 50)
                Spacer()
                Text("Remove Ads and Go Offline")
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .foregroundColor(Color.black.opacity(0.7))
            .padding()
        }
    }
    
}
