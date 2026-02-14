//! Basic ziggy-ui example
const std = @import("std");
const ui = @import("ziggy-ui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("ziggy-ui version: {s}", .{ui.version});

    // Initialize theme engine
    const caps = ui.theme_engine.PlatformCaps.defaultForTarget();
    var engine = ui.theme_engine.ThemeEngine.init(allocator, caps);
    defer engine.deinit();

    // Get current theme
    const theme = ui.theme.current();
    std.log.info("Theme primary color: {any}", .{theme.colors.primary});

    // Initialize platform
    const backend = ui.platform.sdl3.getBackend();
    var platform = try ui.platform.Platform.init(backend, allocator);
    defer platform.deinit();

    // Create window
    const window_id = try platform.createWindow(.{
        .title = "ziggy-ui Example",
        .width = 800,
        .height = 600,
    }, null);
    
    platform.showWindow(window_id);

    // Main loop
    var running = true;
    while (running) {
        try platform.pollEvents();
        
        while (platform.getNextEvent()) |event| {
            switch (event) {
                .window_close => running = false,
                .key_down => |ke| {
                    if (ke.key == .escape) running = false;
                },
                else => {},
            }
        }

        // Render here
        
        platform.sleep(1.0 / 60.0);
    }
}
