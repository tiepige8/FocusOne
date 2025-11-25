import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: Int
    let name: String
    let accentColor: Color
    let secondaryColor: Color
    
    static let presets: [AppTheme] = [
        AppTheme(id: 0, name: "专注蓝", accentColor: .blue, secondaryColor: .blue.opacity(0.1)),
        AppTheme(id: 1, name: "抹茶绿", accentColor: Color(red: 0.4, green: 0.7, blue: 0.4), secondaryColor: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.1)),
        AppTheme(id: 2, name: "樱花粉", accentColor: Color(red: 0.9, green: 0.5, blue: 0.6), secondaryColor: Color(red: 0.9, green: 0.5, blue: 0.6).opacity(0.1)),
        AppTheme(id: 3, name: "高级灰", accentColor: .primary, secondaryColor: .gray.opacity(0.1))
    ]
}
