const std = @import("std");
const sdl = @import("../../platform/sdl3.zig").c;
const sdl_input_backend = @import("../input/sdl_input_backend.zig");
const input_router = @import("../input/input_router.zig");
const input_state = @import("../input/input_state.zig");

pub const c = sdl;

pub const InitOptions = struct {
    video: bool = true,
    gamepad: bool = false,
    events: bool = true,
    ime_ui: bool = true,
};

pub const PollResult = struct {
    quit_requested: bool = false,
    window_close_requested: bool = false,
    window_close_id: u32 = 0,
};

pub fn init(opts: InitOptions) !void {
    var flags: u64 = 0;
    if (opts.video) flags |= sdl.SDL_INIT_VIDEO;
    if (opts.gamepad) flags |= sdl.SDL_INIT_GAMEPAD;
    if (opts.events) flags |= sdl.SDL_INIT_EVENTS;

    if (!sdl.SDL_Init(@intCast(flags))) {
        return error.SdlInitFailed;
    }
    if (opts.ime_ui) {
        _ = sdl.SDL_SetHint("SDL_IME_SHOW_UI", "1");
    }
}

pub fn deinit() void {
    sdl.SDL_Quit();
}

pub fn createWindow(title: [:0]const u8, width: c_int, height: c_int, flags: sdl.SDL_WindowFlags) !*sdl.SDL_Window {
    return sdl.SDL_CreateWindow(title, width, height, flags) orelse error.SdlWindowCreateFailed;
}

pub fn pollEventsToInput() PollResult {
    var result = PollResult{};
    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event)) {
        sdl_input_backend.pushEvent(&event);
        switch (event.type) {
            sdl.SDL_EVENT_QUIT => result.quit_requested = true,
            sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED => {
                result.window_close_requested = true;
                result.window_close_id = event.window.windowID;
            },
            else => {},
        }
    }
    return result;
}

pub fn collectWindowInput(allocator: std.mem.Allocator, window: *sdl.SDL_Window, queue: *input_state.InputQueue) void {
    sdl_input_backend.setCollectWindow(window);
    defer sdl_input_backend.setCollectWindow(null);

    input_router.setExternalQueue(queue);
    defer input_router.setExternalQueue(null);

    input_router.collect(allocator);
}

pub fn startTextInput(window: *sdl.SDL_Window) void {
    _ = sdl.SDL_StartTextInput(window);
}

pub fn stopTextInput(window: *sdl.SDL_Window) void {
    _ = sdl.SDL_StopTextInput(window);
}

pub fn delayMs(ms: u32) void {
    _ = sdl.SDL_Delay(ms);
}
