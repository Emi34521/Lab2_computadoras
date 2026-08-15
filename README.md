# Lab2_computadoras# Conway's Game of Life

Implementación de Conway's Game of Life en Zig + raylib.

## Cómo correrlo

```
zig build run
```

## Reglas

1. Célula viva con menos de 2 vecinos vivos → muere.
2. Célula viva con 2 o 3 vecinos vivos → sobrevive.
3. Célula viva con más de 3 vecinos vivos → muere.
4. Célula muerta con exactamente 3 vecinos vivos → nace.

## Demo

![Game of Life corriendo](prueba.gif)
