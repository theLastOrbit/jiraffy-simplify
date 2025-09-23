import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var root: RootViewModel
    
    @State private var parentKey: String = ""
    @State private var selectedSquad: JiraSquad? = nil
    @State private var parentKeyError: String? = nil
    
    @State private var showAlert = false
    
    // Validation: must match ^MYGP-\\d+$
    private func validateParentKey() {
        root.parentTicketName = ""
        
        let trimmed = parentKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            parentKeyError = nil
            return
        }
        
        let pattern = "^\(root.projectKeyPrefix)-\\d+$"
        if trimmed.range(of: pattern, options: .regularExpression) == nil {
            if trimmed.hasPrefix("\(root.projectKeyPrefix)-") {
                parentKeyError = "Enter digits after \(root.projectKeyPrefix)-"
            } else {
                parentKeyError = "Must start with \(root.projectKeyPrefix)-"
            }
        } else {
            parentKeyError = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            topView()
            InputFieldView(root: root)
            Spacer()
            bottomView()
        }
        .alert(root.parentTicketName, isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Create", role: .none) {
                root.createSubtask()
            }
        } message: {
            Text("Create sub-tasks under \(parentKey)\nin squad \(selectedSquad?.name ?? "") ??")
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
}


extension HomeView {
    
    @ViewBuilder
    func topView() -> some View {
        HStack {
            if let user = root.user {
                Text("Welcome, \(user.displayName) 👋")
                    .font(.largeTitle)
            } else {
                Text("Loading user…")
            }
            Spacer()
            
            Button("Reload User") {
                Task { await root.evaluateToken() }
            }
            .disabled(root.isBusy)
            
            Button("Logout") {
                root.logout()
            }
        }
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        HStack(spacing: 4) {
            Spacer()
            
            Text("Parent Key:")
            
            VStack(alignment: .leading, spacing: 2) {
                TextField("MYGP-100", text: $parentKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
                    .onChange(of: parentKey) {
                        parentKey = parentKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        validateParentKey()
                    }
                    .overlay {
                        if parentKeyError != nil {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.7), lineWidth: 1)
                        }
                    }
                if let error = parentKeyError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer().frame(width: 8)
            
            Text("Squad:")
            Menu {
                if root.squads.isEmpty {
                    Text("No squads available")
                } else {
                    ForEach(root.squads, id: \.name) { squad in
                        Button(squad.name) { selectedSquad = squad }
                    }
                    if selectedSquad != nil {
                        Divider()
                        Button("Clear Selection") { selectedSquad = nil }
                    }
                }
            } label: {
                Text(selectedSquad?.name ?? "Select Squad")
                    .frame(minWidth: 120, alignment: .leading)
            }
            .fixedSize()
            
            Spacer().frame(width: 8)
            
            Button("Submit") {
                Task {
                    do {
                        showAlert = try await root.getTicket(key: parentKey)
                    } catch {
                        parentKeyError = "Not found, enter a valid key"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedSquad == nil || parentKey.isEmpty || parentKeyError != nil)
        }
    }
}

#Preview { HomeView().environmentObject(RootViewModel()) }
