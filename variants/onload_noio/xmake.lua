-- V3: V1 去掉所有 IO 探测（os.iorun / os.dirs），其余结构保留
-- 目的：隔离 "on_load 里做 IO" 这个因素
set_project("issue6404-v3-onload-noio")

isa_arch_list = {}

function has_isa(arch)
    return table.contains(isa_arch_list, arch)
end

toolchain("fake-rv-noio")
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

        local ext_list = arch_string:split("_")
        for _, ext in ipairs(ext_list) do
            add_defines("RVISA_" .. ext:upper())
        end

        add_cxflags('-DFOO6404')
        add_cxflags('-DBAR6404')
        add_cxflags("-ffunction-sections", "-fdata-sections")

        isa_arch_list = arch_string:split("_")

        -- 无任何 os.iorun / os.dirs
        add_ldflags('-L/usr/lib')
    end)

target("hello")
    set_kind("binary")
    set_toolchains("fake-rv-noio")
    add_files("src/main.cpp")

