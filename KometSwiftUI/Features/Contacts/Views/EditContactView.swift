import SwiftUI

struct EditContactView: View {
    let userId: Int

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var isSaving  = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(String(localized: "Name")) {
                TextField(String(localized: "First name"), text: $firstName)
                    .textContentType(.givenName)
                TextField(String(localized: "Last name"), text: $lastName)
                    .textContentType(.familyName)
            }
        }
        .navigationTitle(String(localized: "Edit Contact"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Save")) {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
        .task { await load() }
    }

    private func load() async {
        if let local = await ContactLocalNamesService.shared.localName(for: userId) {
            firstName = local.0
            lastName  = local.1
        } else if let contact = try? await APIService.shared.fetchContact(userId: userId) {
            firstName = contact.firstName
            lastName  = contact.lastName
        }
    }

    private func save() async {
        isSaving = true
        await ContactLocalNamesService.shared.setLocalName(
            userId: userId,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName:  lastName.trimmingCharacters(in: .whitespaces)
        )
        isSaving = false
        dismiss()
    }
}
