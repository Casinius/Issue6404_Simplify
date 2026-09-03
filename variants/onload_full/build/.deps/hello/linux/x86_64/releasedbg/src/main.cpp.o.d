{
    depfiles = "main.o: src/main.cpp\
",
    files = {
        "src/main.cpp"
    },
    values = {
        "/usr/bin/g++",
        {
            "-funroll-loops",
            "-DFOO6404",
            "-DBAR6404",
            "-ffunction-sections",
            "-DRVISA_X86",
            "-DRVISA_64"
        }
    },
    depfiles_format = "gcc"
}