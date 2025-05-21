//
//  AboutView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 19.05.25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("ICE Buddy")
                .font(.title)
            Text("Developed by Frederik Riedel on an ICE.")
                .padding(5)
            Text("Amount of API calls reduced to a minimum (only on user interaction).")
                .foregroundStyle(.secondary)
            HStack {
                Text("App Icon Design by Donatus Wolf:")
                    .foregroundStyle(.secondary)
                Link("donatuswolf.de", destination: URL(string: "https://donatuswolf.de")!)
            }
            .padding(10)
            Image("ICE Buddy App icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            Spacer()
            HStack {
                Spacer()
                Link("Imprint", destination: URL(string: "https://riedel.wtf/imprint/")!)
                    .buttonStyle(.bordered)
                Link("Privacy Policy", destination: URL(string: "https://riedel.wtf/privacy/")!)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    AboutView()
}
