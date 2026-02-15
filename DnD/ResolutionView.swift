import SwiftUI

struct ResolutionView: View {
    let roll: DiceResult
    let dc: Int
    let hpChange: Int
    let outcome: Bool
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            FantasyPanel {
                VStack(spacing: 20) {
                    Text("ACTION RESOLUTION")
                        .font(.fantasyCaption)
                        .foregroundColor(outcome ? .accentNeon : .accentDanger)
                        .tracking(2)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(roll.total)")
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundColor(outcome ? .accentNeon : .accentDanger)
                        
                        Text("vs DC \(dc)")
                            .font(.fantasyBody)
                            .foregroundColor(.textMuted)
                    }
                    
                    Text("d20: \(roll.roll) + modifier: \(roll.bonus)")
                        .font(.fantasyCaption)
                        .foregroundColor(.textSecondary)
                    
                    Divider()
                        .background(Color.accentDanger)
                    
                    Text(outcome ? "Success " : "Failure ")
                        .font(.fantasyTitle)
                        .foregroundColor(outcome ? .accentNeon : .accentDanger)
                        .tracking(4)
                    
                    if hpChange != 0 {
                        HStack {
                            Image(systemName: hpChange > 0 ? "heart.fill" : "heart.slash.fill")
                            Text(hpChange > 0 ? "+\(hpChange) HP" : "\(hpChange) HP")
                        }
                        .font(.fantasyBodyBold)
                        .foregroundColor(hpChange > 0 ? .accentNeon : .accentDanger)
                    } else {
                        Text("No change in HP")
                            .font(.fantasyCaption)
                            .foregroundColor(.textMuted)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            
            FantasyPrimaryButton(title: "CONTINUE") {
                onContinue()
            }
            .padding(.horizontal, 16)
        }
    }
}
