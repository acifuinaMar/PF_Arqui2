/*
 * player.S
 * Control del jugador de Frogger
 */

.syntax unified
.cpu cortex-m3
.thumb


.extern joystick_read
.extern draw_sprite8x8
.extern frog_sprite


.global player_init
.global player_update
.global player_draw

.global frog_x
.global frog_y


/* ============================================================
 * ESTADO DEL JUGADOR
 * ============================================================ */

.section .data
.align 4

frog_x:
    .word 56

frog_y:
    .word 56

/*
 * 0 = joystick preparado
 * 1 = esperar que vuelva al centro
 */
joy_latched:
    .word 0



/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ============================================================
 * player_init
 * ============================================================ */

.type player_init, %function
.thumb_func

player_init:

    ldr r0, =frog_x
    movs r1, #56
    str r1, [r0]

    ldr r0, =frog_y
    movs r1, #56
    str r1, [r0]

    ldr r0, =joy_latched
    movs r1, #0
    str r1, [r0]

    bx lr



/* ============================================================
 * player_update
 *
 * Lee joystick y mueve 8 pixels.
 *
 * Retorna:
 *   r0 = 1 si la rana se movió
 *   r0 = 0 si no hubo movimiento
 *
 * Zona muerta:
 *
 *      1300 ---- centro ---- 2800
 *
 * ============================================================ */

.type player_update, %function
.thumb_func

player_update:

    /*
     * 6 registros = 24 bytes
     * Mantiene stack alineado a 8 bytes.
     */
    push {r3-r7, lr}


    /* Leer ADC */

    bl joystick_read

    /* r4 = X */
    mov r4, r0

    /* r5 = Y */
    mov r5, r1


    /* Estado del latch */

    ldr r6, =joy_latched
    ldr r7, [r6]


    /* Umbrales */

    movw r2, #1300
    movw r3, #2800


    /* ========================================================
     * ¿Joystick en zona central?
     * ======================================================== */

    cmp r4, r2
    blo joy_not_neutral

    cmp r4, r3
    bhi joy_not_neutral

    cmp r5, r2
    blo joy_not_neutral

    cmp r5, r3
    bhi joy_not_neutral


    /*
     * Volvió al centro:
     * permitimos nuevo movimiento.
     */

    movs r0, #0
    str r0, [r6]

    /* No hubo movimiento */

    movs r0, #0

    b player_update_end



/* ============================================================
 * Fuera de la zona central
 * ============================================================ */

joy_not_neutral:

    /*
     * Si ya procesamos este movimiento,
     * esperamos a que regrese al centro.
     */

    cmp r7, #0
    bne player_no_move


    /* ----------------------------------------
     * EJE X
     * ---------------------------------------- */

    cmp r4, r2
    blo move_left

    cmp r4, r3
    bhi move_right


    /* ----------------------------------------
     * EJE Y
     * ---------------------------------------- */

    cmp r5, r2
    blo move_up

    cmp r5, r3
    bhi move_down


player_no_move:

    movs r0, #0
    b player_update_end



/* ============================================================
 * IZQUIERDA
 * ============================================================ */

move_left:

    ldr r2, =frog_x
    ldr r1, [r2]

    cmp r1, #0
    beq player_limit

    subs r1, r1, #8

    str r1, [r2]

    b player_moved



/* ============================================================
 * DERECHA
 * ============================================================ */

move_right:

    ldr r2, =frog_x
    ldr r1, [r2]

    /* 120 + sprite 8px = 128 */

    cmp r1, #120
    bhs player_limit

    adds r1, r1, #8

    str r1, [r2]

    b player_moved



/* ============================================================
 * ARRIBA
 * ============================================================ */

move_up:

    ldr r2, =frog_y
    ldr r1, [r2]

    cmp r1, #0
    beq player_limit

    subs r1, r1, #8

    str r1, [r2]

    b player_moved



/* ============================================================
 * ABAJO
 * ============================================================ */

move_down:

    ldr r2, =frog_y
    ldr r1, [r2]

    /* 56 + sprite 8px = 64 */

    cmp r1, #56
    bhs player_limit

    adds r1, r1, #8

    str r1, [r2]

    b player_moved



/* ============================================================
 * Movimiento efectuado
 * ============================================================ */

player_moved:

    /* Bloquear hasta regresar al centro */

    movs r1, #1
    str r1, [r6]

    /* Informar que hay que redibujar */

    movs r0, #1

    b player_update_end



/* ============================================================
 * Intentó salir de la pantalla
 * ============================================================ */

player_limit:

    /*
     * Igual bloqueamos este movimiento
     * hasta regresar al centro.
     */

    movs r1, #1
    str r1, [r6]

    movs r0, #0



player_update_end:

    pop {r3-r7, pc}



/* ============================================================
 * player_draw
 *
 * Dibuja la rana en su posición actual.
 * ============================================================ */

.type player_draw, %function
.thumb_func

player_draw:

    /* 8 bytes -> stack alineado */

    push {r4, lr}


    ldr r3, =frog_x
    ldr r0, [r3]


    ldr r3, =frog_y
    ldr r1, [r3]


    ldr r2, =frog_sprite


    bl draw_sprite8x8


    pop {r4, pc}