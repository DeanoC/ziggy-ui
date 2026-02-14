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

    const freetype_dep = b.dependency("freetype", .{
        .target = target,
        .optimize = optimize,
        .enable_brotli = false, // Disable old brotli dependency
    });

    // Create the main ziggy-ui module
    const ziggy_ui_mod = b.addModule("ziggy-ui", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add build options
    ziggy_ui_mod.addOptions("build_options", build_options);

    // Add SDL3 include path (SDL3 is a C library, not a Zig module)
    if (enable_sdl) {
        ziggy_ui_mod.addIncludePath(sdl3_dep.path("include"));
    }

    // Add freetype include path
    if (enable_freetype) {
        ziggy_ui_mod.addIncludePath(freetype_dep.path("include"));
    }

    // Create static library
    const lib = b.addLibrary(.{
        .name = "ziggy-ui",
        .root_module = ziggy_ui_mod,
        .linkage = .static,
    });

    // Link SDL3
    if (enable_sdl) {
        lib.linkLibrary(sdl3_dep.artifact("SDL3"));
    }

    // Link freetype
    if (enable_freetype) {
        lib.linkLibrary(freetype_dep.artifact("freetype"));
    }

    b.installArtifact(lib);

    // Tests
    const test_step = b.step("test", "Run ziggy-ui tests");

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addOptions("build_options", build_options);
    if (enable_sdl) {
        test_mod.addIncludePath(sdl3_dep.path("include"));
    }
    if (enable_freetype) {
        test_mod.addIncludePath(freetype_dep.path("include"));
    }

    const tests = b.addTest(.{
        .root_module = test_mod,
    });
    if (enable_sdl) {
        tests.linkLibrary(sdl3_dep.artifact("SDL3"));
    }
    if (enable_freetype) {
        tests.linkLibrary(freetype_dep.artifact("freetype"));
    }
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    const build_examples = b.option(bool, "build-examples", "Build ziggy-ui examples") orelse false;
    if (build_examples) {
        // Example: basic
        const example_mod = b.createModule(.{
            .root_source_file = b.path("examples/basic.zig"),
            .target = target,
            .optimize = optimize,
        });
        example_mod.addImport("ziggy-ui", ziggy_ui_mod);
        if (enable_sdl) {
            example_mod.addIncludePath(sdl3_dep.path("include"));
        }
        if (enable_freetype) {
            example_mod.addIncludePath(freetype_dep.path("include"));
        }

        const example_basic = b.addExecutable(.{
            .name = "example-basic",
            .root_module = example_mod,
        });
        if (enable_sdl) {
            example_basic.linkLibrary(sdl3_dep.artifact("SDL3"));
        }
        if (enable_freetype) {
            example_basic.linkLibrary(freetype_dep.artifact("freetype"));
        }
        b.installArtifact(example_basic);

        const run_example = b.addRunArtifact(example_basic);
        const example_step = b.step("example-basic", "Run the basic example");
        example_step.dependOn(&run_example.step);
    }
}
