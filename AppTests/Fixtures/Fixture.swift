import XCTest
@testable import AAPSClientiOS

func loadFixture(_ name: String) throws -> Data {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("\(name).v3.json")
    return try Data(contentsOf: url)
}
