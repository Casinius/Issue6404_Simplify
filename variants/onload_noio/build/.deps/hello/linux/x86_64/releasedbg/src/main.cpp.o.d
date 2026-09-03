{
    depfiles_format = "gcc",
    files = {
        "src/main.cpp"
    },
    depfiles = "main.o: src/main.cpp\
",
    values = {
        "/usr/bin/g++",
        {
            "-DFOO6404",
            "-DBAR6404",
            "-ffunction-sections",
            "-DRVISA_X86",
            "-DRVISA_64"
        }
    }
}