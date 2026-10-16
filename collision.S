/*
 * collision.S
 *
 * Colisiones y vidas de Frogger
 */

.syntax unified
.cpu cortex-m3
.thumb


.extern frog_x
.extern frog_y

.extern car1_x
.extern car2_x
.extern car3_x

.extern draw_sprite8x8
.extern frog_sprite


.global collision_init
.global collision_check
.global lives_draw

.global lives
.global game_over_flag


/* ============================================================
 * ESTADO
 * ============================================================ */

.section .data
.align 4

lives:
    .word 3

game_over_flag:
    .word 0


/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ============================================================
 * collision_init
 * ============================================================ */

.type collision_init, %function
.thumb_func

collision_init:

    /* 3 vidas */

    ldr r0, =lives
    movs r1, #3
    str r1, [r0]


    /* Game Over desactivado */

    ldr r0, =game_over_flag
    movs r1, #0
    str r1, [r0]


    bx lr



/* ============================================================
 * hit_car
 *
 * Detecta colisión AABB entre dos objetos 8x8.
 *
 * Entrada:
 *   r0 = frog X
 *   r1 = frog Y
 *   r2 = car X
 *   r3 = car Y
 *
 * Salida:
 *   r0 = 1 colisión
 *   r0 = 0 no colisión
 * ============================================================ */

.type hit_car, %function
.thumb_func

hit_car:

    /*
     * Si:
     *
     * frogX >= carX+8
     *
     * no chocan.
     */

    adds r12, r2, #8

    cmp r0, r12

    bge no_hit


    /*
     * frogX+8 <= carX
     */

    adds r12, r0, #8

    cmp r12, r2

    ble no_hit


    /*
     * frogY >= carY+8
     */

    adds r12, r3, #8

    cmp r1, r12

    bge no_hit


    /*
     * frogY+8 <= carY
     */

    adds r12, r1, #8

    cmp r12, r3

    ble no_hit


    /* ¡CHOQUE! */

    movs r0, #1

    bx lr


no_hit:

    movs r0, #0

    bx lr



/* ============================================================
 * collision_check
 *
 * Comprueba la rana contra los 3 carros.
 *
 * Salida:
 *   r0 = 1 si hubo choque
 *   r0 = 0 si no hubo choque
 * ============================================================ */

.type collision_check, %function
.thumb_func

collision_check:

    /*
     * 6 registros = 24 bytes
     * stack alineado a 8.
     */

    push {r3-r7, lr}


    /* Posición de la rana */

    ldr r6, =frog_x
    ldr r4, [r6]

    ldr r6, =frog_y
    ldr r5, [r6]


    /* ========================================================
     * CARRO 1
     * Y = 16
     * ======================================================== */

    mov r0, r4
    mov r1, r5

    ldr r6, =car1_x
    ldr r2, [r6]

    movs r3, #16

    bl hit_car

    cmp r0, #0
    bne collision_hit


    /* ========================================================
     * CARRO 2
     * Y = 32
     * ======================================================== */

    mov r0, r4
    mov r1, r5

    ldr r6, =car2_x
    ldr r2, [r6]

    movs r3, #32

    bl hit_car

    cmp r0, #0
    bne collision_hit


    /* ========================================================
     * CARRO 3
     * Y = 40
     * ======================================================== */

    mov r0, r4
    mov r1, r5

    ldr r6, =car3_x
    ldr r2, [r6]

    movs r3, #40

    bl hit_car

    cmp r0, #0
    bne collision_hit


    /* Ninguna colisión */

    movs r0, #0

    b collision_end



/* ============================================================
 * HUBO COLISIÓN
 * ============================================================ */

collision_hit:

    /* Obtener vidas */

    ldr r6, =lives

    ldr r7, [r6]


    /*
     * Evitar bajar de cero.
     */

    cmp r7, #0

    beq collision_already_over


    /* vidas-- */

    subs r7, r7, #1

    str r7, [r6]


    /* ==========================================
     * Regresar rana al inicio
     *
     * X = 56
     * Y = 56
     * ========================================== */

    ldr r0, =frog_x

    movs r1, #56

    str r1, [r0]


    ldr r0, =frog_y

    movs r1, #56

    str r1, [r0]


    /* ==========================================
     * ¿Se acabaron las vidas?
     * ========================================== */

    cmp r7, #0

    bne collision_return_hit


    /* game_over_flag = 1 */

    ldr r0, =game_over_flag

    movs r1, #1

    str r1, [r0]


collision_return_hit:

    movs r0, #1

    b collision_end


collision_already_over:

    movs r0, #0


collision_end:

    pop {r3-r7, pc}



/* ============================================================
 * lives_draw
 *
 * HUD temporal.
 *
 * Dibuja una ranita pequeña por cada vida.
 *
 * 3 vidas:
 *
 * 🐸 🐸 🐸
 *
 * ============================================================ */

.type lives_draw, %function
.thumb_func

lives_draw:

    /*
     * 6 registros = 24 bytes
     */

    push {r3-r7, lr}


    ldr r4, =lives

    ldr r4, [r4]


    /* X inicial */

    movs r5, #0


lives_loop:

    cmp r4, #0

    beq lives_end


    /* X */

    mov r0, r5


    /* Y = 0 */

    movs r1, #0


    /* Sprite */

    ldr r2, =frog_sprite


    bl draw_sprite8x8


    /* Siguiente icono */

    adds r5, r5, #10

    subs r4, r4, #1

    b lives_loop


lives_end:

    pop {r3-r7, pc}