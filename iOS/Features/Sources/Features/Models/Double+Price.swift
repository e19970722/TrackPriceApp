import Foundation

extension Double {
    func priceFormatted(symbol: String, decimals: Int = 2) -> String {
        "\(symbol)\(String(format: "%.\(decimals)f", self))"
    }
}
