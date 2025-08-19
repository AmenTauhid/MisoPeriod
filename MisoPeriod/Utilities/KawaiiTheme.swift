//
//  KawaiiTheme.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI

struct KawaiiTheme {
    // Kawaii Color Palette
    static let primaryPink = Color(red: 1.0, green: 0.7, blue: 0.8)
    static let softPink = Color(red: 1.0, green: 0.85, blue: 0.9)
    static let lightPink = Color(red: 1.0, green: 0.94, blue: 0.96)
    static let deepPink = Color(red: 0.9, green: 0.4, blue: 0.6)
    
    static let lavender = Color(red: 0.85, green: 0.8, blue: 1.0)
    static let lightLavender = Color(red: 0.95, green: 0.93, blue: 1.0)
    
    static let peach = Color(red: 1.0, green: 0.8, blue: 0.7)
    static let lightPeach = Color(red: 1.0, green: 0.9, blue: 0.85)
    
    static let mintGreen = Color(red: 0.4, green: 0.7, blue: 0.55)
    static let lightMint = Color(red: 0.85, green: 1.0, blue: 0.92)
    
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let softGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // Gradient backgrounds
    static let pinkGradient = LinearGradient(
        colors: [lightPink, softPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let lavenderGradient = LinearGradient(
        colors: [lightLavender, lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let peachGradient = LinearGradient(
        colors: [lightPeach, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Typography - Updated for better readability
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .medium, design: .default)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .default)
    
    // Additional font sizes for better hierarchy
    static let largeBodyFont = Font.system(size: 18, weight: .medium, design: .default)
    static let smallBodyFont = Font.system(size: 15, weight: .regular, design: .default)
    
    // Corner radius
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 8
}

// Custom Button Styles
struct KawaiiButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(backgroundColor: Color = KawaiiTheme.primaryPink, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KawaiiTheme.bodyFont)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(color: backgroundColor.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// Custom Card View
struct KawaiiCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    
    init(backgroundColor: Color = KawaiiTheme.cream, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.cardCornerRadius))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Emoji helpers for kawaii feel
struct KawaiiEmojis {
    static let period = "🩸"
    static let calendar = "📅"
    static let flower = "🌸"
    static let heart = "💕"
    static let sparkles = "✨"
    static let moon = "🌙"
    static let sun = "☀️"
    static let rainbow = "🌈"
    static let butterfly = "🦋"
    static let cherry = "🍒"
    
    // Mood emojis
    static let happy = "😊"
    static let sad = "😢"
    static let neutral = "😐"
    static let tired = "😴"
    static let energetic = "⚡"
    static let anxious = "😰"
    
    // Symptom emojis
    static let cramps = "🤕"
    static let bloating = "🎈"
    static let headache = "🤯"
    static let backache = "🏋️‍♀️"
    static let tender = "🤗"
}
