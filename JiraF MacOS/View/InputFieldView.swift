import SwiftUI

struct InputFieldRow: Identifiable, Hashable {
    let id = UUID()
    var title: String = ""
    var devHours: String = ""
    var solutionHours: String = ""
}

struct InputFieldView: View {
    
    @State private var rows: [InputFieldRow] = [InputFieldRow()]
    @FocusState private var focusedField: UUID?
    
    @Binding var isBusy: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    
                    ForEach($rows) { $row in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            
                            TextField("Subtask title/summary", text: $row.title)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 160)
                                .focused($focusedField, equals: row.id)
                            
                            TextField("Dev hour", text: $row.devHours)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                                .onChange(of: row.devHours) {
                                    row.devHours = filteredNumber(row.devHours)
                                }
                            
                            TextField("Solution Hour", text: $row.solutionHours)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                                .onChange(of: row.solutionHours) {
                                    row.solutionHours = filteredNumber(row.solutionHours)
                                }
                            
                            if rows.count > 1 {
                                Button(role: .destructive) {
                                    remove(rowID: row.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Remove row")
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            Button(action: addRow) {
                Label("Add another", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding()
    }
    
    private func addRow() {
        let new = InputFieldRow()
        rows.append(new)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = new.id
        }
    }
    
    private func remove(rowID: UUID) {
        isBusy = true
        // Clear focus first to avoid SwiftUI trying to access a deallocated binding
        if focusedField == rowID {
            focusedField = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                rows.removeAll { $0.id == rowID }
            }
            if focusedField == nil, let last = rows.last {
                focusedField = last.id
            }
            isBusy = false
        }
    }
    
    private func filteredNumber(_ input: String) -> String {
        // Allow digits + optional decimal
        let allowed = "0123456789.".map { String($0) }
        var dotSeen = false
        var result = ""
        for ch in input {
            if ch == "." {
                if dotSeen {
                    continue
                } else {
                    dotSeen = true
                }
            }
            if allowed.contains(String(ch)) {
                result.append(ch)
            }
        }
        return result
    }
}

#Preview { InputFieldView(isBusy: .constant(false)) }
