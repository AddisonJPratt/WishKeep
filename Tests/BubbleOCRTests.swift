import XCTest
@testable import WishKeep_V2
import UIKit

final class BubbleOCRTests: XCTestCase {
    func testAcceptanceScreenshotHasFiveBubblesInOrder() async throws {
        guard let img = loadAcceptanceImage() else {
            throw XCTSkip("Acceptance screenshot not available in test bundle")
        }

        let detector = BubbleRegionDetector()
        let regions = try await detector.regions(in: img)
        XCTAssertFalse(regions.isEmpty, "No regions detected")

        let bubbles = try await BubbleOCR.recognize(in: img, regions: regions)
        XCTAssertEqual(bubbles.count, 5, "Expected exactly 5 bubbles")

        // Validate side order: ME, THEM, ME, ME, ME per spec
        let sides = bubbles.map { $0.sender }
        XCTAssertEqual(sides.count, 5)
        XCTAssertEqual(sides[0], .me)
        XCTAssertEqual(sides[1], .them)
        XCTAssertEqual(sides[2], .me)
        XCTAssertEqual(sides[3], .me)
        XCTAssertEqual(sides[4], .me)
    }

    private func loadAcceptanceImage() -> UIImage? {
        // Place the exact acceptance screenshot in the test bundle with name "acceptance.png"
        let bundle = Bundle(for: Self.self)
        if let url = bundle.url(forResource: "acceptance", withExtension: "png"), let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}


