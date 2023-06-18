const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tests = b.option(bool, "tests", "Build tests [default: false]") orelse false;
    const boost = boostLibraries(b, target);

    const lib = b.addStaticLibrary(.{
        .name = "context",
        .target = target,
        .optimize = optimize,
    });
    switch (optimize) {
        .ReleaseSafe, .Debug => lib.bundle_compiler_rt = true,
        else => lib.root_module.strip = true,
    }
    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(b.path("src/asm")); // common.h
    for (boost.root_module.include_dirs.items) |include| {
        lib.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    lib.addCSourceFiles(.{
        .files = src,
        .flags = cxxFlags,
    });
    lib.addCSourceFile(.{
        .file = switch (lib.rootModuleTarget().os.tag) {
            .windows => b.path("src/windows/stack_traits.cpp"),
            else => b.path("src/posix/stack_traits.cpp"),
        },
        .flags = cxxFlags,
    });
    if (lib.rootModuleTarget().os.tag == .windows) {
        lib.defineCMacro("BOOST_USE_WINFIB", null);
        lib.want_lto = false;
    } else {
        lib.defineCMacro("BOOST_USE_UCONTEXT", null);
    }
    switch (lib.rootModuleTarget().cpu.arch) {
        .arm => switch (lib.rootModuleTarget().os.tag) {
            .windows => {
                if (lib.rootModuleTarget().abi == .msvc) {
                    lib.addAssemblyFile(b.path("src/asm/jump_arm_aapcs_pe_armasm.asm"));
                    lib.addAssemblyFile(b.path("src/asm/make_arm_aapcs_pe_armasm.asm"));
                    lib.addAssemblyFile(b.path("src/asm/ontop_arm_aapcs_pe_armasm.asm"));
                }
            },
            .macos => {
                lib.addAssemblyFile(b.path("src/asm/jump_arm_aapcs_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_arm_aapcs_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_arm_aapcs_macho_gas.S"));
            },
            else => {
                lib.addAssemblyFile(b.path("src/asm/jump_arm_aapcs_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_arm_aapcs_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_arm_aapcs_elf_gas.S"));
            },
        },
        .aarch64 => switch (lib.rootModuleTarget().os.tag) {
            .windows => {
                if (lib.rootModuleTarget().abi == .msvc) {
                    lib.addAssemblyFile(b.path("src/asm/jump_arm64_aapcs_pe_armasm.asm"));
                    lib.addAssemblyFile(b.path("src/asm/make_arm64_aapcs_pe_armasm.asm"));
                    lib.addAssemblyFile(b.path("src/asm/ontop_arm64_aapcs_pe_armasm.asm"));
                }
            },
            .macos => {
                lib.addAssemblyFile(b.path("src/asm/jump_arm64_aapcs_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_arm64_aapcs_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_arm64_aapcs_macho_gas.S"));
            },
            else => {
                lib.addAssemblyFile(b.path("src/asm/jump_arm64_aapcs_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_arm64_aapcs_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_arm64_aapcs_elf_gas.S"));
            },
        },
        .riscv64 => {
            lib.addAssemblyFile(b.path("src/asm/jump_riscv64_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_riscv64_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_riscv64_sysv_elf_gas.S"));
        },
        .x86 => switch (lib.rootModuleTarget().os.tag) {
            .windows => {
                // @panic("undefined symbol:{j/m/o}-fcontext");
                lib.addAssemblyFile(b.path("src/asm/jump_i386_ms_pe_clang_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_ms_pe_clang_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_ms_pe_clang_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/jump_i386_ms_pe_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_ms_pe_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_ms_pe_gas.S"));
            },
            .macos => {
                lib.addAssemblyFile(b.path("src/asm/jump_i386_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/jump_i386_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_x86_64_sysv_macho_gas.S"));
            },
            else => {
                lib.addAssemblyFile(b.path("src/asm/jump_i386_sysv_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_sysv_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_sysv_elf_gas.S"));
            },
        },
        .x86_64 => switch (lib.rootModuleTarget().os.tag) {
            .windows => {
                lib.addAssemblyFile(b.path("src/asm/jump_x86_64_ms_pe_clang_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_x86_64_ms_pe_clang_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_x86_64_ms_pe_clang_gas.S"));
            },
            .macos => {
                lib.addAssemblyFile(b.path("src/asm/jump_i386_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/jump_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_i386_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_x86_64_sysv_macho_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_i386_x86_64_sysv_macho_gas.S"));
            },
            else => {
                lib.addAssemblyFile(b.path("src/asm/jump_x86_64_sysv_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/make_x86_64_sysv_elf_gas.S"));
                lib.addAssemblyFile(b.path("src/asm/ontop_x86_64_sysv_elf_gas.S"));
            },
        },
        .s390x => {
            lib.addAssemblyFile(b.path("src/asm/jump_s390x_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_s390x_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_s390x_sysv_elf_gas.S"));
        },
        .mips, .mipsel => {
            lib.addAssemblyFile(b.path("src/asm/jump_mips32_o32_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_mips32_o32_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_mips32_o32_elf_gas.S"));
        },
        .mips64, .mips64el => {
            lib.addAssemblyFile(b.path("src/asm/jump_mips64_n64_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_mips64_n64_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_mips64_n64_elf_gas.S"));
        },
        .powerpc => {
            lib.addCSourceFile(.{
                .file = b.path("src/asm/tail_ontop_ppc32_sysv.cpp"),
                .flags = cxxFlags,
            });
            lib.addAssemblyFile(b.path("src/asm/jump_ppc32_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_ppc32_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_ppc32_sysv_elf_gas.S"));
        },
        .powerpc64 => {
            lib.addAssemblyFile(b.path("src/asm/jump_ppc64_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/make_ppc64_sysv_elf_gas.S"));
            lib.addAssemblyFile(b.path("src/asm/ontop_ppc64_sysv_elf_gas.S"));
        },
        else => @panic("Invalid arch"),
    }
    lib.addAssemblyFile(b.path("src/asm/make.S"));
    lib.addAssemblyFile(b.path("src/asm/jump.S"));
    lib.addAssemblyFile(b.path("src/asm/ontop.S"));
    lib.linkLibrary(boost);
    lib.linkLibCpp();

    lib.installHeadersDirectory(b.path("include"), "", .{});
    b.installArtifact(lib);

    if (tests) {
        buildTest(b, .{
            .path = "example/callcc/jump_mov.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/callcc/jump_void.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/circle.cpp",
            .lib = lib,
        });
        // missing libunwind
        if (!lib.rootModuleTarget().isDarwin()) buildTest(b, .{
            .path = "example/fiber/backtrace.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/fibonacci.cpp",
            .lib = lib,
        });
        if (lib.rootModuleTarget().cpu.arch == .x86_64) buildTest(b, .{
            .path = "example/fiber/echosse.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/jump.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/endless_loop.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/stack.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/throw.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/parser.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/ontop.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/ontop_void.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "example/fiber/segmented.cpp",
            .lib = lib,
        });
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.lib.root_module.optimize.?,
        .target = info.lib.root_module.resolved_target.?,
    });
    for (info.lib.root_module.include_dirs.items) |include| {
        test_exe.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    test_exe.addCSourceFile(.{
        .file = b.path(info.path),
        .flags = cxxFlags,
    });
    test_exe.linkLibrary(info.lib);
    test_exe.linkLibCpp();
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const src = &.{
    "src/continuation.cpp",
    "src/fiber.cpp",
};
const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
};

fn boostLibraries(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "boost",
        .target = target,
        .optimize = .ReleaseFast,
    });

    const boostCore = b.dependency("core", .{}).path("");
    const boostConfig = b.dependency("config", .{}).path("");
    const boostAssert = b.dependency("assert", .{}).path("");
    const boostPreprocessor = b.dependency("preprocessor", .{}).path("");
    const boostPredef = b.dependency("predef", .{}).path("");
    const boostIntrusive = b.dependency("intrusive", .{}).path("");
    const boostSmartPtr = b.dependency("smart_ptr", .{}).path("");

    lib.addCSourceFile(.{
        .file = b.path("test/empty.cc"),
        .flags = cxxFlags,
    });
    if (lib.rootModuleTarget().abi != .msvc)
        lib.linkLibCpp()
    else
        lib.linkLibC();

    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostCore.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostConfig.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostAssert.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostPreprocessor.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostPredef.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostIntrusive.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostSmartPtr.getPath(b), "include" }) });

    return lib;
}

const BuildInfo = struct {
    lib: *std.Build.Step.Compile,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
