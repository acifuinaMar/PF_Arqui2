/*
 * timer.S
 * Timer principal de Frogger
 *
 * TC0 canal 0
 * 30 Hz
 *
 * MCK = 84 MHz
 * TIMER_CLOCK4 = MCK / 128
 *
 * 84,000,000 / 128 = 656,250 Hz
 * 656,250 / 30     = 21,875
 */

.syntax unified
.cpu cortex-m3
.thumb

.global timer_stop

/* ============================================================
 * PMC
 * ============================================================ */

.equ PMC_BASE,       0x400E0600
.equ PMC_PCER0,      0x0010

/* TC0 = Peripheral ID 27 */
.equ TC0_CLK_MASK,   0x08000000


/* ============================================================
 * TC0 - canal 0
 * ============================================================ */

.equ TC0_BASE,       0x40080000

.equ TC_CCR,         0x000
.equ TC_CMR,         0x004
.equ TC_RC,          0x01C
.equ TC_SR,          0x020
.equ TC_IER,         0x024
.equ TC_IDR,         0x028


/* CCR */
.equ TC_CLKEN_SWTRG, 0x00000005


/*
 * CMR:
 *
 * TIMER_CLOCK4  = 0x0003
 * WAVE          = 0x8000
 * WAVSEL_UP_RC  = 0x4000
 *
 * Total = 0xC003
 */

.equ TC_MODE_30HZ,   0x0000C003


/* RC compare interrupt */

.equ TC_CPCS,        0x00000010


/* 30 Hz */

.equ TC_RC_30HZ,     21875


/* ============================================================
 * NVIC
 * ============================================================ */

.equ NVIC_ISER0,     0xE000E100
.equ NVIC_ICPR0,     0xE000E280
.equ NVIC_IPR_BASE,  0xE000E400

/* IRQ 27 */
.equ TC0_IRQ_MASK,   0x08000000


/* ============================================================
 * VARIABLE COMPARTIDA
 * ============================================================ */

.section .bss
.align 4

.global frame_tick

frame_tick:
    .space 4


/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2

.global timer_init
.global TC0_Handler


/* ============================================================
 * timer_init
 * ============================================================ */

.type timer_init, %function
.thumb_func

timer_init:

    /* -------------------------------------------
     * frame_tick = 0
     * ------------------------------------------- */

    ldr r0, =frame_tick

    movs r1, #0

    str r1, [r0]


    /* -------------------------------------------
     * Activar reloj TC0
     * ------------------------------------------- */

    ldr r0, =PMC_BASE

    ldr r1, =TC0_CLK_MASK

    str r1, [r0, #PMC_PCER0]


    /* -------------------------------------------
     * Configurar TC0 canal 0
     * ------------------------------------------- */

    ldr r0, =TC0_BASE


    /* Detener/deshabilitar interrupciones anteriores */

    mvn r1, #0

    str r1, [r0, #TC_IDR]


    /* Leer SR limpia estados anteriores */

    ldr r1, [r0, #TC_SR]


    /* Waveform + MCK/128 + reset en RC */

    ldr r1, =TC_MODE_30HZ

    str r1, [r0, #TC_CMR]


    /* RC = 21875 */

    ldr r1, =TC_RC_30HZ

    str r1, [r0, #TC_RC]


    /* Interrupción por comparación RC */

    movs r1, #TC_CPCS

    str r1, [r0, #TC_IER]


    /* -------------------------------------------
     * NVIC
     * ------------------------------------------- */

    /* Limpiar interrupción pendiente */

    ldr r0, =NVIC_ICPR0

    ldr r1, =TC0_IRQ_MASK

    str r1, [r0]


    /* Prioridad media */

    ldr r0, =NVIC_IPR_BASE

    movs r1, #0x80

    strb r1, [r0, #27]


    /* Activar IRQ 27 */

    ldr r0, =NVIC_ISER0

    ldr r1, =TC0_IRQ_MASK

    str r1, [r0]


    /* -------------------------------------------
     * Iniciar timer
     * CLKEN + SWTRG
     * ------------------------------------------- */

    ldr r0, =TC0_BASE

    movs r1, #TC_CLKEN_SWTRG

    str r1, [r0, #TC_CCR]


    bx lr



/* ============================================================
 * TC0_Handler
 *
 * Se ejecuta 30 veces por segundo.
 *
 * IMPORTANTE:
 * La ISR NO dibuja.
 * Solamente levanta una bandera.
 * ============================================================ */

.type TC0_Handler, %function
.thumb_func

TC0_Handler:

    /* Leer SR reconoce/limpia la interrupción */

    ldr r0, =TC0_BASE

    ldr r1, [r0, #TC_SR]


    /* frame_tick = 1 */

    ldr r0, =frame_tick

    movs r1, #1

    str r1, [r0]


    bx lr

/* ============================================================
 * timer_stop
 *
 * Detiene TC0.
 * ============================================================ */

.type timer_stop, %function
.thumb_func

timer_stop:

    ldr r0, =TC0_BASE

    /*
     * CLKDIS = bit 1
     */

    movs r1, #2

    str r1, [r0, #TC_CCR]

    bx lr