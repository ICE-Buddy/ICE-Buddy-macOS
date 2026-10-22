//
//  TrainBuddyWidgetsBundle.swift
//  TrainBuddyWidgets
//
//  Created by Frederik Riedel on 22.10.26.
//

import WidgetKit
import SwiftUI
import AppIntents
import TrainBuddyKit

@main
struct TrainBuddyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TrainBuddyWidgets()
        TrainBuddyLiveActivityWidget()
        StartTrainActivityControl()
    }
}
