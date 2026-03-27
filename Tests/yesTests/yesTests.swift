import Testing
import Foundation

struct YesTests {
    private var yesBinaryURL: URL {
        let fm = FileManager.default
        
        // 1. Xcode環境変数 (Xcodeから実行する場合)
        if let path = ProcessInfo.processInfo.environment["BUILT_PRODUCTS_DIR"] {
            return URL(fileURLWithPath: path).appendingPathComponent("yes")
        }

        // 2. 全てのBundleからテストターゲットに関連するパスを探す (macOS swift test 用)
        for bundle in Bundle.allBundles {
            let path = bundle.bundlePath
            // テストターゲット名やパッケージ名を含むパスを優先
            if path.contains("yes") && (path.hasSuffix(".xctest") || path.contains(".build")) {
                let candidate = bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("yes")
                if fm.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }
        
        // 3. カレントディレクトリの .build フォルダ内を探索 (CLI実行時のフォールバック)
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let searchPaths = [
            ".build/debug/yes",
            ".build/release/yes",
            ".build/apple/Products/Debug/yes",
            ".build/apple/Products/Release/yes",
            "yes" // カレントディレクトリ直下
        ]
        
        for p in searchPaths {
            let candidate = cwd.appendingPathComponent(p)
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        // 最終手段としてエラーログに残った toolchain パスを避けるためのダミー
        return cwd.appendingPathComponent("yes")
    }

    @Test("出力内容が引数と一致することを確認")
    func testOutputContent() throws {
        let process = Process()
        process.executableURL = yesBinaryURL
        process.arguments = ["hello"]

        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        
        // 最初の1行分を読み取る ("hello\n")
        let data = pipe.fileHandleForReading.readData(ofLength: 6)
        process.terminate()
        
        let output = String(data: data, encoding: .utf8)
        #expect(output == "hello\n")
    }

    @Test("パイプが閉じたときに exit(0) で終了することを確認")
    func testBrokenPipeTermination() async throws {
        let process = Process()
        process.executableURL = yesBinaryURL
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        
        // 読み取り側を即座に閉じることで EPIPE/SIGPIPE を誘発
        try pipe.fileHandleForReading.close()
        
        // プロセスの終了を待機
        process.waitUntilExit()
        
        // EPIPE 時に exit(0) する実装になっているか確認
        #expect(process.terminationStatus == 0)
    }
}