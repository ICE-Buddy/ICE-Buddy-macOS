//
//  JourneyBadgeView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 20.05.25.
//

import SwiftUI

struct JourneyBadgeView: View {
    @State var hasPassed: Bool
    var body: some View {
        VStack(spacing: 0) {
            Image(hasPassed ? "stop_badge_grey" : "stop_badge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 5)
            Image(hasPassed ? "stop_icon_grey" : "stop_icon")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 10, height: 10)
            Image(hasPassed ? "stop_badge_grey" : "stop_badge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 5)
        }
    }
}

#Preview {
    JourneyBadgeView(hasPassed: false)
        .frame(width: 200, height: 200)
}
