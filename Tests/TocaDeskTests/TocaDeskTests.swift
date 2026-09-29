import XCTest
@testable import TocaDesk

final class TocaDeskTests: XCTestCase {
    func testEveryMutableToolUsesDryRun() {
        for tool in Tool.allCases where tool.mutable {
            XCTAssertEqual(tool.arguments(preview: true), [tool.rawValue, "--dry-run"])
            XCTAssertEqual(tool.arguments(preview: false), [tool.rawValue])
            XCTAssertFalse(tool.arguments(preview: false).contains("--yes"))
        }
        XCTAssertEqual(Tool.status.arguments(preview: true), ["status"])
    }
    func testMissingExecutable() { XCTAssertNotEqual(MoleClient.locate(custom: "/does/not/exist"), "/does/not/exist") }
    func testDecodeStatusWithoutOptionalFields() throws {
        let json = #"{"host":"Mac","uptime":"1d","cpu":{"usage":12.5},"memory":{"used":1024,"total":4096,"used_percent":25},"disks":[]}"#
        let result = try JSONDecoder().decode(Snapshot.self, from: Data(json.utf8))
        XCTAssertEqual(result.cpu.usage, 12.5)
        XCTAssertNil(result.health_score)
    }
    func testPartialScanRetainsUnknownSizeStatus() throws {
        let json = #"{"path":"/tmp","total_size":0,"scan_status":"partial","entries":[{"name":"Private","path":"/tmp/Private","size":0,"is_dir":true,"scan_status":"unavailable"}]}"#
        let result = try JSONDecoder().decode(DiskReport.self, from: Data(json.utf8))
        XCTAssertEqual(result.entries.first?.scan_status, "unavailable")
        XCTAssertEqual(result.scan_status, "partial")
    }
    func testQueryHandlesOutputAndFailures() async throws {
        let data = try await MoleClient.query(executable: "/usr/bin/printf", arguments: ["%s", "folder with spaces; $(echo test)"])
        XCTAssertEqual(String(data: data, encoding: .utf8), "folder with spaces; $(echo test)")
        do {
            _ = try await MoleClient.query(executable: "/usr/bin/false", arguments: [])
            XCTFail("Expected failure")
        } catch { XCTAssertTrue(error.localizedDescription.contains("código 1")) }
    }
    func testQueryTimeout() async {
        do {
            _ = try await MoleClient.query(executable: "/bin/sleep", arguments: ["10"], timeout: 0.1)
            XCTFail("Expected timeout")
        } catch { XCTAssertTrue(error.localizedDescription.contains("demorou")) }
    }
}
