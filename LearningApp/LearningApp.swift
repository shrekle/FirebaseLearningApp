//
//  LearningAppApp.swift
//  LearningApp
//
//  Created by Christopher Ching on 2021-03-03.
//
// MINE // MINE // MINE // MINE // MINE // MINE // MINE // MINE // MINE
import SwiftUI
import FirebaseCore

@main
struct LearningApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(ContentModel())
        }
    }
}
