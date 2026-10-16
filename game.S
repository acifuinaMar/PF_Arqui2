/*
 * game.S
 *
 * Primera versión del mundo de Frogger.
 *
 * - carreteras
 * - tres vehículos
 * - movimiento automático
 */

.syntax unified
.cpu cortex-m3
.thumb


.extern draw_sprite8x8
.extern draw_hline

.extern framebuffer
.extern draw_dashed_hline

.global game_init
.global game_update
.global game_draw

.global level

/* ============================================================
 * SPRITE AUTO 8x8
 * ============================================================ */
/* ============================================================
 * CARRO HACIA LA DERECHA
 * ============================================================ */

car_right_sprite:

    .byte 0x00
    .byte 0x1C
    .byte 0x3E
    .byte 0x7F
    .byte 0xFF
    .byte 0xDB
    .byte 0x42
    .byte 0x00


/* ============================================================
 * CARRO HACIA LA IZQUIERDA
 * ============================================================ */

car_left_sprite:

    .byte 0x00
    .byte 0x38
    .byte 0x7C
    .byte 0xFE
    .byte 0xFF
    .byte 0xDB
    .byte 0x42
    .byte 0x00


/* ============================================================
 * ESTADO DEL JUEGO
 * ============================================================ */
.global car1_x
.global car2_x
.global car3_x
.global score

.section .data
.align 4

score:
    .word 0

level:
    .word 0

car1_x:
    .word 0

car2_x:
    .word 96

car3_x:
    .word 40



/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ============================================================
 * game_init
 * ============================================================ */

.type game_init, %function
.thumb_func

game_init:

     /* Score inicial = 0 */

    ldr r0, =score
    movs r1, #0
    str r1, [r0]

    /* Nivel = 0 */

    ldr r0, =level
    movs r1, #0
    str r1, [r0]

    ldr r0, =car1_x
    movs r1, #0
    str r1, [r0]

    ldr r0, =car2_x
    movs r1, #96
    str r1, [r0]

    ldr r0, =car3_x
    movs r1, #40
    str r1, [r0]

    bx lr

/* ============================================================
 * game_update
 *
 * Velocidad según dificultad:
 *
 * NIVEL 0:
 *   car1 = 2 px/frame
 *   car2 = 1 px/frame
 *   car3 = 1 px/frame
 *
 * NIVEL 1:
 *   car1 = 3 px/frame
 *   car2 = 2 px/frame
 *   car3 = 2 px/frame
 *
 * NIVEL 2:
 *   car1 = 4 px/frame
 *   car2 = 3 px/frame
 *   car3 = 3 px/frame
 * ============================================================ */

.type game_update, %function
.thumb_func

game_update:

    push {r4-r6, lr}


    /* ========================================
     * Leer nivel
     * ======================================== */

    ldr r0, =level
    ldr r0, [r0]


    /*
     * r4 = velocidad carro rápido
     * r5 = velocidad carros normales
     */


    /* NIVEL 0 */

    movs r4, #2
    movs r5, #1

    cmp r0, #0
    beq speeds_ready


    /* NIVEL 1 */

    movs r4, #3
    movs r5, #2

    cmp r0, #1
    beq speeds_ready


    /* NIVEL 2 o superior */

    movs r4, #4
    movs r5, #3


speeds_ready:


    /* ========================================================
     * CARRO 1 -> DERECHA
     * ======================================================== */

    ldr r0, =car1_x
    ldr r1, [r0]

    adds r1, r1, r4

    cmp r1, #120
    bls car1_store


    /* Salió por la derecha */

    movs r1, #0


car1_store:

    str r1, [r0]



    /* ========================================================
     * CARRO 2 -> IZQUIERDA
     * ======================================================== */

    ldr r0, =car2_x
    ldr r1, [r0]


    /*
     * Si queda menos espacio que la velocidad,
     * reaparece a la derecha.
     *
     * Esto evita underflow.
     */

    cmp r1, r5
    blo car2_wrap


    subs r1, r1, r5

    b car2_store


car2_wrap:

    movs r1, #120


car2_store:

    str r1, [r0]



    /* ========================================================
     * CARRO 3 -> DERECHA
     * ======================================================== */

    ldr r0, =car3_x
    ldr r1, [r0]

    adds r1, r1, r5

    cmp r1, #120
    bls car3_store


    movs r1, #0


car3_store:

    str r1, [r0]


    pop {r4-r6, pc}

/* ============================================================
 * draw_goal_strip
 *
 * Dibuja una meta cuadriculada entre Y=8 y Y=15.
 *
 * Como Y=8..15 coincide exactamente con la página 1
 * del SSD1306, escribimos directamente al framebuffer.
 *
 * 0x55 = 01010101
 * 0xAA = 10101010
 * ============================================================ */

.type draw_goal_strip, %function
.thumb_func

draw_goal_strip:

    /* Comienzo de página 1:
     *
     * framebuffer + 128
     */

    ldr r0, =framebuffer

    adds r0, r0, #128


    /*
     * 64 pares = 128 columnas.
     */

    movs r1, #64

    movs r2, #0x55
    movs r3, #0xAA


goal_strip_loop:

    strb r2, [r0]

    adds r0, r0, #1


    strb r3, [r0]

    adds r0, r0, #1


    subs r1, r1, #1

    bne goal_strip_loop


    bx lr

/* ============================================================
 * game_draw
 *
 * Dibuja:
 *
 *    ---------------- y=15
 *          auto
 *    ---------------- y=31
 *          auto
 *          auto
 *    ---------------- y=47
 *
 *    zona segura
 *    rana
 * ============================================================ */
.type game_draw, %function
.thumb_func

game_draw:

    push {r4-r6, lr}


    /* ========================================================
     * META
     * ======================================================== */

    bl draw_goal_strip


    /* ========================================================
     * BORDE SUPERIOR DE LA CARRETERA
     * ======================================================== */

    movs r0, #0
    movs r1, #15
    movs r2, #128
    movs r3, #1

    bl draw_hline


    /* ========================================================
     * DIVISIÓN CARRIL 1 / CARRIL 2
     * ======================================================== */

    movs r0, #0
    movs r1, #27
    movs r2, #128
    movs r3, #1

    bl draw_dashed_hline


    /* ========================================================
     * DIVISIÓN CARRIL 2 / CARRIL 3
     * ======================================================== */

    movs r0, #0
    movs r1, #39
    movs r2, #128
    movs r3, #1

    bl draw_dashed_hline


    /* ========================================================
     * BORDE INFERIOR DE LA CARRETERA
     * ======================================================== */

    movs r0, #0
    movs r1, #47
    movs r2, #128
    movs r3, #1

    bl draw_hline


    /* ========================================================
     * AUTO 1 -> DERECHA
     * ======================================================== */

    ldr r4, =car1_x
    ldr r0, [r4]

    movs r1, #16

    ldr r2, =car_right_sprite

    bl draw_sprite8x8


    /* ========================================================
     * AUTO 2 -> IZQUIERDA
     * ======================================================== */

    ldr r4, =car2_x
    ldr r0, [r4]

    movs r1, #32

    ldr r2, =car_left_sprite

    bl draw_sprite8x8


    /* ========================================================
     * AUTO 3 -> DERECHA
     * ======================================================== */

    ldr r4, =car3_x
    ldr r0, [r4]

    movs r1, #40

    ldr r2, =car_right_sprite

    bl draw_sprite8x8


    pop {r4-r6, pc}