-- V4: 对照组 —— 同样的探测/flags 全部挪到 on_check（waruqi 建议的官方姿势）
-- kind=cross 使 on_check 生效；on_load 留空避免 builtin cross loader 干扰 toolset
-- 预期：两次 build 都有 -DFOO6404（问题绕过）
set_project("issue6404-v4-oncheck")

toolchain("fake-check")
    set_kind("cross")
    set_toolset("cc", "gcc")
    set_toolset("cxx", "g++")
    set_toolset("cpp", "g++")
    set_toolset("as", "g++")
    set_toolset("ld", "g++")
    set_toolset("sh", "g++")
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")

    on_load(function (toolchain)
        -- 保持无副作用
    end)

    on_check(function (toolchain)
        local compiler_path = string.trim(path.directory(os.iorun("which g++"))) .. "/../"
        local version_output = os.iorun("g++ --version")
        local version = version_output:match("%) (%d+%.%d+%.%d+)") or "unknown"
        local dirs = os.dirs(compiler_path .. "lib/gcc/*") or {}

        toolchain:add("cxflags", "-DFOO6404")
        toolchain:add("cxflags", "-DBAR6404")
        toolchain:add("ldflags", "-L" .. compiler_path .. "lib")
    end)

target("hello")
    set_kind("binary")
    set_toolchains("fake-check")
    add_files("src/main.cpp")

