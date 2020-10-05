usingnamespace @import("Zig-PSP/src/psp/include/pspge.zig");
usingnamespace @import("Zig-PSP/src/psp/include/psputils.zig");
usingnamespace @import("Zig-PSP/src/psp/utils/psp.zig");
usingnamespace @import("Zig-PSP/src/psp/include/pspdisplay.zig");

var draw_buffer: ?[*]u32 = null;
var disp_buffer: ?[*]u32 = null;

pub fn init() void{
    draw_buffer = @intToPtr(?[*]u32, @ptrToInt(sceGeEdramGetAddr()));
    disp_buffer = @intToPtr(?[*]u32, @ptrToInt(sceGeEdramGetAddr()) + (272 * SCR_BUF_WIDTH * 4));

    _ = sceDisplaySetMode(0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _ = sceDisplaySetFrameBuf(disp_buffer, SCR_BUF_WIDTH, @enumToInt(PspDisplayPixelFormats.Format8888), 1);
}

pub fn drawRect(x : usize, y : usize, w : usize, h : usize, color : u32) void{
    var x0 = x;
    var y0 = y;
    var w0 = w;
    var h0 = h;

    if(x0 > 480){
        x0 = 480;
    }

    if(y0 > 272){
        y0 = 272;
    }

    if( (x0 + w0) > 480){
        w0 = 480 - x0;
    }

    if( (y0 + h0) > 272){
        h0 = 272 - y0;
    }

    var off : usize = x0 + (y0 * SCR_BUF_WIDTH);

    var y1 : usize = 0;    
    while(y1 < h0) : (y1 += 1){
        var x1 : usize = 0;
        while(x1 < w0) : (x1 += 1){
           draw_buffer.?[x1 + off + y1 * SCR_BUF_WIDTH] = color;
        }
    }

}

pub fn swapBuffers() void{
    var temp : ?[*]u32 = disp_buffer;
    disp_buffer = draw_buffer;
    draw_buffer = temp;

    sceKernelDcacheWritebackInvalidateAll();
    _ = sceDisplaySetFrameBuf(disp_buffer, SCR_BUF_WIDTH, @enumToInt(PspDisplayPixelFormats.Format8888), @enumToInt(PspDisplaySetBufSync.Nextframe));
}

pub fn clear(color : u32) void {
    var i: usize = 0;
    while (i < SCR_BUF_WIDTH * SCREEN_HEIGHT) : (i += 1) {
        draw_buffer.?[i] = color;
    }
}

//Print out a constant string
pub fn print(x : u32, y : u32, text: []const u8, color: u32) void {
    var i : usize = 0;
    while(i < text.len) : (i += 1){
        internal_putchar(@as(u32,x), @as(u32,y+i*32), text[i], color);        
    }
}

const dbg = @import("Zig-PSP/src/psp/utils/debug.zig");

fn internal_putchar(cx: u32, cy: u32, ch: u8, color : u32) void{
    var off : usize = (511 - cx) + (cy * SCR_BUF_WIDTH);
    
    var i : usize = 0;
    while (i < 32) : (i += 1){
        
        var j: usize = 0;

        while(j < 32) : (j += 1){

            const mask : u32 = 128;

            var idx : u32 = @as(u32, ch - 32) * 8 + j / 4;
            var glyph : u8 = dbg.msxFont[idx];
            
            if( (glyph & (mask >> @intCast(@import("std").math.Log2Int(c_int), i/4))) != 0 ){
                draw_buffer.?[(480 - j) + (i) * SCR_BUF_WIDTH + off] = color;
            }

        }
    }

}
