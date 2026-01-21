import Foundation
import CoreNetworking
import CorePersistence
import SharedDomain
import SwiftUI

public enum TransactionsFeatureBuilder {

    public static func makeRepository(stack: CoreDataStack) -> any TransactionsRepository {
        let json = StubJSONLoader.data(named: "transactions")
        let transport = StubTransport(responses: ["/transactions": json])

        let client = DefaultAPIClient(transport: transport, decoder: .financeAPI)
        let remote = DefaultTransactionsRemoteAPI(
            client: client,
            baseURL: URL(string: "https://stub.local")!
        )

        return TransactionsRepositoryImpl(stack: stack, remote: remote)
    }

    public static func makeScreen(repository: any TransactionsRepository) -> some View {
        TransactionsScreen(viewModel: .init(repo: repository))
    }
}
