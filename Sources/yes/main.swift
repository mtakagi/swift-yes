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

#if !os(Windows)
signal(SIGPIPE, SIG_IGN)
#endif

let arguments = CommandLine.arguments.dropFirst()
let yes = arguments.isEmpty ? "y" : arguments.joined(separator: " ")
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
        var writtenBytes = 0
        while writtenBytes < size {
            let bytesToWrite = size - writtenBytes
            let currentPtr = base.advanced(by: writtenBytes)
            #if os(Windows)
            let result = write(STDOUT_FILENO, currentPtr, UInt32(bytesToWrite))
            if result < 0 {
                if _errno().pointee == EINTR { continue }
                if _errno().pointee == EPIPE { exit(0) }
                perror("write")
                exit(1)
            }
            #else
            let result = write(STDOUT_FILENO, currentPtr, bytesToWrite)
            if result < 0 {
                if errno == EINTR { continue }
                if errno == EPIPE { exit(0) }
                perror("write")
                exit(1)
            }
            #endif
            if result == 0 {
                exit(0)
            }
            writtenBytes += Int(result)
        }
    }
}
