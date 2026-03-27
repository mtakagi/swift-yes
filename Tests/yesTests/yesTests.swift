import Testing
import Foundation

struct YesTests {
    private var yesBinaryURL: URL {
        let fm = FileManager.default
        let executableName = {
            #if os(Windows)
            return "yes.exe"
            #else
            return "yes"
            #endif
        }()

        // 1. カレントディレクトリ直下を確認
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let directPath = cwd.appendingPathComponent(executableName)
        if fm.fileExists(atPath: directPath.path) { return directPath }

        // 2. 標準的な .build ディレクトリ内を探索 (再帰を避け、既知のパスを優先)
        let searchSubPaths = [
            ".build/debug",
            ".build/release",
            ".build/x86_64-unknown-linux-gnu/debug",
            ".build/x86_64-unknown-linux-gnu/release",
            ".build/arm64-apple-macosx/debug",
            ".build/arm64-apple-macosx/release"
        ]

        for subPath in searchSubPaths {
            let candidate = cwd.appendingPathComponent(subPath).appendingPathComponent(executableName)
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        // 3. 最終手段：環境変数から推測（CI用）
        return directPath
    }

    @Test("出力内容が一致することを確認")
    func testOutput() throws {
        let process = Process()
        process.executableURL = yesBinaryURL
        process.arguments = ["test"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        
        let data = pipe.fileHandleForReading.readData(ofLength: 5) // "test\n"
        process.terminate()
        
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
         #expect(output == "test")
    }

    @Test("パイプ切断で正常終了することを確認")
    func testEPIPE() async throws {
        let process = Process()
        process.executableURL = yesBinaryURL
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        
        try pipe.fileHandleForReading.close()
        process.waitUntilExit()
        
        #expect(process.terminationStatus == 0)
    }
}