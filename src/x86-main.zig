// const std = @import("std");
// const builtin = std.builtin;

const multiboot = @import("multiboot2.zig");
const vga = @import("x86/vga.zig");

export fn kmain(magic: u32, info_addr: u32) noreturn {
    vga.initialize();
    vga.puts("Initialising...\n");

    vga.printf("magic: {}\n", .{magic});
    vga.printf("info_addr: {}\n", .{info_addr});

    if (magic != multiboot.BOOTLOADER_MAGIC) {
        @panic("Invalid magic number");
    }
    vga.puts("magic is valid\n");
    if ((info_addr & 7) != 0) {
        @panic("Unaligned mbi");
    }
    vga.puts("info_addr is valid\n");
    const info_ptr: *u32 = @ptrFromInt(info_addr);
    var info_iter = multiboot.BootInfoIter.init(info_ptr);
    while (info_iter.next()) |tag| {
        const tag_type = tag.ptr.*.tag_type() catch unreachable;
        vga.printf("tag_type: {}\n", .{tag_type});
    }
    while (true) {}
}

// pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace, something: ?usize) noreturn {
//     vga.setColor(vga.ConsoleColors.Red);
//     vga.puts("\nKERNEL PANIC:\n");
//     vga.puts(msg);
//     vga.puts("\n");

//     vga.printf("{}\n", .{error_return_trace});
//     vga.printf("{}\n", .{something});

//     // const first_trace_addr = @intFromPtr(@returnAddress());
//     // std.debug.panicExtra(error_return_trace, first_trace_addr, "{}", msg);

//     while (true) {}
// }
