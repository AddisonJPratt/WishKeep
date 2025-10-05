import Foundation
import CoreGraphics

enum AppConstants {
    static let bgRefreshId = "com.wishkeep.refresh"
    static let thumbnailWidth: CGFloat = 300
    static let statusBarIgnorePercent: CGFloat = 0.06
    static let scanNegativeBufferSeconds: TimeInterval = 300 // 5 min
    static let groupingWindowSeconds: TimeInterval = 90

    enum UserDefaultsKeys {
        static let lastIndexedAt = "lastIndexedAt"
    }
}


