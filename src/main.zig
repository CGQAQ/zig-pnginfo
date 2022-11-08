const std = @import("std");
const io = std.io;
const os = std.os;
const fs = std.fs;
const process = std.process;
const mem = std.mem;
const print = std.debug.print;

const png_CHUNK_IHDR =  struct {
    length: u32 align(1),
    chunk_type: u32 align(1),
    data: png_IHDR align(1),
    crc: u32 align(1),
};

const png_IHDR = struct {
    width: u32 align(1),
    height: u32 align(1),
    bit_depth: u8,
    color_type: u8,
    compression_method: u8,
    filter_method: u8,
    interlace_method: u8,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    if (args.len != 2) {
        _ = try io.getStdErr().write("Usage: zig-pnginfo <file.png>");
        return;
    }

    // resolve the path
    const path = try fs.realpathAlloc(allocator, args[1]);
    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    const data = try file.readToEndAlloc(allocator, 102400000);

    if (mem.eql(u8, data[0..7], &[_]u8{137, 80, 78, 71, 13, 10, 26, 10})){
        _ = try io.getStdErr().write("Not a PNG file");
        return;
    }

    var offset: usize = 8;
    var iHDR = while(true) {
        // find the ihdr chunk
        var chunk: *png_CHUNK_IHDR = allocator.create(png_CHUNK_IHDR) catch unreachable;
        const chunk_size = @sizeOf(png_CHUNK_IHDR);
        @memcpy(@ptrCast([*]u8, &chunk), @ptrCast([*]const u8, &data[offset..]), chunk_size);
        // std.debug.print("chunk type: {x}\n", .{chunk.chunk_type});
        // print("align: {d} {d}\n", .{@alignOf(png_CHUNK_IHDR), @alignOf(png_IHDR)});

        chunk.length = @byteSwap(chunk.length);
        chunk.data.width = @byteSwap(chunk.data.width);
        chunk.data.height = @byteSwap(chunk.data.height);

        // return;
        // print("{x}, {x}, {}\n", .{chunk.chunk_type, 0x52444849, chunk.chunk_type == 0x52444849});

        if (chunk.chunk_type == 0x52444849){
            break chunk;
        } else if(offset >= data.len){
            _ = try io.getStdErr().write("No IHDR chunk found");
            return;
        } else {
            offset += 1;
            continue;
        }
    };
    defer allocator.destroy(iHDR);


    std.debug.print("{}", .{iHDR});
}