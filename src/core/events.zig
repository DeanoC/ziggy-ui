//! Event system for GUI interactions
const std = @import("std");

/// Input event types
pub const Event = union(enum) {
    // Mouse events
    mouse_move: MouseMoveEvent,
    mouse_down: MouseButtonEvent,
    mouse_up: MouseButtonEvent,
    mouse_scroll: MouseScrollEvent,

    // Keyboard events
    key_down: KeyEvent,
    key_up: KeyEvent,
    char_input: CharInputEvent,

    // Window events
    window_resize: WindowResizeEvent,
    window_focus: WindowFocusEvent,
    window_close: WindowCloseEvent,

    // Touch events (for mobile)
    touch_begin: TouchEvent,
    touch_move: TouchEvent,
    touch_end: TouchEvent,

    // Drag and drop
    drag_start: DragEvent,
    drag_move: DragEvent,
    drag_end: DragEvent,
    drop: DropEvent,
};

/// Mouse move event
pub const MouseMoveEvent = struct {
    pos: [2]f32,
    delta: [2]f32,
    timestamp: i64,
};

/// Mouse button event
pub const MouseButtonEvent = struct {
    button: MouseButton,
    pos: [2]f32,
    modifiers: Modifiers,
    timestamp: i64,
};

/// Mouse scroll event
pub const MouseScrollEvent = struct {
    delta_x: f32,
    delta_y: f32,
    pos: [2]f32,
    modifiers: Modifiers,
    timestamp: i64,
};

/// Mouse buttons
pub const MouseButton = enum {
    left,
    right,
    middle,
    back,
    forward,
};

/// Keyboard modifiers
pub const Modifiers = packed struct {
    shift: bool = false,
    ctrl: bool = false,
    alt: bool = false,
    meta: bool = false, // Command on macOS, Windows key on Windows

    pub fn fromSDL(sdl_mods: u16) Modifiers {
        return .{
            .shift = (sdl_mods & 0x0001) != 0 or (sdl_mods & 0x0002) != 0,
            .ctrl = (sdl_mods & 0x0040) != 0 or (sdl_mods & 0x0080) != 0,
            .alt = (sdl_mods & 0x0100) != 0 or (sdl_mods & 0x0200) != 0,
            .meta = (sdl_mods & 0x0400) != 0 or (sdl_mods & 0x0800) != 0,
        };
    }
};

/// Key event
pub const KeyEvent = struct {
    key: Key,
    scancode: i32,
    modifiers: Modifiers,
    repeat: bool,
    timestamp: i64,
};

/// Keys
pub const Key = enum {
    unknown,
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    num_0,
    num_1,
    num_2,
    num_3,
    num_4,
    num_5,
    num_6,
    num_7,
    num_8,
    num_9,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    escape,
    enter,
    tab,
    backspace,
    insert,
    delete,
    right,
    left,
    down,
    up,
    page_up,
    page_down,
    home,
    end,
    caps_lock,
    scroll_lock,
    num_lock,
    print_screen,
    pause,
    space,
    apostrophe,
    comma,
    minus,
    period,
    slash,
    semicolon,
    equal,
    bracket_left,
    backslash,
    bracket_right,
    grave,

    // Numpad
    kp_0,
    kp_1,
    kp_2,
    kp_3,
    kp_4,
    kp_5,
    kp_6,
    kp_7,
    kp_8,
    kp_9,
    kp_decimal,
    kp_divide,
    kp_multiply,
    kp_subtract,
    kp_add,
    kp_enter,
    kp_equal,

    // Modifier keys
    left_shift,
    left_ctrl,
    left_alt,
    left_super,
    right_shift,
    right_ctrl,
    right_alt,
    right_super,

    // Application keys
    menu,

    pub fn isPrintable(self: Key) bool {
        return switch (self) {
            .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z, .num_0, .num_1, .num_2, .num_3, .num_4, .num_5, .num_6, .num_7, .num_8, .num_9, .space, .apostrophe, .comma, .minus, .period, .slash, .semicolon, .equal, .bracket_left, .backslash, .bracket_right, .grave, .kp_0, .kp_1, .kp_2, .kp_3, .kp_4, .kp_5, .kp_6, .kp_7, .kp_8, .kp_9, .kp_decimal, .kp_divide, .kp_multiply, .kp_subtract, .kp_add, .kp_equal => true,
            else => false,
        };
    }

    pub fn toChar(self: Key, shift: bool) ?u8 {
        return switch (self) {
            .a => if (shift) 'A' else 'a',
            .b => if (shift) 'B' else 'b',
            .c => if (shift) 'C' else 'c',
            .d => if (shift) 'D' else 'd',
            .e => if (shift) 'E' else 'e',
            .f => if (shift) 'F' else 'f',
            .g => if (shift) 'G' else 'g',
            .h => if (shift) 'H' else 'h',
            .i => if (shift) 'I' else 'i',
            .j => if (shift) 'J' else 'j',
            .k => if (shift) 'K' else 'k',
            .l => if (shift) 'L' else 'l',
            .m => if (shift) 'M' else 'm',
            .n => if (shift) 'N' else 'n',
            .o => if (shift) 'O' else 'o',
            .p => if (shift) 'P' else 'p',
            .q => if (shift) 'Q' else 'q',
            .r => if (shift) 'R' else 'r',
            .s => if (shift) 'S' else 's',
            .t => if (shift) 'T' else 't',
            .u => if (shift) 'U' else 'u',
            .v => if (shift) 'V' else 'v',
            .w => if (shift) 'W' else 'w',
            .x => if (shift) 'X' else 'x',
            .y => if (shift) 'Y' else 'y',
            .z => if (shift) 'Z' else 'z',
            .num_0 => '0',
            .num_1 => '1',
            .num_2 => '2',
            .num_3 => '3',
            .num_4 => '4',
            .num_5 => '5',
            .num_6 => '6',
            .num_7 => '7',
            .num_8 => '8',
            .num_9 => '9',
            .space => ' ',
            .comma => if (shift) '<' else ',',
            .period => if (shift) '>' else '.',
            .slash => if (shift) '?' else '/',
            .semicolon => if (shift) ':' else ';',
            .apostrophe => if (shift) '"' else '\'',
            .bracket_left => if (shift) '{' else '[',
            .bracket_right => if (shift) '}' else ']',
            .backslash => if (shift) '|' else '\\',
            .minus => if (shift) '_' else '-',
            .equal => if (shift) '+' else '=',
            .grave => if (shift) '~' else '`',
            .kp_0 => '0',
            .kp_1 => '1',
            .kp_2 => '2',
            .kp_3 => '3',
            .kp_4 => '4',
            .kp_5 => '5',
            .kp_6 => '6',
            .kp_7 => '7',
            .kp_8 => '8',
            .kp_9 => '9',
            else => null,
        };
    }
};

/// Character input event (for text entry)
pub const CharInputEvent = struct {
    codepoint: u32,
    timestamp: i64,
};

/// Window resize event
pub const WindowResizeEvent = struct {
    width: u32,
    height: u32,
    window_id: u32,
};

/// Window focus event
pub const WindowFocusEvent = struct {
    focused: bool,
    window_id: u32,
};

/// Window close event
pub const WindowCloseEvent = struct {
    window_id: u32,
};

/// Touch event
pub const TouchEvent = struct {
    id: i64,
    pos: [2]f32,
    pressure: f32,
    timestamp: i64,
};

/// Drag event
pub const DragEvent = struct {
    source_id: u64,
    payload_type: []const u8,
    pos: [2]f32,
};

/// Drop event
pub const DropEvent = struct {
    source_id: u64,
    target_id: u64,
    payload_type: []const u8,
    payload_data: []const u8,
};

/// Event queue for buffering events
pub const EventQueue = struct {
    allocator: std.mem.Allocator,
    events: std.ArrayList(Event),

    pub fn init(allocator: std.mem.Allocator) EventQueue {
        return .{
            .allocator = allocator,
            .events = .empty,
        };
    }

    pub fn deinit(self: *EventQueue) void {
        self.events.deinit(self.allocator);
    }

    pub fn push(self: *EventQueue, event: Event) !void {
        try self.events.append(self.allocator, event);
    }

    pub fn pop(self: *EventQueue) ?Event {
        if (self.events.items.len == 0) return null;
        return self.events.orderedRemove(0);
    }

    pub fn peek(self: *const EventQueue) ?Event {
        if (self.events.items.len == 0) return null;
        return self.events.items[0];
    }

    pub fn clear(self: *EventQueue) void {
        self.events.clearRetainingCapacity();
    }

    pub fn len(self: *const EventQueue) usize {
        return self.events.items.len;
    }

    pub fn isEmpty(self: *const EventQueue) bool {
        return self.events.items.len == 0;
    }
};

/// Event dispatcher with handler registration
pub const EventDispatcher = struct {
    const Handler = struct {
        id: u64,
        callback: *const fn (event: Event, userdata: ?*anyopaque) bool,
        userdata: ?*anyopaque,
    };

    allocator: std.mem.Allocator,
    handlers: std.ArrayList(Handler),
    next_id: u64 = 1,

    pub fn init(allocator: std.mem.Allocator) EventDispatcher {
        return .{
            .allocator = allocator,
            .handlers = .empty,
            .next_id = 1,
        };
    }

    pub fn deinit(self: *EventDispatcher) void {
        self.handlers.deinit(self.allocator);
    }

    pub fn register(
        self: *EventDispatcher,
        callback: *const fn (event: Event, userdata: ?*anyopaque) bool,
        userdata: ?*anyopaque,
    ) !u64 {
        const id = self.next_id;
        self.next_id += 1;

        try self.handlers.append(self.allocator, .{
            .id = id,
            .callback = callback,
            .userdata = userdata,
        });

        return id;
    }

    pub fn unregister(self: *EventDispatcher, id: u64) void {
        for (self.handlers.items, 0..) |handler, i| {
            if (handler.id == id) {
                _ = self.handlers.orderedRemove(i);
                return;
            }
        }
    }

    pub fn dispatch(self: *EventDispatcher, event: Event) bool {
        for (self.handlers.items) |handler| {
            if (handler.callback(event, handler.userdata)) {
                return true; // Event was handled
            }
        }
        return false;
    }
};
