/*
 * state.S
 *
 * Máquina de estados de Frogger.
 *
 * 0 = MENU
 * 1 = PLAYING
 * 2 = GAME OVER
 */

.syntax unified
.cpu cortex-m3
.thumb


.extern joystick_button

.extern player_init
.extern game_init
.extern collision_init

.extern timer_init
.extern timer_stop
.extern frame_tick


.global state_init
.global button_event
.global start_new_game
.global set_game_over

.global game_state


/* ============================================================
 * ESTADOS
 * ============================================================ */

.equ STATE_MENU,      0
.equ STATE_PLAYING,   1
.equ STATE_GAMEOVER,  2


/* ============================================================
 * VARIABLES
 * ============================================================ */

.section .data
.align 4

game_state:
    .word STATE_MENU


/*
 * Evita que mantener Z presionado
 * se interprete como muchas pulsaciones.
 */

button_latched:
    .word 0



/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ============================================================
 * state_init
 * ============================================================ */

.type state_init, %function
.thumb_func

state_init:

    ldr r0, =game_state

    movs r1, #STATE_MENU

    str r1, [r0]


    ldr r0, =button_latched

    movs r1, #0

    str r1, [r0]


    bx lr



/* ============================================================
 * button_event
 *
 * Detecta una NUEVA pulsación de Z.
 *
 * Salida:
 *
 * r0 = 1 -> acaba de ser presionado
 * r0 = 0 -> ninguna pulsación nueva
 * ============================================================ */

.type button_event, %function
.thumb_func

button_event:

    push {r4, lr}


    /*
     * joystick_button:
     *
     * r0 = 1 presionado
     * r0 = 0 libre
     */

    bl joystick_button


    ldr r4, =button_latched


    cmp r0, #0

    beq button_released


    /* ==========================================
     * Está presionado.
     * ¿Ya lo habíamos procesado?
     * ========================================== */

    ldr r1, [r4]

    cmp r1, #0

    bne button_no_event


    /*
     * Primera detección:
     * bloquear hasta que se suelte.
     */

    movs r1, #1

    str r1, [r4]


    movs r0, #1

    b button_end



button_released:

    /*
     * Está libre otra vez.
     */

    movs r1, #0

    str r1, [r4]

    movs r0, #0

    b button_end



button_no_event:

    movs r0, #0



button_end:

    pop {r4, pc}



/* ============================================================
 * start_new_game
 *
 * Reinicia TODO el estado de una partida.
 * ============================================================ */

.type start_new_game, %function
.thumb_func

start_new_game:

    push {r4, lr}


    /* Jugador */

    bl player_init


    /* Autos + score */

    bl game_init


    /* Vidas + Game Over flag */

    bl collision_init


    /* Limpiar posibles ticks anteriores */

    ldr r0, =frame_tick

    movs r1, #0

    str r1, [r0]


    /* Estado = PLAYING */

    ldr r0, =game_state

    movs r1, #STATE_PLAYING

    str r1, [r0]


    /* Iniciar las físicas */

    bl timer_init


    pop {r4, pc}



/* ============================================================
 * set_game_over
 * ============================================================ */

.type set_game_over, %function
.thumb_func

set_game_over:

    push {r4, lr}


    /* Estado = GAME OVER */

    ldr r0, =game_state

    movs r1, #STATE_GAMEOVER

    str r1, [r0]


    /* Detener físicas */

    bl timer_stop


    pop {r4, pc}