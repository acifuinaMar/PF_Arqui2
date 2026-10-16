/*
 * joystick.S
 * Lectura directa del joystick usando el ADC del SAM3X8E
 *
 * A0  -> PA16 -> ADC7 -> X
 * A1  -> PA24 -> ADC6 -> Y
 * D22 -> PB26        -> botón Z
 */

.syntax unified
.cpu cortex-m3
.thumb


/* ============================================================
 * PMC
 * ============================================================ */

.equ PMC_BASE,       0x400E0600
.equ PMC_PCER0,      0x0010
.equ PMC_PCER1,      0x0100

/* PIOB = ID 12 */
.equ PIOB_CLK,       0x00001000

/* ADC = ID 37 -> bit 5 de PCER1 */
.equ ADC_CLK,        0x00000020


/* ============================================================
 * PIOB - botón Z en D22 / PB26
 * ============================================================ */

.equ PIOB,           0x400E1000

.equ PIO_PER,        0x000
.equ PIO_ODR,        0x014
.equ PIO_PDSR,       0x03C
.equ PIO_IDR,        0x044
.equ PIO_PUER,       0x064

.equ JOY_SW_MASK,    0x04000000


/* ============================================================
 * ADC
 * ============================================================ */

.equ ADC_BASE,       0x400C0000

.equ ADC_CR,         0x000
.equ ADC_MR,         0x004
.equ ADC_CHER,       0x010
.equ ADC_CHDR,       0x014
.equ ADC_IDR,        0x028
.equ ADC_ISR,        0x030

/* ADC_CDR[n] empieza en 0x50 */

.equ ADC_CDR6,       0x068
.equ ADC_CDR7,       0x06C


/* Canales que utilizamos:
 *
 * bit 6 = ADC6 = A1 = Y
 * bit 7 = ADC7 = A0 = X
 */

.equ JOY_ADC_MASK,   0x000000C0


/* ============================================================
 * EXPORTACIONES
 * ============================================================ */

.global joystick_init
.global joystick_read
.global joystick_button


.section .text
.align 2


/* ============================================================
 * joystick_init
 *
 * Inicializa:
 *  - ADC6
 *  - ADC7
 *  - botón Z PB26
 * ============================================================ */

.type joystick_init, %function
.thumb_func

joystick_init:

    /* ------------------------------------------
     * Activar reloj PIOB
     * ------------------------------------------ */

    ldr r0, =PMC_BASE
    ldr r1, =PIOB_CLK
    str r1, [r0, #PMC_PCER0]


    /* ------------------------------------------
     * Configurar PB26 como entrada con pull-up
     * ------------------------------------------ */

    ldr r0, =PIOB
    ldr r1, =JOY_SW_MASK

    /* Desactivar interrupción */
    str r1, [r0, #PIO_IDR]

    /* Entrada */
    str r1, [r0, #PIO_ODR]

    /* Pull-up */
    str r1, [r0, #PIO_PUER]

    /* Control GPIO */
    str r1, [r0, #PIO_PER]


    /* ------------------------------------------
     * Activar reloj ADC
     * ------------------------------------------ */

    ldr r0, =PMC_BASE
    ldr r1, =ADC_CLK
    str r1, [r0, #PMC_PCER1]


    /* ------------------------------------------
     * Reset ADC
     * ------------------------------------------ */

    ldr r0, =ADC_BASE

    movs r1, #1
    str r1, [r0, #ADC_CR]


    /* ------------------------------------------
     * Configuración ADC
     *
     * Resolución: 12 bits
     * Trigger: software
     * ADC clock ≈ 14 MHz
     * ------------------------------------------ */

    ldr r1, =0x13040200
    str r1, [r0, #ADC_MR]


    /* Desactivar todos los canales */

    movw r1, #0xFFFF
    str r1, [r0, #ADC_CHDR]


    /* Sin interrupciones ADC por ahora */

    mvn r1, #0
    str r1, [r0, #ADC_IDR]


    /* Activar ADC6 y ADC7 */

    movs r1, #JOY_ADC_MASK
    str r1, [r0, #ADC_CHER]


    bx lr



/* ============================================================
 * joystick_read
 *
 * Lee ambos ejes.
 *
 * Salida:
 *   r0 = X (ADC7 / A0), 0..4095
 *   r1 = Y (ADC6 / A1), 0..4095
 * ============================================================ */

.type joystick_read, %function
.thumb_func

joystick_read:

    ldr r2, =ADC_BASE


    /* Iniciar conversión */

    movs r3, #2
    str r3, [r2, #ADC_CR]


adc_wait:

    /* Esperar EOC6 y EOC7 */

    ldr r3, [r2, #ADC_ISR]

    ands r3, r3, #JOY_ADC_MASK

    cmp r3, #JOY_ADC_MASK

    bne adc_wait


    /* A0 / ADC7 = X */

    ldr r0, [r2, #ADC_CDR7]


    /* A1 / ADC6 = Y */

    ldr r1, [r2, #ADC_CDR6]


    bx lr



/* ============================================================
 * joystick_button
 *
 * Salida:
 *   r0 = 1 si Z está presionado
 *   r0 = 0 si está libre
 * ============================================================ */

.type joystick_button, %function
.thumb_func

joystick_button:

    ldr r1, =PIOB

    ldr r2, [r1, #PIO_PDSR]

    ldr r1, =JOY_SW_MASK

    tst r2, r1

    beq joy_pressed


    movs r0, #0
    bx lr


joy_pressed:

    movs r0, #1
    bx lr