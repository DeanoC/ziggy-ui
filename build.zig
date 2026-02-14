const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options for backend selection
    const enable_wgpu = b.option(bool, "wgpu", "Enable WGPU renderer backend") orelse true;
    const enable_sdl = b.option(bool, "sdl", "Enable SDL platform backend") orelse true;
    const enable_freetype = b.option(bool, "freetype", "Enable FreeType font rendering") orelse true;

    // Create build options module
    const build_options = b.addOptions();
    build_options.addOption(bool, "enable_wgpu", enable_wgpu);
    build_options.addOption(bool, "enable_sdl", enable_sdl);
    build_options.addOption(bool, "enable_freetype", enable_freetype);

    // Dependencies
    const sdl3_dep = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
    });

    // Vendored freetype for Zig 0.15 compatibility
    const freetype_dep = b.dependency("freetype", .{
        .target = target,
        .optimize = optimize,
    });
    _ = freetype_dep; // Used for linking

    // Create the main ziggy-ui module
    const ziggy_ui_mod = b.addModule("ziggy-ui", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add build options
    ziggy_ui_mod.addOptions("build_options", build_options);

    // Add SDL3
    if (enable_sdl) {
        ziggy_ui_mod.addImport("sdl3", sdl3_dep.module("sdl3"));
    }

    // Create static library
    const lib = b.addStaticLibrary(.{
        .name = "ziggy-ui",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add imports to library
    lib.root_module.addOptions("build_options", build_options);
    if (enable_sdl) {
        lib.root_module.addImport("sdl3", sdl3_dep.module("sdl3"));
    }

    // Link SDL3
    if (enable_sdl) {
        lib.linkLibrary(sdl3_dep.artifact("SDL3"));
    }

    b.installArtifact(lib);

    // Tests
    const test_step = b.step("test", "Run ziggy-ui tests");

    const tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addOptions("build_options", build_options);
    if (enable_sdl) {
        tests.root_module.addImport("sdl3", sdl3_dep.module("sdl3"));
    }
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    // Example: basic
    const example_basic = b.addExecutable(.{
        .name = "example-basic",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    example_basic.root_module.addImport("ziggy-ui", ziggy_ui_mod);
    if (enable_sdl) {
        example_basic.root_module.addImport("sdl3", sdl3_dep.module("sdl3"));
        example_basic.linkLibrary(sdl3_dep.artifact("SDL3"));
    }
    b.installArtifact(example_basic);

    const run_example = b.addRunArtifact(example_basic);
    const example_step = b.step("example-basic", "Run the basic example");
    example_step.dependOn(&run_example.step);
}