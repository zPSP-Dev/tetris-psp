const psp = @import("Zig-PSP/src/psp/utils/psp.zig");
const gfx = @import("gfx.zig");

comptime {
    asm(psp.module_info("zTetris", 0, 1, 0));
}

//Tetris board
const tetris_columns : u32 = 10;
const tetris_rows : u32 = 24;

const bg_color : u32 = 0xffffeecc;
const board_color : u32 = 0xff000000;
const outline_color : u32 = 0xff333333;

fn drawLogo() void{
    gfx.print(16, 4, "T", 0xFF0000FF);
    gfx.print(16, 4 + 32*1, "E", 0xFF00FFFF);
    gfx.print(16, 4 + 32*2, "T", 0xFF00FF00);
    gfx.print(16, 4 + 32*3, "R", 0xFFFFFF00);
    gfx.print(16, 4 + 32*4, "I", 0xFFFF0000);
    gfx.print(16, 4 + 32*5, "S", 0xFFFF00FF);
}

pub fn main() !void {
    psp.utils.enableHBCB();
    gfx.init();

    while(true){
        //Clear screen
        gfx.clear(bg_color);

        //Draw logo
        drawLogo();

        //Draw outline
        gfx.drawRect(16, 16, tetris_rows * 16, tetris_columns * 16, outline_color);
        //Draw board
        gfx.drawRect(24, 24, (tetris_rows -1) * 16, (tetris_columns - 1) * 16, board_color);

        gfx.swapBuffers();
    }
}
