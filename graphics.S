/*
 * graphics.S
 * Rutinas gráficas para Frogger
 *
 * Framebuffer SSD1306:
 * 128 x 64 pixels
 * 1024 bytes
 */

.syntax unified
.cpu cortex-m3
.thumb

.extern framebuffer

.global clear_buffer
.global draw_pixel
.global draw_sprite8x8
.global frog_sprite

.global draw_hline


/* ============================================================
 * SPRITE DE LA RANITA - 8x8 pixels
 *
 * Cada byte representa una fila.
 *
 * ..#..#..
 * .######.
 * ##.##.##
 * ########
 * .######.
 * ..####..
 * .##..##.
 * ##....##
 * ============================================================ */

.section .rodata
.align 2

frog_sprite:

    .byte 0x24
    .byte 0x7E
    .byte 0xDB
    .byte 0xFF
    .byte 0x7E
    .byte 0x3C
    .byte 0x66
    .byte 0xC3


/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ============================================================
 * clear_buffer
 *
 * Limpia los 1024 bytes del framebuffer.
 * ============================================================ */

.type clear_buffer, %function
.thumb_func

clear_buffer:

    push {r4-r6, lr}

    ldr  r4, =framebuffer

    /* 1024 bytes / 4 = 256 palabras */
    movw r5, #256

    movs r6, #0


clear_loop:

    str  r6, [r4]

    adds r4, r4, #4

    subs r5, r5, #1

    bne clear_loop


    pop {r4-r6, pc}



/* ============================================================
 * draw_pixel
 *
 * Dibuja o borra un pixel.
 *
 * Entrada:
 *
 * r0 = X       (0 - 127)
 * r1 = Y       (0 - 63)
 * r2 = color   (0 = negro, 1 = blanco)
 *
 *
 * SSD1306 organiza la memoria así:
 *
 * byte = X + (Y / 8) * 128
 *
 * bit  = Y mod 8
 * ============================================================ */

.type draw_pixel, %function
.thumb_func

draw_pixel:

    push {r3-r7, lr}

    /* Guardamos color */
    mov r7, r2


    /* ----------------------------------
     * Verificar límites
     * ---------------------------------- */

    cmp r0, #127
    bhi pixel_end

    cmp r1, #63
    bhi pixel_end


    /* ----------------------------------
     * Calcular página:
     *
     * page = Y / 8
     * ---------------------------------- */

    lsrs r4, r1, #3


    /* ----------------------------------
     * page * 128
     * ---------------------------------- */

    lsls r4, r4, #7


    /* ----------------------------------
     * offset = page*128 + X
     * ---------------------------------- */

    adds r4, r4, r0


    /* ----------------------------------
     * Dirección framebuffer[offset]
     * ---------------------------------- */

    ldr r5, =framebuffer

    adds r5, r5, r4


    /* ----------------------------------
     * bit = Y % 8
     * ---------------------------------- */

    mov r6, r1

    movs r3, #7

    ands r6, r3


    /* ----------------------------------
     * máscara = 1 << bit
     * ---------------------------------- */

    movs r4, #1

    lsls r4, r4, r6


    /* Leer byte actual */
    ldrb r6, [r5]


    /* ¿Encender o borrar? */

    cmp r7, #0

    beq pixel_clear


/* Encender pixel */

    orrs r6, r6, r4

    b pixel_store


pixel_clear:

    bics r6, r6, r4


pixel_store:

    strb r6, [r5]


pixel_end:

    pop {r3-r7, pc}



/* ============================================================
 * draw_sprite8x8
 *
 * Dibuja un sprite monocromático de 8x8.
 *
 * Entrada:
 *
 * r0 = X
 * r1 = Y
 * r2 = dirección del sprite
 *
 * El sprite consta de 8 bytes:
 * 1 byte = 1 fila.
 * ============================================================ */

.type draw_sprite8x8, %function
.thumb_func

draw_sprite8x8:

    push {r3-r7, lr}


    /* Coordenada inicial X */
    mov r4, r0

    /* Coordenada inicial Y */
    mov r5, r1

    /* Dirección del sprite */
    mov r6, r2

    /* fila = 0 */
    movs r7, #0


sprite_row_loop:

    /* Obtener byte de esta fila */

    ldrb r2, [r6, r7]


    /* columna = 0 */

    movs r3, #0


sprite_col_loop:

    /* Máscara empezando por bit 7 */

    movs r0, #0x80

    lsrs r0, r0, r3


    /* ¿Está encendido este pixel? */

    tst r2, r0

    beq sprite_skip_pixel


    /*
     * Guardamos r2 y r3 porque draw_pixel
     * puede modificarlos.
     */

    push {r2, r3}


    /* X = baseX + columna */

    adds r0, r4, r3


    /* Y = baseY + fila */

    adds r1, r5, r7


    /* blanco */

    movs r2, #1


    bl draw_pixel


    pop {r2, r3}


sprite_skip_pixel:

    adds r3, r3, #1

    cmp r3, #8

    blt sprite_col_loop


    /* siguiente fila */

    adds r7, r7, #1

    cmp r7, #8

    blt sprite_row_loop


    pop {r3-r7, pc}

/* ============================================================
 * draw_hline
 *
 * Línea horizontal.
 *
 * Entrada:
 *   r0 = X inicial
 *   r1 = Y
 *   r2 = longitud
 *   r3 = color
 * ============================================================ */

.type draw_hline, %function
.thumb_func

draw_hline:

    /*
     * 6 registros = 24 bytes
     * Stack alineado a 8 bytes
     */

    push {r3-r7, lr}

    /* X */
    mov r4, r0

    /* Y */
    mov r5, r1

    /* longitud */
    mov r6, r2

    /* color */
    mov r7, r3


hline_loop:

    cmp r6, #0
    beq hline_end


    mov r0, r4
    mov r1, r5
    mov r2, r7

    bl draw_pixel


    adds r4, r4, #1

    subs r6, r6, #1

    b hline_loop


hline_end:
    pop {r3-r7, pc}