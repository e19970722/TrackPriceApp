import SwiftUI

#if DEBUG
    #Preview("Ripe Tokens — Light") {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s4) {
                // Font preview
                Group {
                    Text("Display 30 — ExtraBold").customFont(.extrabold30)
                    Text("Title 26 — ExtraBold").customFont(.extrabold26)
                    Text("Heading 19 — Bold").customFont(.bold19)
                    Text("Body 15 — SemiBold").customFont(.semibold15)
                    Text("Label 13 — SemiBold").customFont(.semibold13)
                    Text("Caption 12 — Medium").customFont(.medium12)
                    Text("Num $12.99 — Bold").customFont(.bold17).monospacedDigit()
                }

                Divider()

                // Color swatches
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach([
                        ("Bg", Color(.ripeBg)), ("Surface", Color(.ripeSurface)), ("Surface2", Color(.ripeSurface2)),
                        ("Ink", Color(.ripeInk)), ("Ink2", Color(.ripeInk2)), ("Ink3", Color(.ripeInk3)),
                        ("Accent", Color(.ripeAccent)), ("Good", Color(.ripeGood)), ("Warn", Color(.ripeWarn)),
                        ("Danger", Color(.ripeDanger)), ("Cat1", Color(.ripeCat1)), ("Cat2", Color(.ripeCat2)),
                    ], id: \.0) { name, color in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: RipeRadius.xs)
                                .fill(color)
                                .frame(height: 36)
                                .overlay(RoundedRectangle(cornerRadius: RipeRadius.xs)
                                    .stroke(Color(.ripeInk).opacity(0.08)))
                            Text(name).customFont(.medium10).foregroundStyle(Color(.ripeInk2))
                        }
                    }
                }
            }
            .padding(RipeSpacing.s5)
        }
        .background(Color(.ripeBg))
    }
#endif
