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

line.withCString {
    #if os(Windows)
    let len = UInt32(line.utf8.count)
    #else
    let len = line.utf8.count
    #endif
    while true {
        write(STDOUT_FILENO, $0, len)
    }
}

