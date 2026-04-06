import Foundation

extension ExpenseStore {
    var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [
            NSLocale.Key.currencyCode.rawValue: selectedCurrency
        ]))
        return locale.currencySymbol ?? selectedCurrency
    }
}
