//
//  IceHeaderView.swift
//  ICE Buddy
//
//  Created by Simon Kroner on 20.05.25.
//

import DBConnect
import SwiftUI
import TrainConnect

struct IceHeaderView: View {
    #if os(macOS)
        @State var trainIcon: NSImage?
    #else
        @State var trainIcon: Image?
    #endif
    var body: some View {
        if let trainIcon = trainIcon {
            #if os(macOS)
                Image(nsImage: trainIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            #else
                Image(image: trainIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            #endif
        } else {
            Text("Loading...")
            // TODO: Error handling
        }
    }
}

#Preview {
    let connectDataHandler = ConnectDataHandler(demoMode: true)
    if let trainIcon = connectDataHandler.train?.trainType.trainIcon {
        IceHeaderView(trainIcon: trainIcon)
            .frame(width: 300, height: 400)
    }
}
