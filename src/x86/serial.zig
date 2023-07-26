const PortU8 = @import("port.zig").PortU8;

// TODO: Send and receive functions: https://github.com/rust-osdev/uart_16550/blob/master/src/port.rs
pub const SerialPort = struct {
    base: u16,

    pub fn init(base: u16) SerialPort {
        var self: SerialPort = .{ .base = base };
        // Disable interrupts
        self.int_en().write(0x00);
        // Enable DLAB
        self.line_ctrl().write(0x80);
        // Set maximum speed to 38400 bps by configuring DLL and DLM
        self.data().write(0x03);
        self.int_en().write(0x00);
        // Disable DLAB and set data word length to 8 bits
        self.line_ctrl().write(0x03);
        // Enable FIFO, clear TX/RX queues and
        // set interrupt watermark at 14 bytes
        self.fifo_ctrl().write(0xC7);
        // Mark data terminal ready, signal request to send
        // and enable auxilliary output #2 (used as interrupt line for CPU)
        self.modem_ctrl().write(0x0B);
        // Enable interrupts
        self.int_en().write(0x01);
        return self;
    }

    // Read/Write
    pub inline fn data(self: *SerialPort) PortU8 {
        return PortU8.init(self.base);
    }

    // Write only
    pub inline fn int_en(self: *SerialPort) PortU8 {
        return PortU8.init(self.base + 1);
    }

    // Write only
    pub inline fn fifo_ctrl(self: *SerialPort) PortU8 {
        return PortU8.init(self.base + 2);
    }

    // Write only
    pub inline fn line_ctrl(self: *SerialPort) PortU8 {
        return PortU8.init(self.base + 3);
    }

    // Write only
    pub inline fn modem_ctrl(self: *SerialPort) PortU8 {
        return PortU8.init(self.base + 4);
    }

    // Read only
    pub inline fn line_sts(self: *SerialPort) PortU8 {
        return PortU8.init(self.base + 5);
    }
};
