const psp = @import("Zig-PSP/src/psp/utils/psp.zig");
const gfx = @import("gfx.zig");
usingnamespace @import("Zig-PSP/src/psp/include/psprtc.zig");
usingnamespace @import("Zig-PSP/src/psp/include/pspdisplay.zig");
usingnamespace @import("Zig-PSP/src/psp/include/psploadexec.zig");

var current_time : u64 = 0;
var tickRate : u32 = 0;

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
    x: i32,
    y: i32,
};

pub const Piece = struct{
    x: i32, 
    y: i32,
    orietation: usize,
    ptype: PieceType,
    block: [4]Block,
    count: usize,
    color: u32,
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

fn drawBlockCol(x : i32, y : i32, color : u32) void{
    gfx.drawRect(@intCast(u32, 24 + x * @intCast(i32, block_side)), @intCast(u32, 24 + y * @intCast(i32, block_side)), block_side, block_side, 0xFF000000);
    gfx.drawRect(@intCast(u32, 26 + x * @intCast(i32, block_side)), @intCast(u32, 26 + y * @intCast(i32, block_side)), block_side - 4, block_side - 4, color);
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
        drawBlockCol(activePiece.block[i].y + activePiece.y, activePiece.block[i].x + activePiece.x, activePiece.color);
    }
}


const std = @import("std");
var r = std.rand.DefaultPrng.init(0);

fn newPiece() void {
    activePiece.ptype = @intToEnum(PieceType, r.random.uintLessThanBiased(u8, 7));
    activePiece.x = 0;
    activePiece.y = 20;
    activePiece.count = 0;
    activePiece.orietation = 0;

    activePiece.color = colorArray[r.random.uintLessThanBiased(usize, 8)];

    var i : i32 = 0;
    while(i < 16) : (i += 1){
        if(pieceData[@enumToInt(activePiece.ptype)][activePiece.orietation][@intCast(usize, i)] != 0){
            var x : i32 = @rem(i, 4);
            var y : i32 = @divTrunc(i, 4);

            activePiece.block[activePiece.count].x = x;
            activePiece.block[activePiece.count].y = y;
            activePiece.count += 1;
        }
    }
}

fn rightWallCollided() bool {
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        if(activePiece.block[i].x + activePiece.x >= tetris_columns){
            return true;
        }
    }
    return false;
}

fn leftWallCollided() bool {
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        if(activePiece.block[i].x + activePiece.x < 0){
            return true;
        }
    }
    return false;
}

fn getCell(x : usize, y : usize) bool {
    if(y < 0 or y >= tetris_rows or x < 0 or x >= tetris_columns){
        return false;
    }
    return grid[x][y] != 0xff111111;
}

fn gridCollided() bool {
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        if(getCell(@intCast(usize, activePiece.x + activePiece.block[i].x), @intCast(usize, activePiece.y + activePiece.block[i].y))){
            return true;
        }
    }
    return false;
}


const control = @import("Zig-PSP/src/psp/include/pspctrl.zig");

var oldPadData : control.SceCtrlData = undefined;
var newPadData : control.SceCtrlData = undefined;
fn handleInput() void{
    oldPadData = newPadData;
    _ = control.sceCtrlReadBufferPositive(&newPadData, 1);

    if(oldPadData.Buttons != newPadData.Buttons){
        if(newPadData.Buttons & @bitCast(c_uint, @enumToInt(control.PspCtrlButtons.PSP_CTRL_UP)) != 0){
            activePiece.x -= 1;
            if(leftWallCollided() or gridCollided()){
                activePiece.x += 1;
            }
        }

        if(newPadData.Buttons & @bitCast(c_uint, @enumToInt(control.PspCtrlButtons.PSP_CTRL_DOWN)) != 0){
            activePiece.x += 1;
            if(rightWallCollided() or gridCollided()){
                activePiece.x -= 1;
            }
            //TODO: Grid Check
        }

        if(newPadData.Buttons & @bitCast(c_uint, @enumToInt(control.PspCtrlButtons.PSP_CTRL_LEFT)) != 0){
            activePiece.y -= 1;
        }

        if(newPadData.Buttons & @bitCast(c_uint, @enumToInt(control.PspCtrlButtons.PSP_CTRL_RIGHT)) != 0){
            rotate();
        }
    }
}

fn rotate() void{
    var blockBack: [4]Block = activePiece.block;

    activePiece.orietation += 1;
    activePiece.orietation %= 4;
    activePiece.count = 0;

    var i : i32 = 0;
    while(i < 16) : (i += 1){
        if(pieceData[@enumToInt(activePiece.ptype)][activePiece.orietation][@intCast(usize, i)] != 0){
            var x : i32 = @rem(i, 4);
            var y : i32 = @divTrunc(i, 4);

            activePiece.block[activePiece.count].x = x;
            activePiece.block[activePiece.count].y = y;
            activePiece.count += 1;
        }
    }

    if(leftWallCollided()){
        activePiece.x += 1;
        while(leftWallCollided()){
            activePiece.x += 1;
        }
    } 
    
    if(rightWallCollided()){
        activePiece.x -= 1;
        while(rightWallCollided()){
            activePiece.x -= 1;
        }
    }

    //TODO: GRID CHECK
}

fn bottomCollided() bool{
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        if(activePiece.block[i].y + activePiece.y < 0 or gridCollided()){
            return true;
        }
    }
    return false;
}

fn topCollided() bool{
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        if(activePiece.block[i].y + activePiece.y >= 20){
            return true;
        }
    }
    return false;
}

fn addPieceToBoard() void {
    var i : usize = 0;
    while(i < activePiece.count) : (i += 1){
        grid[@intCast(usize, activePiece.block[i].x + activePiece.x)][@intCast(usize, activePiece.block[i].y + activePiece.y)] = activePiece.color;
    }
}

fn checkRows() void {

    var y : usize = 0;
    while(y < tetris_rows) : (y += 1){
        var cleared : bool = true;
        var x : usize = 0;
        while(x < tetris_columns) : (x += 1){
            if(grid[x][y] == 0xff111111){
                cleared = false;
                break;
            }
        }

        if(cleared){
            //We clear this line and above

            var i : usize = y;
            //I is this line
            while(i < (tetris_rows-4)) : (i += 1){
                var j : usize = 0;
                while(j < tetris_columns) : (j += 1){
                    grid[j][i] = grid[j][i + 1];
                }
            }

        }
    }
}

pub fn main() !void {
    oldPadData.Buttons = 0;
    newPadData.Buttons = 0;
    psp.utils.enableHBCB();
    gfx.init();

    _ = control.sceCtrlSetSamplingCycle(0);
    _ = control.sceCtrlSetSamplingMode(@enumToInt(control.PspCtrlMode.PSP_CTRL_MODE_ANALOG));

    initBlocks();
    
    tickRate = sceRtcGetTickResolution();
    _ = sceRtcGetCurrentTick(&current_time);
    r = std.rand.DefaultPrng.init(current_time);
    newPiece();
    
    var timer : f64 = 0.0;

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

        var oldTime = current_time;
        _ = sceRtcGetCurrentTick(&current_time);
        var delta = current_time - oldTime;
        var deltaF = @intToFloat(f64, delta) / @intToFloat(f64, tickRate);

        timer += deltaF;
        if(timer > 0.5){
            timer = 0.0;
            //Tick
            activePiece.y -= 1;
        }

        handleInput();
        
        if(bottomCollided()){
            activePiece.y += 1;
            if(topCollided()){
                sceKernelExitGame();
            }else{
                addPieceToBoard();
                newPiece();
            }
        }

        checkRows();

        gfx.swapBuffers();
        _ = sceDisplayWaitVblankStart();
    }
}
