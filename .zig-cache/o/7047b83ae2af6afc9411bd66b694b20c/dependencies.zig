pub const packages = struct {
    pub const @"122031789a7c6364c2f99164c1183661bb5fe914ad7336cc224039c7fba649f35c47" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAB0eQwD-0MdOEBmz7intriBReIsIDNlukNVoNu6o" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/N-V-__8AAB0eQwD-0MdOEBmz7intriBReIsIDNlukNVoNu6o";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAGsYnAT5RIzeAu881RveLghQ1EidqgVBVx10gVTo" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAIz1QAKx8C8vft2YoHjGTjEAkH2QMR2UiAo8xZJ-" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAJ-wTwNc0T9oSflO92iO6IxrdMeRil37UU-KQD_M" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAJHgXwBPt17hQdF6ZmDlBAakhffuHGSNcE49WWzL" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/N-V-__8AAJHgXwBPt17hQdF6ZmDlBAakhffuHGSNcE49WWzL";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAK7XUQNKNRnv1J6i189jtURJKjp3HTftoyD4Y4CB" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AALVIRAIf5nfpx8-4mEo2RGsynVryPQPcHk95qFM5" = struct {
        pub const available = false;
    };
    pub const @"deps/freetype" = struct {
        pub const build_root = "/safe/Safe/openclaw-config/workspace/ziggy-ui/deps/freetype";
        pub const build_zig = @import("deps/freetype");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "brotli", "122031789a7c6364c2f99164c1183661bb5fe914ad7336cc224039c7fba649f35c47" },
            .{ "libpng", "libpng-1.6.53-oiaFGtwqAAB2XTxMgi4dG96BUO-0_BtUFtxKraIwq6-w" },
            .{ "libpng_src", "N-V-__8AAJHgXwBPt17hQdF6ZmDlBAakhffuHGSNcE49WWzL" },
            .{ "zlib_src", "N-V-__8AAB0eQwD-0MdOEBmz7intriBReIsIDNlukNVoNu6o" },
        };
    };
    pub const @"deps/zgpu" = struct {
        pub const build_root = "/safe/Safe/openclaw-config/workspace/ziggy-ui/deps/zgpu";
        pub const build_zig = @import("deps/zgpu");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "zpool", "zpool-0.11.0-dev-bG692QtEAQCyqBnzSBJbJlY0-a_3v1YcjFTGmg0VBjOc" },
            .{ "system_sdk", "system_sdk-0.3.0-dev-alwUNnYaaAJAtIdE2fg4NQfDqEKs7QCXy_qYukAOBfmF" },
            .{ "dawn_x86_64_windows_gnu", "N-V-__8AAGsYnAT5RIzeAu881RveLghQ1EidqgVBVx10gVTo" },
            .{ "dawn_x86_64_linux_gnu", "N-V-__8AAK7XUQNKNRnv1J6i189jtURJKjp3HTftoyD4Y4CB" },
            .{ "dawn_aarch64_linux_gnu", "N-V-__8AAJ-wTwNc0T9oSflO92iO6IxrdMeRil37UU-KQD_M" },
            .{ "dawn_aarch64_macos", "N-V-__8AALVIRAIf5nfpx8-4mEo2RGsynVryPQPcHk95qFM5" },
            .{ "dawn_x86_64_macos", "N-V-__8AAIz1QAKx8C8vft2YoHjGTjEAkH2QMR2UiAo8xZJ-" },
        };
    };
    pub const @"libpng-1.6.53-oiaFGtwqAAB2XTxMgi4dG96BUO-0_BtUFtxKraIwq6-w" = struct {
        pub const available = true;
        pub const build_root = "/home/deano/.cache/zig/p/libpng-1.6.53-oiaFGtwqAAB2XTxMgi4dG96BUO-0_BtUFtxKraIwq6-w";
        pub const build_zig = @import("libpng-1.6.53-oiaFGtwqAAB2XTxMgi4dG96BUO-0_BtUFtxKraIwq6-w");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "libpng", "N-V-__8AAJHgXwBPt17hQdF6ZmDlBAakhffuHGSNcE49WWzL" },
            .{ "zlib", "zlib-1.3.1-ZZQ7lc8NAABUbHzDe_cSWboCqMbrLkVwvFkKnojgeiT2" },
        };
    };
    pub const @"sdl-0.3.3+3.2.28-7uIn9MiRfwFhqxnwBi_vCQlKr82YpwkQBVwdz2uy46S1" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/sdl-0.3.3+3.2.28-7uIn9MiRfwFhqxnwBi_vCQlKr82YpwkQBVwdz2uy46S1";
        pub const build_zig = @import("sdl-0.3.3+3.2.28-7uIn9MiRfwFhqxnwBi_vCQlKr82YpwkQBVwdz2uy46S1");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "sdl_linux_deps", "sdl_linux_deps-0.0.0-Vy5_h4AlfwBtG7MIPe7ZNUANhmYLek_SA140uYk9SrED" },
        };
    };
    pub const @"sdl_linux_deps-0.0.0-Vy5_h4AlfwBtG7MIPe7ZNUANhmYLek_SA140uYk9SrED" = struct {
        pub const available = true;
        pub const build_root = "/home/deano/.cache/zig/p/sdl_linux_deps-0.0.0-Vy5_h4AlfwBtG7MIPe7ZNUANhmYLek_SA140uYk9SrED";
        pub const build_zig = @import("sdl_linux_deps-0.0.0-Vy5_h4AlfwBtG7MIPe7ZNUANhmYLek_SA140uYk9SrED");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"system_sdk-0.3.0-dev-alwUNnYaaAJAtIdE2fg4NQfDqEKs7QCXy_qYukAOBfmF" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/system_sdk-0.3.0-dev-alwUNnYaaAJAtIdE2fg4NQfDqEKs7QCXy_qYukAOBfmF";
        pub const build_zig = @import("system_sdk-0.3.0-dev-alwUNnYaaAJAtIdE2fg4NQfDqEKs7QCXy_qYukAOBfmF");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"zlib-1.3.1-ZZQ7lc8NAABUbHzDe_cSWboCqMbrLkVwvFkKnojgeiT2" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/zlib-1.3.1-ZZQ7lc8NAABUbHzDe_cSWboCqMbrLkVwvFkKnojgeiT2";
        pub const build_zig = @import("zlib-1.3.1-ZZQ7lc8NAABUbHzDe_cSWboCqMbrLkVwvFkKnojgeiT2");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "zlib", "N-V-__8AAB0eQwD-0MdOEBmz7intriBReIsIDNlukNVoNu6o" },
        };
    };
    pub const @"zpool-0.11.0-dev-bG692QtEAQCyqBnzSBJbJlY0-a_3v1YcjFTGmg0VBjOc" = struct {
        pub const build_root = "/home/deano/.cache/zig/p/zpool-0.11.0-dev-bG692QtEAQCyqBnzSBJbJlY0-a_3v1YcjFTGmg0VBjOc";
        pub const build_zig = @import("zpool-0.11.0-dev-bG692QtEAQCyqBnzSBJbJlY0-a_3v1YcjFTGmg0VBjOc");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "sdl3", "sdl-0.3.3+3.2.28-7uIn9MiRfwFhqxnwBi_vCQlKr82YpwkQBVwdz2uy46S1" },
    .{ "zgpu", "deps/zgpu" },
    .{ "freetype", "deps/freetype" },
};
