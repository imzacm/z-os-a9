// The code in this file is loosely copied/based on the Futex implementation of `std.Thread.Mutex`.

const std = @import("std");
const builtin = @import("builtin");
const Atomic = std.atomic.Atomic;

const UNLOCKED = 0b00;
const LOCKED = 0b01;

pub const LockError = error{
    Locked,
};

pub const UnlockError = error{
    NotLocked,
};

// TODO: Test multithreaded access.
test "Lock - single threaded" {
    var lock = Lock.init();
    try std.testing.expect(!lock.is_locked());

    var handle1 = lock.lock();
    try std.testing.expect(lock.is_locked());
    try std.testing.expectError(LockError.Locked, lock.try_lock());
    try handle1.release();
    try std.testing.expect(!lock.is_locked());

    var handle2 = try lock.try_lock();
    try std.testing.expect(lock.is_locked());
    try lock.unsafe_force_unlock();
    try std.testing.expect(!lock.is_locked());
    try std.testing.expectError(UnlockError.NotLocked, handle2.release());
}

pub const Lock = struct {
    state: Atomic(u32) = Atomic(u32).init(UNLOCKED),

    pub fn init() Lock {
        return .{};
    }

    pub inline fn is_locked(self: *Lock) bool {
        return self.state.load(.Monotonic) == LOCKED;
    }

    pub inline fn lock(self: *Lock) Handle {
        while (!try_lock_state(&self.state, "tryCompareAndSwap")) {
            // TODO: efficiently wait.
        }
        return .{ .state = self };
    }

    pub inline fn try_lock(self: *Lock) LockError!Handle {
        if (try_lock_state(&self.state, "compareAndSwap")) {
            return .{ .state = self };
        }
        return LockError.Locked;
    }

    // This is "unsafe" because it doesn't do any checks, it just returns a `Handle`.
    pub fn unsafe_create_handle(self: *Lock) Handle {
        return .{ .state = self };
    }

    // Locks the state if it's unlocked.
    pub inline fn unsafe_force_lock(self: *Lock) LockError!void {
        const prev_state = self.state.swap(LOCKED, .Release);
        if (prev_state == LOCKED) {
            return LockError.Locked;
        }
    }

    // Unlocks the state it's locked.
    pub inline fn unsafe_force_unlock(self: *Lock) UnlockError!void {
        // Unlock the mutex and wake up a waiting thread if any.
        //
        // A waiting thread will acquire with `contended` instead of `locked`
        // which ensures that it wakes up another thread on the next unlock().
        //
        // Release barrier ensures the critical section happens before we let go of the lock
        // and that our critical section happens before the next lock holder grabs the lock.
        const prev_state = self.state.swap(UNLOCKED, .Release);
        if (prev_state == UNLOCKED) {
            return UnlockError.NotLocked;
        }
    }
};

pub const Handle = struct {
    state: *Lock,

    pub fn guard(self: Handle, value: anytype) Guard(@TypeOf(value)) {
        return .{ .value = value, .handle = self };
    }

    pub fn release(self: Handle) UnlockError!void {
        return self.state.*.unsafe_force_unlock();
    }
};

pub fn Guard(comptime T: type) type {
    return struct {
        value: T,
        handle: Handle,
    };
}

// Returns true if state was successfully changed to locked.
inline fn try_lock_state(state: *Atomic(u32), comptime cas_fn_name: []const u8) bool {
    // On x86, use `lock bts` instead of `lock cmpxchg` as:
    // - they both seem to mark the cache-line as modified regardless: https://stackoverflow.com/a/63350048
    // - `lock bts` is smaller instruction-wise which makes it better for inlining
    if (comptime builtin.cpu.arch.isX86()) {
        const locked_bit = @ctz(@as(u32, LOCKED));
        return state.bitSet(locked_bit, .Acquire) == 0;
    }

    // Acquire barrier ensures grabbing the lock happens before the critical section
    // and that the previous lock holder's critical section happens before we grab the lock.
    const casFn = @field(@TypeOf(state.*), cas_fn_name);
    return casFn(state, UNLOCKED, LOCKED, .Acquire, .Monotonic) == null;
}
