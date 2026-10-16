/*
 * goal.S
 *
 * Control de meta y puntuación.
 */

.syntax unified
.cpu cortex-m3
.thumb

.extern frog_x
.extern frog_y
.extern score

.extern level

.global goal_check

.global draw_dashed_hline

.section .text
.align 2

/* ============================================================
 * goal_check
 *
 * Llegar a la meta:
 *
 * score += 100
 *
 * Si pasa de 900:
 *   score = 999
 *
 * Si ya teníamos 999 y volvemos a llegar:
 *
 *   score = 000
 *   level++
 *
 * El nivel máximo es 2.
 * ============================================================ */

.type goal_check, %function
.thumb_func

goal_check:

    /* ========================================
     * ¿Llegó a la meta?
     * ======================================== */

    ldr r0, =frog_y
    ldr r1, [r0]

    cmp r1, #8
    bhi goal_no


    /* ========================================
     * Leer score
     * ======================================== */

    ldr r0, =score
    ldr r1, [r0]


    /* ========================================
     * ¿Ya estaba en 999?
     * ======================================== */

    movw r2, #999

    cmp r1, r2

    beq goal_level_up


    /* ========================================
     * score += 100
     * ======================================== */

    adds r1, r1, #100


    /*
     * Si pasó de 999:
     * dejamos exactamente 999.
     */

    cmp r1, r2
    bls goal_store_score

    mov r1, r2


goal_store_score:

    str r1, [r0]

    b goal_reset_frog



/* ============================================================
 * SUBIR NIVEL
 * ============================================================ */

goal_level_up:

    /*
     * Score vuelve a 000.
     */

    movs r1, #0
    str r1, [r0]


    /*
     * Leer nivel.
     */

    ldr r0, =level
    ldr r1, [r0]


    /*
     * Máximo nivel = 2.
     */

    cmp r1, #2
    bhs goal_reset_frog


    adds r1, r1, #1

    str r1, [r0]



/* ============================================================
 * Regresar jugador al inicio
 * ============================================================ */

goal_reset_frog:

    ldr r0, =frog_x
    movs r1, #56
    str r1, [r0]


    ldr r0, =frog_y
    movs r1, #56
    str r1, [r0]


    movs r0, #1
    bx lr



goal_no:

    movs r0, #0
    bx lr

/* ============================================================
 * draw_dashed_hline
 *
 * Línea horizontal discontinua:
 *
 * ####....####....####
 *
 * Entrada:
 *   r0 = X inicial
 *   r1 = Y
 *   r2 = longitud
 *   r3 = color
 * ============================================================ */

.type draw_dashed_hline, %function
.thumb_func

draw_dashed_hline:

    /*
     * 6 registros = 24 bytes.
     * Stack alineado a 8 bytes.
     */

    push {r3-r7, lr}

    /* X actual */
    mov r4, r0

    /* Y */
    mov r5, r1

    /* X final = inicial + longitud */
    adds r6, r0, r2

    /* color */
    mov r7, r3


dashed_loop:

    cmp r4, r6
    bhs dashed_end


    /* Dibujar 4 pixels */

    mov r0, r4
    mov r1, r5

    movs r2, #4
    mov r3, r7

    bl draw_hline


    /*
     * 4 encendidos + 4 apagados
     */

    adds r4, r4, #8

    b dashed_loop


dashed_end:

    pop {r3-r7, pc}