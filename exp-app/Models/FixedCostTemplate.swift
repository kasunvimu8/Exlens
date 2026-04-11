//
//  FixedCostTemplate.swift
//  exp-app
//

import Foundation

struct FixedCostTemplate: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var categoryID: UUID
    var categoryName: String
    var categoryIcon: String
}
