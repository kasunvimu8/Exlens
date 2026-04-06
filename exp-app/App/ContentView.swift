//
//  ContentView.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 04.04.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
            
            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle.fill") }
            
            RecommendationsView()
                .tabItem { Label("Insights", systemImage: "lightbulb.fill") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
}
