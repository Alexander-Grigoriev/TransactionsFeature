import Foundation

struct TransactionDTO: Decodable {
    let id: UUID
    let date: Date
    let amount: Decimal
    let currencyCode: String
    let category: String
    let merchant: String

    private enum CodingKeys: String, CodingKey {
        case id, date, amount, currencyCode, category, merchant
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)

        // amount comes as String -> Decimal
        let amountString = try c.decode(String.self, forKey: .amount)
        guard let dec = Decimal(string: amountString) else {
            throw DecodingError.dataCorruptedError(forKey: .amount, in: c, debugDescription: "Invalid decimal string")
        }
        amount = dec

        currencyCode = try c.decode(String.self, forKey: .currencyCode)
        category = try c.decode(String.self, forKey: .category)
        merchant = try c.decode(String.self, forKey: .merchant)
    }
}

public extension JSONDecoder {
    static var financeAPI: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
