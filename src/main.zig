const std = @import("std");
const rl = @import("raylib");
const fb = @import("framebuffer.zig");

// confirguración
// Resolución interna baja, como recomienda el enunciado, para poder
// apreciar bien el patrón inicial y que la simulación corra rápido.
// Sin tipo explícito (comptime_int) a propósito así el mismo valor sirve
// tanto para aritmética en i32 (coordenadas) como para el tamaño de
// arreglos, que Zig exige en usize.
const GRID_WIDTH = 140;
const GRID_HEIGHT = 100;

// Cada celda se dibuja como un bloque de CELL_SCALE x CELL_SCALE píxeles en
// la ventana real, para que un framebuffer chico se vea bien en una ventana
// grande.
const CELL_SCALE = 7;
const WINDOW_WIDTH = GRID_WIDTH * CELL_SCALE;
const WINDOW_HEIGHT = GRID_HEIGHT * CELL_SCALE;

// Cuántas generaciones avanza el juego por segundo. La ventana
// sigue corriendo a 60 FPS; solo la lógica de Conway avanza más despacio
// para poder ver bien la animación.
const GENERATIONS_PER_SECOND: f32 = 12.0;

const ALIVE_COLOR = rl.Color.init(0, 200, 130, 255); // verde quetzal
const DEAD_COLOR = rl.Color.init(12, 14, 20, 255);

// Buffer temporal (no es un framebuffer, es solo un arreglo de trabajo) para
// calcular la siguiente generación completa antes de pintar nada. Si
// pintáramos directo sobre el framebuffer mientras todavía estamos contando
// vecinos, dañaríamos el conteo de las celdas que faltan por procesar en ese
// mismo turno.
var next_state: [GRID_HEIGHT][GRID_WIDTH]bool = undefined;

fn colorsEqual(a: rl.Color, b: rl.Color) bool {
    return a.r == b.r and a.g == b.g and a.b == b.b;
}

fn isAlive(framebuffer: *fb.Framebuffer, x: i32, y: i32) bool {
    return colorsEqual(framebuffer.get_color(x, y), ALIVE_COLOR);
}

// Cuenta los 8 vecinos de una celda. Las orillas del mundo estánpegadas
// si te sales por la derecha, reapareces por la
// izquierda, y lo mismo arriba/abajo. Esto da patrones más interesantes

fn countAliveNeighbors(framebuffer: *fb.Framebuffer, x: i32, y: i32) u8 {
    var count: u8 = 0;
    var dy: i32 = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: i32 = -1;
        while (dx <= 1) : (dx += 1) {
            if (dx == 0 and dy == 0) continue;
            const nx = @mod(x + dx + GRID_WIDTH, GRID_WIDTH);
            const ny = @mod(y + dy + GRID_HEIGHT, GRID_HEIGHT);
            if (isAlive(framebuffer, nx, ny)) count += 1;
        }
    }
    return count;
}

// El algoritmo de Conway completo. Usa únicamente `point` (para pintar) y
// get_color (para leer el estado actual) del framebuffer
// No se limpia el framebuffer antes como aquí se pinta cada
// celda (viva o muerta) en cada turno, el frame anterior queda cubierto
// solo.
fn render(framebuffer: *fb.Framebuffer) void {
    var y: i32 = 0;
    while (y < GRID_HEIGHT) : (y += 1) {
        var x: i32 = 0;
        while (x < GRID_WIDTH) : (x += 1) {
            const alive = isAlive(framebuffer, x, y);
            const neighbors = countAliveNeighbors(framebuffer, x, y);

            // Las 4 reglas de Conway:
            const will_be_alive =
                (alive and (neighbors == 2 or neighbors == 3)) or // sobrevive
                (!alive and neighbors == 3); // reproducción
            // menos de 2 vecinos o más de 3 muere / sigue muerta, que es
            // simplemente el caso false de arriba

            next_state[@intCast(y)][@intCast(x)] = will_be_alive;
        }
    }

    y = 0;
    while (y < GRID_HEIGHT) : (y += 1) {
        var x: i32 = 0;
        while (x < GRID_WIDTH) : (x += 1) {
            const alive = next_state[@intCast(y)][@intCast(x)];
            framebuffer.point(x, y, if (alive) ALIVE_COLOR else DEAD_COLOR);
        }
    }
}

fn placeCells(framebuffer: *fb.Framebuffer, cells: []const [2]i32, offset_x: i32, offset_y: i32) void {
    for (cells) |cell| {
        framebuffer.point(offset_x + cell[0], offset_y + cell[1], ALIVE_COLOR);
    }
}

// Dos Gosper Glider Guns (una normal y otra rotada 180°) en esquinas
// opuestas del tablero, disparando planeadores en direcciones contrarias
// que terminan cruzándose por toda la pantalla (y con el wraparound de las
// orillas, la cosa se pone todavía más caótica con el tiempo). Dos púlsares
// laten como "estrellas" fijas en las otras dos esquinas, y tres naves
// ligeras cruzan por el centro para darle vida al arranque.

const gun1 = [_][2]i32{
    .{ 24, 0 }, .{ 22, 1 }, .{ 24, 1 }, .{ 12, 2 }, .{ 13, 2 }, .{ 20, 2 }, .{ 21, 2 }, .{ 34, 2 }, .{ 35, 2 },
    .{ 11, 3 }, .{ 15, 3 }, .{ 20, 3 }, .{ 21, 3 }, .{ 34, 3 }, .{ 35, 3 }, .{ 0, 4 },  .{ 1, 4 },  .{ 10, 4 },
    .{ 16, 4 }, .{ 20, 4 }, .{ 21, 4 }, .{ 0, 5 },  .{ 1, 5 },  .{ 10, 5 }, .{ 14, 5 }, .{ 16, 5 }, .{ 17, 5 },
    .{ 22, 5 }, .{ 24, 5 }, .{ 10, 6 }, .{ 16, 6 }, .{ 24, 6 }, .{ 11, 7 }, .{ 15, 7 }, .{ 12, 8 }, .{ 13, 8 },
};

const gun2 = [_][2]i32{
    .{ 0, 5 },  .{ 0, 6 },  .{ 1, 5 },  .{ 1, 6 },  .{ 11, 2 }, .{ 11, 3 }, .{ 11, 7 }, .{ 11, 8 }, .{ 13, 3 },
    .{ 13, 7 }, .{ 14, 4 }, .{ 14, 5 }, .{ 14, 6 }, .{ 15, 4 }, .{ 15, 5 }, .{ 15, 6 }, .{ 18, 3 }, .{ 19, 2 },
    .{ 19, 3 }, .{ 19, 4 }, .{ 20, 1 }, .{ 20, 5 }, .{ 21, 3 }, .{ 22, 0 }, .{ 22, 6 }, .{ 23, 0 }, .{ 23, 6 },
    .{ 24, 1 }, .{ 24, 5 }, .{ 25, 2 }, .{ 25, 3 }, .{ 25, 4 }, .{ 34, 3 }, .{ 34, 4 }, .{ 35, 3 }, .{ 35, 4 },
};

const pulsar = [_][2]i32{
    .{ 0, 2 },  .{ 0, 3 },  .{ 0, 4 },   .{ 0, 8 },  .{ 0, 9 },  .{ 0, 10 },  .{ 2, 0 },  .{ 2, 5 },  .{ 2, 7 },
    .{ 2, 12 }, .{ 3, 0 },  .{ 3, 5 },   .{ 3, 7 },  .{ 3, 12 }, .{ 4, 0 },   .{ 4, 5 },  .{ 4, 7 },  .{ 4, 12 },
    .{ 5, 2 },  .{ 5, 3 },  .{ 5, 4 },   .{ 5, 8 },  .{ 5, 9 },  .{ 5, 10 },  .{ 7, 2 },  .{ 7, 3 },  .{ 7, 4 },
    .{ 7, 8 },  .{ 7, 9 },  .{ 7, 10 },  .{ 8, 0 },  .{ 8, 5 },  .{ 8, 7 },   .{ 8, 12 }, .{ 9, 0 },  .{ 9, 5 },
    .{ 9, 7 },  .{ 9, 12 }, .{ 10, 0 },  .{ 10, 5 }, .{ 10, 7 }, .{ 10, 12 }, .{ 12, 2 }, .{ 12, 3 }, .{ 12, 4 },
    .{ 12, 8 }, .{ 12, 9 }, .{ 12, 10 },
};

const lwss = [_][2]i32{
    .{ 1, 0 }, .{ 4, 0 }, .{ 0, 1 }, .{ 0, 2 }, .{ 4, 2 }, .{ 0, 3 }, .{ 1, 3 }, .{ 2, 3 }, .{ 3, 3 },
};

fn setupInitialPattern(framebuffer: *fb.Framebuffer) void {
    // Cañón 1: esquina superior izquierda, dispara hacia el sureste.
    placeCells(framebuffer, &gun1, 4, 4);
    // Cañón 2: esquina inferior derecha, dispara hacia el noroeste.
    placeCells(framebuffer, &gun2, GRID_WIDTH - 4 - 36, GRID_HEIGHT - 4 - 9);

    // Púlsares en las otras dos esquinas.
    placeCells(framebuffer, &pulsar, GRID_WIDTH - 13 - 6, 6);
    placeCells(framebuffer, &pulsar, 6, GRID_HEIGHT - 13 - 6);

    // Naves ligeras cruzando el centro.
    placeCells(framebuffer, &lwss, 40, 48);
    placeCells(framebuffer, &lwss, 60, 52);
    placeCells(framebuffer, &lwss, 80, 48);
}

pub fn main(init: std.process.Init) !void {
    _ = init;

    var framebuffer = fb.Framebuffer.init(GRID_WIDTH, GRID_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, DEAD_COLOR);

    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Conway's Game of Life - Danza de Planeadores");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    setupInitialPattern(&framebuffer);

    const step_interval: f32 = 1.0 / GENERATIONS_PER_SECOND;
    var time_accumulator: f32 = 0;

    while (!rl.windowShouldClose()) {
        time_accumulator += rl.getFrameTime();
        if (time_accumulator >= step_interval) {
            time_accumulator -= step_interval;
            render(&framebuffer);
        }

        try framebuffer.swap();
    }
}
