import Foundation
import CoreData
import SharedDomain
import CoreNetworking
import CorePersistence

public final class TransactionsRepositoryImpl: TransactionsRepository {

    private let stack: CoreDataStack
    private let remote: TransactionsRemoteAPI

    init(stack: CoreDataStack, remote: TransactionsRemoteAPI) {
        self.stack = stack
        self.remote = remote
    }

    public func observeTransactions(filter: TransactionsFilter) -> AsyncThrowingStream<[FinanceTransaction], Error> {
        let context = stack.container.viewContext
        let request = TransactionMapping.makeFetchRequest(filter: filter)

        return AsyncThrowingStream { continuation in
            // 1) Emit initial value
            let initialTask = Task {
                do {
                    let items = try await context.perform {
                        let objs = try context.fetch(request)
                        return objs.compactMap{ TransactionMapping.toDomain($0) }
                    }
                    continuation.yield(items)
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // 2) Re-emit on Core Data changes
            let center = NotificationCenter.default
            let token = center.addObserver(
                forName: .NSManagedObjectContextObjectsDidChange,
                object: context,
                queue: nil
            ) { _ in
                Task {
                    do {
                        let items = try await context.perform {
                            let objs = try context.fetch(request)
                            return objs.compactMap(TransactionMapping.toDomain)
                        }
                        continuation.yield(items)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }

            continuation.onTermination = { _ in
                initialTask.cancel()
                center.removeObserver(token)
            }
        }
    }

    public func refreshTransactions() async throws {
        let dtos = try await remote.fetchTransactions()

        try await stack.performWrite { ctx in
            for dto in dtos {
                let existing = try Self.fetchTransaction(by: dto.id, in: ctx)
                let obj: NSManagedObject

                if let existing {
                    obj = existing
                } else {
                    obj = NSEntityDescription.insertNewObject(
                        forEntityName: "TransactionEntity",
                        into: ctx
                    )
                }

                obj.setValue(dto.id, forKey: "id")
                obj.setValue(dto.date, forKey: "date")
                obj.setValue(NSDecimalNumber(decimal: dto.amount), forKey: "amount")
                obj.setValue(dto.currencyCode, forKey: "currencyCode")
                obj.setValue(dto.category, forKey: "categoryRaw")
                obj.setValue(dto.merchant, forKey: "merchant")
            }
        }
    }

    private static func fetchTransaction(by id: UUID, in ctx: NSManagedObjectContext) throws -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TransactionEntity")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try ctx.fetch(req).first
    }
}
