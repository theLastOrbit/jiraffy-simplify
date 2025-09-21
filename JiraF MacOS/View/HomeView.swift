
import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var root: RootViewModel
    @State private var parentKey: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            InputFieldView(isBusy: $root.isBusy)
            
            Spacer()
            
            HStack(spacing: 4) {
                Spacer()
                
                Text("Parent Key:")
                
                TextField("MYGP-100", text: $parentKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .onChange(of: parentKey) {
                        parentKey = parentKey.uppercased()
                    }
                
                Spacer()
                    .frame(width: 8)
                
                Text("Squad Name: Sigma")
                
                Spacer()
                    .frame(width: 8)
                
                Button("Submit") {
                    
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
}

#Preview { HomeView().environmentObject(RootViewModel()) }
