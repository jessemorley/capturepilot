import XCTest
@testable import CapturePilotMac

class GalleryViewModelTests: XCTestCase {

    var viewModel: GalleryViewModel!
    var client: CapturePilotClient!
    var imageCache: ImageCacheService!

    override func setUp() {
        super.setUp()
        client = CapturePilotClient()
        imageCache = ImageCacheService()
        viewModel = GalleryViewModel(client: client, imageCache: imageCache)
    }

    override func tearDown() {
        viewModel = nil
        client = nil
        imageCache = nil
        super.tearDown()
    }

    func testSingleSelection() {
        let variant1 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "1", originalImageID: "1")
        let variant2 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "2", originalImageID: "2")

        viewModel.selectVariant(variant1, isCommandPressed: false)
        XCTAssertEqual(viewModel.selectedVariantIDs, [variant1.id])
        XCTAssertEqual(viewModel.activeVariantID, variant1.id)

        viewModel.selectVariant(variant2, isCommandPressed: false)
        XCTAssertEqual(viewModel.selectedVariantIDs, [variant2.id])
        XCTAssertEqual(viewModel.activeVariantID, variant2.id)
    }

    func testMultiSelection() {
        let variant1 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "1", originalImageID: "1")
        let variant2 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "2", originalImageID: "2")
        let variant3 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "3", originalImageID: "3")

        viewModel.selectVariant(variant1, isCommandPressed: false)
        viewModel.selectVariant(variant2, isCommandPressed: true)
        viewModel.selectVariant(variant3, isCommandPressed: true)

        XCTAssertEqual(viewModel.selectedVariantIDs, [variant1.id, variant2.id, variant3.id])
        XCTAssertEqual(viewModel.activeVariantID, variant3.id)
    }

    func testDeselection() {
        let variant1 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "1", originalImageID: "1")
        let variant2 = Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "2", originalImageID: "2")

        viewModel.selectVariant(variant1, isCommandPressed: false)
        viewModel.selectVariant(variant2, isCommandPressed: true)
        viewModel.selectVariant(variant1, isCommandPressed: true)

        XCTAssertEqual(viewModel.selectedVariantIDs, [variant2.id])
        XCTAssertEqual(viewModel.activeVariantID, variant1.id)
    }
}