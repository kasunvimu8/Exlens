//
//  Expense.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 04.04.26.
//

import Foundation

struct Expense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var date: Date
    var categoryID: UUID
    var categoryName: String
    var categoryIcon: String
    var isFixed: Bool = false
}
