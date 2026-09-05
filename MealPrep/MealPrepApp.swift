//
//  MealPrepApp.swift
//  MealPrep
//
//  Created by Davide Merassi on 04/09/2026.
//

import SwiftUI

@main
struct MealPrepApp: App {
    init() {
        PromoFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
