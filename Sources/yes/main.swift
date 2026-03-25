#if os(macOS) || os(iOS)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
#else
#error("Unknown platform")
#endif

let yes = CommandLine.argc > 1 ? CommandLine.arguments[1] : "y"
let line = yes + "\n"

line.withCString {
    let len = strlen($0)
    while true {
        write(STDOUT_FILENO, $0, len)
    }
}

