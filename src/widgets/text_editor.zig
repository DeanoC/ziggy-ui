//! Text editor widget (multi-line)
const std = @import("std");
const theme = @import("../themes/theme.zig");
const colors = @import("../themes/colors.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");
const TextInput = @import("text_input.zig");

/// Text editor options
pub const Options = struct {
    disabled: bool = false,
    read_only: bool = false,
    line_numbers: bool = true,
    word_wrap: bool = false,
    language: ?[]const u8 = null, // for syntax highlighting hints
};

/// Text editor state
pub const TextEditor = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),
    cursor_pos: usize = 0,
    selection_start: ?usize = null,
    scroll_offset: [2]f32 = .{ 0, 0 },
    focused: bool = false,

    pub fn init(allocator: std.mem.Allocator) TextEditor {
        return .{
            .allocator = allocator,
            .buffer = std.ArrayList(u8).empty,
        };
    }

    pub fn initWithCapacity(allocator: std.mem.Allocator, capacity: usize) TextEditor {
        return .{
            .allocator = allocator,
            .buffer = std.ArrayList(u8).initCapacity(allocator, capacity) catch std.ArrayList(u8).empty,
        };
    }

    pub fn deinit(self: *TextEditor) void {
        self.buffer.deinit();
    }

    pub fn clear(self: *TextEditor) void {
        self.buffer.clearRetainingCapacity();
        self.cursor_pos = 0;
        self.selection_start = null;
    }

    pub fn insertText(self: *TextEditor, text: []const u8) !void {
        try self.buffer.insertSlice(self.cursor_pos, text);
        self.cursor_pos += text.len;
    }

    pub fn deleteSelection(self: *TextEditor) void {
        if (self.selection_start) |start| {
            const end = self.cursor_pos;
            const sel_start = @min(start, end);
            const sel_end = @max(start, end);
            
            _ = self.buffer.orderedRemoveRange(sel_start, sel_end - sel_start);
            self.cursor_pos = sel_start;
            self.selection_start = null;
        }
    }

    pub fn getText(self: *const TextEditor) []const u8 {
        return self.buffer.items;
    }

    pub fn setText(self: *TextEditor, text: []const u8) !void {
        self.buffer.clearRetainingCapacity();
        try self.buffer.appendSlice(text);
        self.cursor_pos = 0;
        self.selection_start = null;
    }
};

/// Get background color for editor
pub fn getBackgroundColor(t: *const theme.Theme, opts: Options) colors.Color {
    if (opts.disabled) {
        return colors.withAlpha(t.colors.background, 0.5);
    }
    return t.colors.background;
}

/// Get text color for editor
pub fn getTextColor(t: *const theme.Theme, opts: Options) colors.Color {
    if (opts.disabled) {
        return colors.withAlpha(t.colors.text_primary, 0.4);
    }
    return t.colors.text_primary;
}

/// Get line number color
pub fn getLineNumberColor(t: *const theme.Theme) colors.Color {
    return colors.withAlpha(t.colors.text_secondary, 0.6);
}

/// Get selection color
pub fn getSelectionColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.text_input.selection orelse colors.withAlpha(t.colors.primary, 0.3);
}

/// Get caret color
pub fn getCaretColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.text_input.caret orelse t.colors.primary;
}

/// Get gutter (line numbers area) background
pub fn getGutterColor(t: *const theme.Theme) colors.Color {
    return colors.blend(t.colors.background, t.colors.surface, 0.5);
}

/// Editor layout info
pub const LayoutInfo = struct {
    line_height: f32,
    char_width: f32,
    gutter_width: f32,
    content_offset_x: f32,
};

/// Calculate layout dimensions
pub fn calculateLayout(t: *const theme.Theme, opts: Options, max_line_digits: usize) LayoutInfo {
    const line_height = t.typography.body_size * 1.4;
    const char_width = t.typography.body_size * 0.6; // Approximate monospace
    
    const gutter_width = if (opts.line_numbers)
        char_width * @as(f32, @floatFromInt(max_line_digits + 2))
    else
        0;
    
    return .{
        .line_height = line_height,
        .char_width = char_width,
        .gutter_width = gutter_width,
        .content_offset_x = gutter_width + t.spacing.sm,
    };
}
