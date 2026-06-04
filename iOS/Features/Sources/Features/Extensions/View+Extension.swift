//
//  View+Extension.swift
//  Features
//
//  Created by Yen Lin on 2026/6/4.
//

import SwiftUI

extension View {
    func customFont(_ customFont: CustomFont) -> some View {
        font(customFont.font)
    }
}
