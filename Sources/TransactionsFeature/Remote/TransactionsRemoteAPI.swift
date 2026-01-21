import Foundation
import CoreNetworking

protocol TransactionsRemoteAPI: Sendable {
    func fetchTransactions() async throws -> [TransactionDTO]
}

struct DefaultTransactionsRemoteAPI: TransactionsRemoteAPI {
    private let client: APIClient
    private let baseURL: URL

    init(client: APIClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    func fetchTransactions() async throws -> [TransactionDTO] {
        let endpoint = Endpoint(path: "/transactions")
        let request = endpoint.makeRequest(baseURL: baseURL)
        // Inject our decoder by constructing a DefaultAPIClient with JSONDecoder.financeAPI in composition (Step 4.3),
        // so here we just call client.
        return try await client.request(request, as: [TransactionDTO].self)
    }
}
