-- V2: 极简版 —— on_load 里只有一次 toolchain:add("cxflags", ...)
set_project("issue6404-v2-onload-min")

toolchain("fake-min")
    set_kind("standalone")
    set_toolset("cc", "gcc")
    set_toolset("cxx", "g++")
    set_toolset("cpp", "g++")
    set_toolset("as", "g++")
    set_toolset("ld", "g++")
    set_toolset("sh", "g++")
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")

    on_load(function (toolchain)
        toolchain:add("cxflags", "-DFOO6404")
    end)

target("hello")
    set_kind("binary")
    set_toolchains("fake-min")
    add_files("src/main.cpp")

