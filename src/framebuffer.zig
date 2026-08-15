const rl = @import("raylib");

/// Representa un pixel del framebuffer en coordenadas de "mundo" (bajas,
/// tipo 100x100), no en coordenadas de ventana.
pub const Point = struct {
    x: f32,
    y: f32,
};

pub const Framebuffer = struct {
    // Resolución interna del framebuffer (la resolución "del juego").
    width: i32,
    height: i32,

    // Resolución de la ventana real donde se presenta el framebuffer ya
    // escalado. Puede ser (y normalmente es) más grande que width/height.
    window_width: i32,
    window_height: i32,

    image: rl.Image,
    texture: ?rl.Texture,
    background_color: rl.Color,

    pub fn init(width: i32, height: i32, window_width: i32, window_height: i32, color: rl.Color) Framebuffer {
        return Framebuffer{
            .width = width,
            .height = height,
            .window_width = window_width,
            .window_height = window_height,
            .image = rl.genImageColor(width, height, color),
            .background_color = color,
            .texture = null,
        };
    }

    /// La función "point": pinta un solo pixel del framebuffer de un color.
    /// Es la única primitiva de dibujo que usamos para implementar Conway.
    pub fn point(self: *Framebuffer, x: i32, y: i32, color: rl.Color) void {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) return;
        self.image.drawPixel(x, y, color);
    }

    /// Complemento de `point`: devuelve el color actual de una celda. Con
    /// esto el estado del juego (viva/muerta) vive directamente en el
    /// framebuffer -- no necesitamos un arreglo de booleanos aparte para
    /// saber si una celda está viva.
    pub fn get_color(self: *Framebuffer, x: i32, y: i32) rl.Color {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) {
            return self.background_color;
        }
        return self.image.getColor(x, y);
    }

    pub fn clear(self: *Framebuffer) void {
        self.image.clearBackground(self.background_color);
    }

    /// Sube el framebuffer (chico) a una textura y la dibuja escalada para
    /// llenar toda la ventana (que puede ser bastante más grande). Usamos
    /// filtro "point" (vecino más cercano) para que se vea en bloques
    /// nítidos en vez de borroso.
    pub fn swap(self: *Framebuffer) !void {
        if (self.texture) |old_texture| {
            rl.unloadTexture(old_texture);
        }
        self.texture = try rl.loadTextureFromImage(self.image);
        rl.setTextureFilter(self.texture.?, .point);

        rl.beginDrawing();
        defer rl.endDrawing();

        const src = rl.Rectangle.init(0, 0, @floatFromInt(self.width), @floatFromInt(self.height));
        const dst = rl.Rectangle.init(0, 0, @floatFromInt(self.window_width), @floatFromInt(self.window_height));
        rl.drawTexturePro(self.texture.?, src, dst, .{ .x = 0, .y = 0 }, 0, .white);
    }
};
