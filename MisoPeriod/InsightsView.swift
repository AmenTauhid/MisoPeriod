//
//  StatsCard.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let emoji: String
    let color: Color
    
    var body: some View {
        KawaiiCard(backgroundColor: color.opacity(0.2)) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title)
                
                Text(title)
                    .font(KawaiiTheme.captionFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(KawaiiTheme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    StatsCard(title: "Average Cycle", value: "28 days", emoji: KawaiiEmojis.calendar, color: KawaiiTheme.primaryPink)
}
