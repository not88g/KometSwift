// Multi-account support — mirrors services/account_manager.dart.
// Stores account list in Keychain as JSON.

import Foundation

actor AccountManager {
    static let shared = AccountManager()

    private(set) var accounts: [Account] = []
    private(set) var currentAccount: Account?

    private let accountsKey = "komet.accounts"
    private let currentIdKey = "komet.currentAccountId"

    func initialize() async {
        accounts = loadAccounts()
        let currentId = UserDefaults.standard.string(forKey: currentIdKey)
        currentAccount = accounts.first(where: { $0.id == currentId }) ?? accounts.first
        if let token = currentAccount?.token {
            APIService.shared.setAuthToken(token)
        }
    }

    var currentUserId: Int { currentAccount?.userId ?? 0 }

    func addOrUpdateAccount(_ account: Account) async {
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
        } else {
            accounts.append(account)
        }
        saveAccounts()
        await switchTo(account)
    }

    func switchTo(_ account: Account) async {
        currentAccount = account
        UserDefaults.standard.set(account.id, forKey: currentIdKey)
        APIService.shared.setAuthToken(account.token)
        await TokenStore.shared.saveToken(account.token, userId: account.userId)
    }

    func removeAccount(_ account: Account) async {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
        if currentAccount?.id == account.id {
            currentAccount = accounts.first
            if let first = currentAccount {
                await switchTo(first)
            } else {
                await TokenStore.shared.clearToken()
                APIService.shared.clearAuthToken()
            }
        }
    }

    // MARK: - Persistence (Keychain as JSON)

    private func loadAccounts() -> [Account] {
        guard let data = KeyValueStore.shared.data(forKey: accountsKey),
              let decoded = try? JSONDecoder().decode([Account].self, from: data)
        else { return [] }
        return decoded
    }

    private func saveAccounts() {
        let data = try? JSONEncoder().encode(accounts)
        KeyValueStore.shared.set(data, forKey: accountsKey)
    }
}
