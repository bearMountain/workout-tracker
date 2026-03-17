import SwiftUI

struct SyncStatusIndicator: View {
    @Environment(SyncEngine.self) private var syncEngine: SyncEngine?
    
    var body: some View {
        if let syncEngine {
            Menu {
                Text(syncEngine.isOnline ? "Online" : "Offline")
                Text("\(syncEngine.pendingChangesCount) pending changes")
                if let lastSyncDate = syncEngine.lastSuccessfulSyncDate {
                    Text("Last sync: \(lastSyncDate.formatted(date: .abbreviated, time: .shortened))")
                } else {
                    Text("Last sync: Never")
                }
                if let message = syncEngine.persistentBannerMessage ?? syncEngine.syncError {
                    Text(message)
                }
            } label: {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
            }
        }
    }
    
    private var iconName: String {
        guard let syncEngine else { return "icloud.slash" }
        switch syncEngine.indicatorState {
        case .synced:
            return "icloud.fill"
        case .pending:
            return syncEngine.isOnline ? "icloud" : "icloud.slash"
        case .error:
            return "icloud.slash.fill"
        }
    }
    
    private var iconColor: Color {
        guard let syncEngine else { return AppTheme.textMuted }
        switch syncEngine.indicatorState {
        case .synced:
            return AppTheme.success
        case .pending:
            return AppTheme.textMuted
        case .error:
            return AppTheme.warning
        }
    }
}

struct SyncStatusBanner: View {
    @Environment(SyncEngine.self) private var syncEngine: SyncEngine?
    
    var body: some View {
        if let message = syncEngine?.persistentBannerMessage {
            HStack(spacing: 8) {
                Image(systemName: "icloud.slash")
                Text(message)
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.warning)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.warning.opacity(0.35), lineWidth: 1)
            )
            .padding(.top, 8)
        }
    }
}
