-- V1: 原始 toolchain.lua (simple-riscv-software-env @ a3ae042) 的忠实缩小版
-- 结构镜像: defines 循环 + 单字符串 cxflags add + 全局 isa 表赋值 + os.iorun 探测 + 目录扫描 + ldflags
set_project("issue6404-v1-onload-full")

isa_arch_list = {}

function has_isa(arch)
    return table.contains(isa_arch_list, arch)
end

toolchain("fake-rv-toolchain")
    set_kind("standalone")
    set_toolset("cc", "gcc")
    set_toolset("cxx", "g++")
    set_toolset("cpp", "g++")
    set_toolset("as", "g++")
    set_toolset("ld", "g++")
    set_toolset("sh", "g++")
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")

    -- 静态 flags（镜像原始的 -funroll-loops），对照组：预期两次 build 都在
    if is_mode("release") or is_mode("releasedbg") then
        add_cxflags("-funroll-loops")
    end

    on_load(function (toolchain)
        import("core.project.config")

        local arch_string = config.get("arch")

        local function add_cxflags(flags)
            toolchain:add('cxflags', flags)
        end

        local function add_ldflags(flags)
            toolchain:add('ldflags', flags)
        end

        local function add_defines(flags)
            toolchain:add('defines', flags)
        end

        -- (a) defines 循环（镜像原始 RVISA_* 循环）
        local ext_list = arch_string:split("_")
        for _, ext in ipairs(ext_list) do
            add_defines("RVISA_" .. ext:upper())
        end

        -- (b) 动态 cxflags（镜像 -march=.. / -mabi=..，单字符串逐个 add）
        add_cxflags('-DFOO6404')
        add_cxflags('-DBAR6404')
        add_cxflags("-ffunction-sections", "-fdata-sections")

        -- (c) 全局表赋值（镜像 isa_arch_list = parse_arch_string(...)）
        isa_arch_list = arch_string:split("_")

        -- (d) IO 探测（镜像 which gcc / gcc --version / multilib 目录扫描）
        local compiler_path = string.trim(path.directory(os.iorun("which g++"))) .. "/../"
        local version_output = os.iorun("g++ --version")
        local version = version_output:match("%) (%d+%.%d+%.%d+)") or "unknown"
        local dirs = os.dirs(compiler_path .. "lib/gcc/*") or {}

        -- (e) ldflags（镜像 -L multilib 路径）
        add_ldflags('-L' .. compiler_path .. "lib")
    end)

target("hello")
    set_kind("binary")
    set_toolchains("fake-rv-toolchain")
    add_files("src/main.cpp")

