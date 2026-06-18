import SwiftUI

/// Data model for a `PriceCard` row.
public struct PriceCardItem {
    public let name: String
    public let store: String
    public let currentPrice: Decimal
    public let targetPrice: Decimal
    public let isDeal: Bool
    public let thumbnailLabel: String
    public let paletteIndex: Int // 0–4

    public init(
        name: String,
        store: String,
        currentPrice: Decimal,
        targetPrice: Decimal,
        isDeal: Bool = false,
        thumbnailLabel: String,
        paletteIndex: Int = 0
    ) {
        self.name = name
        self.store = store
        self.currentPrice = currentPrice
        self.targetPrice = targetPrice
        self.isDeal = isDeal
        self.thumbnailLabel = thumbnailLabel
        self.paletteIndex = paletteIndex
    }
}

/// Full price-tracker row component wrapping product info, current price, and target.
public struct PriceCard: View {
    let item: PriceCardItem

    public init(item: PriceCardItem) {
        self.item = item
    }

    // MARK: - Body

    public var body: some View {
        cardWrapperView
    }
}

// MARK: - Subviews

extension PriceCard {
    private var cardWrapperView: some View {
        RipeCard(padding: RipeSpacing.s4) {
            ZStack(alignment: .topLeading) {
                rowContentView
                if item.isDeal {
                    DealRibbon()
                }
            }
            .clipped()
        }
    }

    private var rowContentView: some View {
        HStack(spacing: RipeSpacing.s3) {
            thumbnailView
            productInfoStack
            Spacer()
            priceStack
        }
    }

    private var thumbnailView: some View {
        MonoThumbnail(
            label: item.thumbnailLabel,
            categoryColor: paletteColor,
            showStripeTexture: true
        )
    }

    private var productInfoStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            productNameText
            productStoreText
        }
    }

    private var productNameText: some View {
        Text(item.name)
            .font(CustomFont.heading(15.5))
            .foregroundStyle(Color(.ripeInk))
            .lineLimit(1)
    }

    private var productStoreText: some View {
        Text(item.store)
            .font(CustomFont.caption(12))
            .foregroundStyle(Color(.ripeInk2))
    }

    private var priceStack: some View {
        VStack(alignment: .trailing, spacing: 2) {
            currentPriceText
            targetPriceText
        }
    }

    private var currentPriceText: some View {
        Text(item.currentPrice, format: .currency(code: "USD"))
            .font(CustomFont.num(20))
            .foregroundStyle(priceColor)
    }

    private var targetPriceText: some View {
        Text("Target: \(item.targetPrice, format: .currency(code: "USD"))")
            .font(CustomFont.caption(12))
            .foregroundStyle(Color(.ripeInk3))
    }
}

// MARK: - Helpers

extension PriceCard {
    private var priceColor: Color {
        item.currentPrice <= item.targetPrice ? Color(.ripeGood) : Color(.ripeDanger)
    }

    private var paletteColor: Color {
        let colors: [Color] = [
            Color(.ripeCat1),
            Color(.ripeCat2),
            Color(.ripeCat3),
            Color(.ripeCat4),
            Color(.ripeCat5),
        ]
        let index = max(0, min(4, item.paletteIndex))
        return colors[index]
    }
}

// MARK: - Preview

#Preview("PriceCard") {
    VStack(spacing: RipeSpacing.s3) {
        PriceCard(item: PriceCardItem(
            name: "Nike Air Max 90",
            store: "Nike.com",
            currentPrice: 89.99,
            targetPrice: 100.00,
            isDeal: true,
            thumbnailLabel: "N",
            paletteIndex: 0
        ))
        PriceCard(item: PriceCardItem(
            name: "Sony WH-1000XM5",
            store: "Amazon",
            currentPrice: 349.99,
            targetPrice: 299.00,
            thumbnailLabel: "S",
            paletteIndex: 1
        ))
        PriceCard(item: PriceCardItem(
            name: "Apple AirPods Pro",
            store: "Apple Store",
            currentPrice: 199.00,
            targetPrice: 219.00,
            isDeal: false,
            thumbnailLabel: "A",
            paletteIndex: 2
        ))
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("PriceCard Dark") {
    VStack(spacing: RipeSpacing.s3) {
        PriceCard(item: PriceCardItem(
            name: "LEGO Technic Set",
            store: "LEGO Shop",
            currentPrice: 79.99,
            targetPrice: 89.00,
            isDeal: true,
            thumbnailLabel: "L",
            paletteIndex: 3
        ))
        PriceCard(item: PriceCardItem(
            name: "Instant Pot Duo",
            store: "Target",
            currentPrice: 119.99,
            targetPrice: 99.00,
            thumbnailLabel: "I",
            paletteIndex: 4
        ))
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
