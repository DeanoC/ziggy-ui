//! Render backend interface
const std = @import("std");
const Rect = @import("../core/context.zig").Rect;
const Vec2 = @import("../core/context.zig").Vec2;
const Color = @import("../core/context.zig").Color;
const Texture = @import("../core/context.zig").Texture;
const CommandList = @import("command_list.zig").CommandList;

/// Render backend interface - implementations must provide these functions
pub const RenderBackend = struct {
    /// Initialize the renderer
    init: *const fn (ctx: ?*anyopaque, allocator: std.mem.Allocator) anyerror!void,

    /// Shutdown the renderer
    deinit: *const fn (ctx: ?*anyopaque) void,

    /// Begin a frame
    beginFrame: *const fn (ctx: ?*anyopaque, width: u32, height: u32) anyerror!void,

    /// End a frame and present
    endFrame: *const fn (ctx: ?*anyopaque) anyerror!void,

    /// Execute a command list
    executeCommandList: *const fn (ctx: ?*anyopaque, list: *const CommandList) anyerror!void,

    /// Create a texture from RGBA data
    createTexture: *const fn (ctx: ?*anyopaque, width: u32, height: u32, data: ?[]const u8) anyerror!Texture,

    /// Update texture data
    updateTexture: *const fn (ctx: ?*anyopaque, texture: Texture, x: u32, y: u32, width: u32, height: u32, data: []const u8) anyerror!void,

    /// Destroy a texture
    destroyTexture: *const fn (ctx: ?*anyopaque, texture: Texture) void,

    /// Get texture size
    getTextureSize: *const fn (ctx: ?*anyopaque, texture: Texture) ?Vec2,

    /// Set viewport
    setViewport: *const fn (ctx: ?*anyopaque, x: u32, y: u32, width: u32, height: u32) void,

    /// Set clip rect (scissor)
    setClipRect: *const fn (ctx: ?*anyopaque, rect: ?Rect) void,

    /// Clear the screen
    clear: *const fn (ctx: ?*anyopaque, color: Color) void,
};

/// Renderer instance that wraps a backend
pub const Renderer = struct {
    backend: RenderBackend,
    ctx: ?*anyopaque,
    allocator: std.mem.Allocator,

    pub fn init(backend: RenderBackend, ctx: ?*anyopaque, allocator: std.mem.Allocator) !Renderer {
        try backend.init(ctx, allocator);
        return .{
            .backend = backend,
            .ctx = ctx,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.backend.deinit(self.ctx);
    }

    pub fn beginFrame(self: *Renderer, width: u32, height: u32) !void {
        try self.backend.beginFrame(self.ctx, width, height);
    }

    pub fn endFrame(self: *Renderer) !void {
        try self.backend.endFrame(self.ctx);
    }

    pub fn executeCommandList(self: *Renderer, list: *const CommandList) !void {
        try self.backend.executeCommandList(self.ctx, list);
    }

    pub fn createTexture(self: *Renderer, width: u32, height: u32, data: ?[]const u8) !Texture {
        return try self.backend.createTexture(self.ctx, width, height, data);
    }

    pub fn updateTexture(self: *Renderer, texture: Texture, x: u32, y: u32, width: u32, height: u32, data: []const u8) !void {
        try self.backend.updateTexture(self.ctx, texture, x, y, width, height, data);
    }

    pub fn destroyTexture(self: *Renderer, texture: Texture) void {
        self.backend.destroyTexture(self.ctx, texture);
    }

    pub fn getTextureSize(self: *Renderer, texture: Texture) ?Vec2 {
        return self.backend.getTextureSize(self.ctx, texture);
    }

    pub fn setViewport(self: *Renderer, x: u32, y: u32, width: u32, height: u32) void {
        self.backend.setViewport(self.ctx, x, y, width, height);
    }

    pub fn setClipRect(self: *Renderer, rect: ?Rect) void {
        self.backend.setClipRect(self.ctx, rect);
    }

    pub fn clear(self: *Renderer, color: Color) void {
        self.backend.clear(self.ctx, color);
    }
};
