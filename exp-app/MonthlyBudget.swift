//
//  MonthlyBudget.swift
//  exp-app
//
//  Created by Kasun Vimukthi on 05.04.26.
//

import Foundation

struct MonthlyBudget: Identifiable, Codable {
    var id = UUID()
    var year: Int
    var month: Int
    var amount: Double
}
