//
//  CustomCategory.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import Foundation

struct CustomCategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var color: String // Store as hex string
    
    static let defaultCategories: [CustomCategory] = [
        CustomCategory(name: "Food", icon: "fork.knife", color: "orange"),
        CustomCategory(name: "Transport", icon: "car.fill", color: "blue"),
        CustomCategory(name: "Shopping", icon: "bag.fill", color: "pink"),
        CustomCategory(name: "Bills", icon: "doc.text.fill", color: "red"),
        CustomCategory(name: "Entertainment", icon: "film.fill", color: "purple"),
        CustomCategory(name: "Other", icon: "ellipsis.circle.fill", color: "gray")
    ]
}
