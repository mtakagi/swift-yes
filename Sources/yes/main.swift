import Darwin

let yes = CommandLine.argc > 1 ? CommandLine.arguments[1] : "y"
let cstring = yes.utf8CString

while true {
    write(STDOUT_FILENO, yes, cstring.count)
    write(STDOUT_FILENO, [0x0a], 1)
}

