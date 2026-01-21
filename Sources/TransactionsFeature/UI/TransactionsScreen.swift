import SwiftUI
import SharedDomain

public final class TransactionsViewModel: ObservableObject {
    @Published public private(set) var transactions: [FinanceTransaction] = []
    private let repo: any TransactionsRepository
    private var task: Task<Void, Never>?

    public init(repo: any TransactionsRepository) {
        self.repo = repo
    }

    public func start() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                // kick off refresh once
                try await repo.refreshTransactions()

                for try await items in repo.observeTransactions(filter: .init()) {
                    await MainActor.run { self.transactions = items }
                }
            } catch {
                // keep simple for now; later we’ll add error state
            }
        }
    }

    deinit { task?.cancel() }
}

public struct TransactionsScreen: View {
    @StateObject private var vm: TransactionsViewModel

    public init(viewModel: TransactionsViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List(vm.transactions) { tx in
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.merchant)
                Text("\(NSDecimalNumber(decimal: tx.money.amount)) \(tx.money.currencyCode)")
                    .font(.caption)
            }
        }
        .navigationTitle("Transactions")
        .onAppear { vm.start() }
    }
}
