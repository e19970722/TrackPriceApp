import SwiftUI

public extension Color {
    // Surfaces
    static let ripeBg          = Color("RipeBg",          bundle: .module)
    static let ripeSurface     = Color("RipeSurface",     bundle: .module)
    static let ripeSurface2    = Color("RipeSurface2",    bundle: .module)
    static let ripeSurfaceTint = Color("RipeSurfaceTint", bundle: .module)

    // Ink
    static let ripeInk         = Color("RipeInk",         bundle: .module)
    static let ripeInk2        = Color("RipeInk2",        bundle: .module)
    static let ripeInk3        = Color("RipeInk3",        bundle: .module)
    static let ripeLine        = Color("RipeLine",        bundle: .module)

    // Brand
    static let ripeAccent      = Color("RipeAccent",      bundle: .module)
    static let ripeAccentSoft  = Color("RipeAccentSoft",  bundle: .module)
    static let ripeAccentInk   = Color("RipeAccentInk",   bundle: .module)

    // Semantic
    static let ripeGood        = Color("RipeGood",        bundle: .module)
    static let ripeGoodSoft    = Color("RipeGoodSoft",    bundle: .module)
    static let ripeWarn        = Color("RipeWarn",        bundle: .module)
    static let ripeWarnSoft    = Color("RipeWarnSoft",    bundle: .module)
    static let ripeDanger      = Color("RipeDanger",      bundle: .module)
    static let ripeDangerSoft  = Color("RipeDangerSoft",  bundle: .module)
    static let ripeBarTrack    = Color("RipeBarTrack",    bundle: .module)

    // Category palette
    static let ripeCat1 = Color("RipeCat1", bundle: .module) // coral   #EC6240
    static let ripeCat2 = Color("RipeCat2", bundle: .module) // sage    #3E9E6E
    static let ripeCat3 = Color("RipeCat3", bundle: .module) // amber   #D88A2A
    static let ripeCat4 = Color("RipeCat4", bundle: .module) // blue    #5B8DEF
    static let ripeCat5 = Color("RipeCat5", bundle: .module) // mauve   #B0729E
}
