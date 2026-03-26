#if os(macOS) || os(iOS)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
let STDOUT_FILENO: Int32 = 1
#else
#error("Unknown platform")
#endif

let yes = CommandLine.argc > 1 ? CommandLine.arguments[1] : "y"
let line = yes + "\n"

let bufferSize = 64 * 1024
var buffer = [UInt8](repeating: 0, count: bufferSize)

let bytes = Array(line.utf8)
var size = bytes.count

buffer[0..<size] = bytes[0..<size]

while size < bufferSize / 2 {
    buffer[size..<size*2] = buffer[0..<size]
    size *= 2
}

buffer.withUnsafeBytes { ptr in
    let base = ptr.baseAddress!
    while true {
        #if os(Windows)
        let written = write(STDOUT_FILENO, base, UInt32(size))
        #else
        let written = write(STDOUT_FILENO, base, size)
        #endif
        if written <= 0 {
            break
        }
    }
}
