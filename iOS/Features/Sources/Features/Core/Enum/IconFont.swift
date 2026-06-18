//
//  IconFont.swift
//  Features
//
//  Created by Yen Lin on 2026/6/18.
//

import SwiftUI

/// Semantic sizes for SF Symbol icons. Unlike body text, SF Symbols must be styled with
/// `.system(size:weight:)` so the symbol weight axis renders correctly — `PlusJakartaSans`
/// does not provide symbol glyphs.
///
/// Use `iconFont(_:)` on an `Image(systemName:)` (or any view that renders SF Symbols)
/// rather than calling `.font(.system(...))` directly. This keeps all icon sizing centralized
/// and aligned with the design system.
public enum IconFont {
    // Standard scale
    case xs           // 10pt bold     — DEAL ribbon glyph, tiny direction arrows
    case sm           // 12pt semibold — small chevrons, in-line input glyphs
    case md           // 15pt semibold — standard list / settings icons
    case lg           // 17pt semibold — large nav / hero glyphs
    case xl           // 20pt medium   — settings row leading icon
    case xxl          // 22pt semibold — tab bar icons, FAB plus

    // Specialised
    case caption      // 11pt medium   — tiny in-row meta icons
    case quantity     // 16pt semibold — quantity stepper +/-
    case quantityLg   // 18pt semibold — quantity stepper +/- (large)
    case bodyIcon     // 16pt regular  — bell/reminder body-size icons
    case sectionIcon  // 18pt regular  — section header icons (no weight)
    case nav          // 16pt semibold — modal header back chevron
    case fab          // 24pt semibold — floating action button
    case cameraTool   // 28pt regular  — camera tool icons (gallery picker)
    case emptyState   // 48pt regular  — empty / error state large glyph
    case hero         // 52pt regular  — hero illustration (refrigerator, …)
    case heroSolid    // 52pt bold     — hero confirmation glyph (checkmark, …)
    case heroPlain    // 36pt regular  — empty chart placeholder
    case splash       // 60pt regular  — splash logo glyph

    public var font: Font {
        switch self {
        case .xs:           .system(size: 10, weight: .bold)
        case .sm:           .system(size: 12, weight: .semibold)
        case .md:           .system(size: 15, weight: .semibold)
        case .lg:           .system(size: 17, weight: .semibold)
        case .xl:           .system(size: 20, weight: .medium)
        case .xxl:          .system(size: 22, weight: .semibold)
        case .caption:      .system(size: 11, weight: .medium)
        case .quantity:     .system(size: 16, weight: .semibold)
        case .quantityLg:   .system(size: 18, weight: .semibold)
        case .bodyIcon:     .system(size: 16)
        case .sectionIcon:  .system(size: 18)
        case .nav:          .system(size: 16, weight: .semibold)
        case .fab:          .system(size: 24, weight: .semibold)
        case .cameraTool:   .system(size: 28, weight: .regular)
        case .emptyState:   .system(size: 48)
        case .hero:         .system(size: 52, weight: .regular)
        case .heroSolid:    .system(size: 52, weight: .bold)
        case .heroPlain:    .system(size: 36)
        case .splash:       .system(size: 60)
        }
    }
}

// MARK: - View Modifier

public extension View {
    /// Apply a semantic `IconFont` size to an SF Symbol image.
    func iconFont(_ font: IconFont) -> some View {
        self.font(font.font)
    }

    /// Apply a runtime-computed SF Symbol size + weight. Use this only for genuinely
    /// dynamic sizes (e.g. proportional to a parent container); prefer the semantic
    /// `iconFont(_:)` overload everywhere else.
    func iconFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight))
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Image(systemName: "chevron.right").iconFont(.sm)
        Image(systemName: "tag").iconFont(.md)
        Image(systemName: "bag").iconFont(.lg)
        Image(systemName: "bell.fill").iconFont(.xl)
        Image(systemName: "house").iconFont(.xxl)
        Image(systemName: "plus").iconFont(.fab)
        Image(systemName: "refrigerator.fill").iconFont(.hero)
    }
    .padding()
}
