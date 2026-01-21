import Foundation

enum StubJSONLoader {
    static func data(named name: String) -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing stub json: \(name).json in TransactionsFeature resources")
        }
        return data
    }
}
