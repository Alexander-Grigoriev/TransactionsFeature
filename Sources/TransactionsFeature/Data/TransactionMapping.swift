import Foundation
import CoreData
import SharedDomain

enum TransactionMapping {

    static func toDomain(_ obj: NSManagedObject) -> FinanceTransaction? {
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let date = obj.value(forKey: "date") as? Date,
            let currencyCode = obj.value(forKey: "currencyCode") as? String,
            let categoryRaw = obj.value(forKey: "categoryRaw") as? String,
            let merchant = obj.value(forKey: "merchant") as? String
        else { return nil }

        // Core Data Decimal may come as NSDecimalNumber
        let amountDecimal: Decimal
        if let ns = obj.value(forKey: "amount") as? NSDecimalNumber {
            amountDecimal = ns.decimalValue
        } else if let dec = obj.value(forKey: "amount") as? Decimal {
            amountDecimal = dec
        } else {
            return nil
        }

        let category = Category(rawValue: categoryRaw) ?? .other

        return FinanceTransaction(
            id: id,
            date: date,
            money: Money(amount: amountDecimal, currencyCode: currencyCode),
            category: category,
            merchant: merchant
        )
    }

    static func makeFetchRequest(filter: TransactionsFilter) -> NSFetchRequest<NSManagedObject> {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TransactionEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        var predicates: [NSPredicate] = []

        if let from = filter.from {
            predicates.append(NSPredicate(format: "date >= %@", from as NSDate))
        }
        if let to = filter.to {
            predicates.append(NSPredicate(format: "date <= %@", to as NSDate))
        }
        if !filter.categories.isEmpty {
            let raws = filter.categories.map(\.rawValue)
            predicates.append(NSPredicate(format: "categoryRaw IN %@", raws))
        }

        if !predicates.isEmpty {
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        return req
    }
}
