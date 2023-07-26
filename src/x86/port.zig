pub const PortU8 = Port(u8);
pub const PortU16 = Port(u16);
pub const PortU32 = Port(u32);

pub fn Port(comptime T: type) type {
    const t_type = @TypeOf(T);
    if (t_type != u8 and t_type != u16 and t_type != u32) {
        @compileError("Port type must be one of: u8, u16, u32");
    }

    return struct {
        port: u16,

        const Self = @This();

        pub fn init(port: u16) Self {
            return .{ .port = port };
        }

        pub inline fn read(self: *Self) T {
            if (t_type == u8) {
                return read_u8(self.port);
            } else if (t_type == u16) {
                return read_u16(self.port);
            } else if (t_type == u32) {
                return read_u32(self.port);
            } else {
                unreachable;
            }
        }

        pub inline fn write(self: *Self, value: T) void {
            if (t_type == u8) {
                write_u8(self.port, value);
            } else if (t_type == u16) {
                write_u16(self.port, value);
            } else if (t_type == u32) {
                write_u32(self.port, value);
            } else {
                unreachable;
            }
        }
    };
}

fn read_u8(port: u16) u8 {
    return asm volatile ("in al, dx"
        : [ret] "={al}" (-> u8),
        : [port] "{dx}" (port),
    );
}

fn read_u16(port: u16) u16 {
    return asm volatile ("in ax, dx"
        : [ret] "={ax}" (-> u16),
        : [port] "{dx}" (port),
    );
}

fn read_u32(port: u16) u32 {
    return asm volatile ("in eax, dx"
        : [ret] "={eax}" (-> u8),
        : [port] "{dx}" (port),
    );
}

fn write_u8(port: u16, value: u8) void {
    asm volatile ("out dx, al"
        :
        : [port] "{dx}" (port),
          [value] "{al}" (value),
    );
}

fn write_u16(port: u16, value: u16) void {
    asm volatile ("out dx, ax"
        :
        : [port] "{dx}" (port),
          [value] "{ax}" (value),
    );
}

fn write_u32(port: u16, value: u32) void {
    asm volatile ("out dx, eax"
        :
        : [port] "{dx}" (port),
          [value] "{eax}" (value),
    );
}
