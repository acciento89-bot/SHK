import SwiftUI

struct HeizBalanceView: View {
    var body: some View {
        NavigationStack {
            HeizBalanceProjectListView()
        }
    }
}

#Preview {
    HeizBalanceView()
        .environment(HeizBalanceProjectStore())
        .preferredColorScheme(.dark)
}
