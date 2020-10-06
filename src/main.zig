const psp = @import("Zig-PSP/src/psp/utils/psp.zig");
const gfx = @import("gfx.zig");

comptime {
    asm(psp.module_info("zTetris", 0, 1, 0));
}

//Tetris board
const tetris_columns : u32 = 10;
const tetris_rows : u32 = 24;

const bg_color : u32 = 0xffffeecc;
const board_color : u32 = 0xff111111;
const outline_color : u32 = 0xff333333;

const block_side : u32 = 16;

const pieceData : [7][4][16]u8 = [7][4][16]u8{
    //Line
    [4][16]u8{
        [_]u8{
            0,0,0,0,
            1,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,1,0,
            0,0,1,0,
            0,0,1,0,
            0,0,1,0,
        },
        [_]u8{
            0,0,0,0,
            0,0,0,0,
            1,1,1,1,
            0,0,0,0,
        },
        [_]u8{
            0,1,0,0,
            0,1,0,0,
            0,1,0,0,
            0,1,0,0,
        }
    },
    //Square
    [4][16]u8{
        [_]u8{
            1,1,0,0,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            1,1,0,0,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            1,1,0,0,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            1,1,0,0,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        }
    },
    //T
    [4][16]u8{
        [_]u8{
        0,1,0,0,
        1,1,1,0,
        0,0,0,0,
        0,0,0,0,
        },
        [_]u8{
        0,1,0,0,
        0,1,1,0,
        0,1,0,0,
        0,0,0,0,
        },
        [_]u8{
        0,0,0,0,
        1,1,1,0,
        0,1,0,0,
        0,0,0,0,
        },
        [_]u8{
        0,1,0,0,
        1,1,0,0,
        0,1,0,0,
        0,0,0,0,
        },
    },

    //Z 
    [4][16]u8{
        [_]u8{
            1,1,0,0,
            0,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,1,0,
            0,1,1,0,
            0,1,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,0,0,
            1,1,0,0,
            0,1,1,0,
            0,0,0,0,
        },
        [_]u8{
            0,1,0,0,
            1,1,0,0,
            1,0,0,0,
            0,0,0,0,
        }
    },

    //Zr
    [4][16]u8{    
        [_]u8{
            0,1,1,0,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,1,0,0,
            0,1,1,0,
            0,0,1,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,0,0,
            0,1,1,0,
            1,1,0,0,
            0,0,0,0,
        },
        [_]u8{
            1,0,0,0,
            1,1,0,0,
            0,1,0,0,
            0,0,0,0,
        }
    },

    //L
    [4][16]u8 {
        [_]u8{
            1,0,0,0,
            1,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,1,1,0,
            0,1,0,0,
            0,1,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,0,0,
            1,1,1,0,
            0,0,1,0,
            0,0,0,0,
        },
        [_]u8{
            0,1,0,0,
            0,1,0,0,
            1,1,0,0,
            0,0,0,0,
        }
    },
    //Lr
    [4][16]u8{
        [_]u8{
            0,0,1,0,
            1,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            0,1,0,0,
            0,1,0,0,
            0,1,1,0,
            0,0,0,0,
        },
        [_]u8{
            0,0,0,0,
            1,1,1,0,
            1,0,0,0,
            0,0,0,0,
        },
        [_]u8{
            1,1,0,0,
            0,1,0,0,
            0,1,0,0,
            0,0,0,0,
        }
    }
};

const colorArray : [8]u32 = [_]u32{
    0xFFFFFFFF,
    0xFF777777,
    0xFF0000FF,
    0xFF00FFFF,
    0xFF00FF00,
    0xFFFFFF00,
    0xFFFF0000,
    0xFFFF00FF,
};

pub const PieceType = enum(u8) {
    Line = 0,
    Square = 1,
    T = 2,
    Z = 3,
    Zr = 4,
    L = 5,
    Lr = 6,
};

pub const Block = struct{
    x: usize,
    y: usize,
    color: u32,
};

pub const Piece = struct{
    x: usize, 
    y: usize,
    orietation: usize,
    ptype: PieceType,
    block: [4]Block,
    count: usize,
};

pub var activePiece : Piece = undefined;

var grid : [tetris_columns][tetris_rows]u32 = undefined;

fn initBlocks() void{
    var i : usize = 0;
    while(i < tetris_rows) : (i += 1){
        var j : usize = 0;
        while(j < tetris_columns) : (j += 1){
            grid[j][i] = 0xff111111;
        }
    }
}

fn drawLogo() void{
    gfx.print(16, 8, "T", 0xFF0000FF);
    gfx.print(16, 8 + 32*1, "E", 0xFF00FFFF);
    gfx.print(16, 8 + 32*2, "T", 0xFF00FF00);
    gfx.print(16, 8 + 32*3, "R", 0xFFFFFF00);
    gfx.print(16, 8 + 32*4, "I", 0xFFFF0000);
    gfx.print(16, 8 + 32*5, "S", 0xFFFF00FF);
}


fn drawBlock(x : usize, y : usize) void{
    gfx.drawRect(24 + x * block_side, 24 + y * block_side, block_side, block_side, 0xFF000000);
    gfx.drawRect(26 + x * block_side, 26 + y * block_side, block_side - 4, block_side - 4, grid[y][x]);
}

fn drawBlockCol(x : usize, y : usize, color : u32) void{
    gfx.drawRect(24 + x * block_side, 24 + y * block_side, block_side, block_side, 0xFF000000);
    gfx.drawRect(26 + x * block_side, 26 + y * block_side, block_side - 4, block_side - 4, color);
}

fn drawBlocks() void {
    var i : usize = 0;
    while(i < tetris_rows) : (i += 1){
        var j : usize = 0;
        while(j < tetris_columns) : (j += 1){
            drawBlock(i, j);
        }
    }
}

fn drawPiece() void {
    var i : usize = 0;
    while(i < 4) : (i += 1){
        drawBlockCol(activePiece.block[i].y + activePiece.y, activePiece.block[i].x + activePiece.x, activePiece.block[i].color);
    }
}


const std = @import("std");
var r = std.rand.DefaultPrng.init(0);

fn newPiece() void {
    activePiece.ptype = @intToEnum(PieceType, r.random.uintLessThanBiased(u8, 7));
    activePiece.x = 0;
    activePiece.y = 20;
    activePiece.count = 0;
    activePiece.orietation = r.random.uintLessThanBiased(u8, 4);

    var color : usize = r.random.uintLessThanBiased(usize, 8);

    var i : usize = 0;
    while(i < 16) : (i += 1){
        if(pieceData[@enumToInt(activePiece.ptype)][activePiece.orietation][i] != 0){
            var x : usize = i % 4;
            var y : usize = i / 4;

            activePiece.block[activePiece.count].x = x;
            activePiece.block[activePiece.count].y = y;
            activePiece.block[activePiece.count].color = colorArray[color];
            activePiece.count += 1;
        }
    }
}

pub fn main() !void {
    psp.utils.enableHBCB();
    gfx.init();

    initBlocks();
    grid[9][23] = 0xFFFF_FFFF;
    newPiece();

    while(true){
        //Clear screen
        gfx.clear(bg_color);

        //Draw logo
        drawLogo();

        //Draw outline
        gfx.drawRect(16, 16, (tetris_rows+1) * block_side, (tetris_columns+1) * block_side, outline_color);

        //Draw board
        drawBlocks();
        drawPiece();

        gfx.swapBuffers();
    }
}
