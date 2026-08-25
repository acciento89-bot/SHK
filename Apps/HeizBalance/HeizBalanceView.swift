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
        .environment(HeizBalanceRadiatorDatasetStore())
        .preferredColorScheme(.dark)
}
