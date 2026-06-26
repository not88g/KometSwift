// Mirrors services/contact_local_names_service.dart.
// Stores user-defined local name overrides for contacts.

import Foundation

actor ContactLocalNamesService {
    static let shared = ContactLocalNamesService()

    private let key = "komet.localContactNames"
    private var names: [Int: (String, String)] = [:]  // userId → (firstName, lastName)

    func initialize() async {
        if let data = UserDefaults.standard.data(forKey: key),
           let dict = try? JSONDecoder().decode([String: [String]].self, from: data) {
            names = dict.compactMapKeys { Int($0) }.mapValues { ($0[0], $0.count > 1 ? $0[1] : "") }
        }
    }

    func localName(for userId: Int) -> (String, String)? { names[userId] }

    func setLocalName(userId: Int, firstName: String, lastName: String) async {
        names[userId] = (firstName, lastName)
        persist()
    }

    func clearLocalName(for userId: Int) async {
        names.removeValue(forKey: userId)
        persist()
    }

    private func persist() {
        let dict = names.reduce(into: [String: [String]]()) { $0["\($1.key)"] = [$1.value.0, $1.value.1] }
        let data = try? JSONEncoder().encode(dict)
        UserDefaults.standard.set(data, forKey: key)
    }
}

private extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        reduce(into: [:]) { result, pair in
            if let key = transform(pair.key) { result[key] = pair.value }
        }
    }
}
