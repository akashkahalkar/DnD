import SwiftUI
import Combine

@available(iOS 26.0, *)
struct CampaignsView: View {
    @StateObject private var viewModel = CampaignsViewModel()

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Campaign Timeline")
                        .font(.fantasyTitleLarge)
                        .foregroundColor(.accentGold)
                        .padding(.top, 50)

                    if viewModel.campaigns.isEmpty {
                        FantasyPanel {
                            Text("Start an adventure to unlock campaign progress.")
                                .font(.fantasyBody)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        Picker("Campaign", selection: $viewModel.selectedCampaignIndex) {
                            ForEach(viewModel.campaigns, id: \.campaignIndex) { campaign in
                                Text("C\(campaign.campaignIndex): \(campaign.seedTitle)")
                                    .tag(campaign.campaignIndex)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        if let campaign = viewModel.selectedCampaign {
                            FantasyPanel {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(campaign.seedTitle)
                                            .font(.fantasyBodyBold)
                                            .foregroundColor(campaign.isUnlocked ? .textPrimary : .textMuted)
                                        Spacer()
                                        Text(campaign.isCompleted ? "COMPLETED" : (campaign.isUnlocked ? "ACTIVE" : "LOCKED"))
                                            .font(.fantasyCaption)
                                            .foregroundColor(campaign.isCompleted ? .accentNeon : .textSecondary)
                                    }

                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                        ForEach(campaign.quests, id: \.questIndex) { quest in
                                            QuestCellView(quest: quest, campaignUnlocked: campaign.isUnlocked)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
    }
}

private struct QuestCellView: View {
    let quest: QuestProgress
    let campaignUnlocked: Bool

    var body: some View {
        let isLocked = quest.status == .locked || !campaignUnlocked
        VStack(spacing: 8) {
            Image(systemName: iconName(isLocked: isLocked))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(iconColor(isLocked: isLocked))

            Text("Q\(quest.questIndex)")
                .font(.fantasyCaption)
                .foregroundColor(.textSecondary)

            Text(statusLabel(isLocked: isLocked))
                .font(.fantasyCaption)
                .foregroundColor(statusColor(isLocked: isLocked))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor(isLocked: isLocked), lineWidth: 1)
        )
    }

    private func iconName(isLocked: Bool) -> String {
        if isLocked { return "lock.fill" }
        switch quest.status {
        case .inProgress:
            return "hourglass"
        case .success:
            return "checkmark.seal.fill"
        case .failed:
            return "xmark.seal.fill"
        case .available:
            return "sparkles"
        case .locked:
            return "lock.fill"
        }
    }

    private func iconColor(isLocked: Bool) -> Color {
        if isLocked { return .textMuted }
        switch quest.status {
        case .success:
            return .accentNeon
        case .failed:
            return .accentDanger
        case .inProgress:
            return .accentGold
        default:
            return .accentMagic
        }
    }

    private func statusLabel(isLocked: Bool) -> String {
        if isLocked { return "Locked" }
        switch quest.status {
        case .available:
            return "Available"
        case .inProgress:
            return "In Progress"
        case .success:
            return "Success"
        case .failed:
            return "Failed"
        case .locked:
            return "Locked"
        }
    }

    private func statusColor(isLocked: Bool) -> Color {
        if isLocked { return .textMuted }
        switch quest.status {
        case .success:
            return .accentNeon
        case .failed:
            return .accentDanger
        case .inProgress:
            return .accentGold
        default:
            return .textSecondary
        }
    }

    private func borderColor(isLocked: Bool) -> Color {
        if isLocked { return Color.textMuted.opacity(0.3) }
        switch quest.status {
        case .inProgress:
            return Color.accentGold.opacity(0.6)
        case .success:
            return Color.accentNeon.opacity(0.6)
        case .failed:
            return Color.accentDanger.opacity(0.6)
        default:
            return Color.white.opacity(0.2)
        }
    }
}

@available(iOS 26.0, *)
@MainActor
final class CampaignsViewModel: ObservableObject {
    @Published var campaigns: [CampaignProgress] = []
    @Published var selectedCampaignIndex: Int = 1

    private let dataService = DataService.shared
    private let campaignService = CampaignService.shared

    var selectedCampaign: CampaignProgress? {
        campaigns.first(where: { $0.campaignIndex == selectedCampaignIndex })
    }

    func refresh() async {
        guard let gameData = dataService.fetchLatestGame() else {
            campaigns = []
            return
        }

        await campaignService.ensureCampaignData(for: gameData)
        campaigns = campaignService.campaigns(for: gameData)

        if campaigns.contains(where: { $0.campaignIndex == selectedCampaignIndex }) == false {
            selectedCampaignIndex = campaigns.first?.campaignIndex ?? 1
        }
    }
}
