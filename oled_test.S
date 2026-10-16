/*
 * oled_test.S
 * Prueba OLED SSD1306 128x64 SPI
 * Arduino Due - SAM3X8E Cortex-M3
 *
 * OLED:
 *   D34 / PC2 -> SCK
 *   D35 / PC3 -> MOSI
 *   D36 / PC4 -> RESET
 *   D37 / PC5 -> DC
 *   D38 / PC6 -> CS
 */

.syntax unified
.cpu cortex-m3
.thumb

.extern clear_buffer
.extern draw_sprite8x8
.extern frog_sprite

.extern joystick_init

.extern player_init
.extern player_update
.extern player_draw

.extern timer_init
.extern frame_tick

.extern game_init
.extern game_update
.extern game_draw

.extern collision_init
.extern collision_check
.extern lives_draw

.extern game_over_flag

.extern timer_stop

.extern ui_draw
.extern game_over_draw

.extern goal_check

.extern state_init
.extern button_event
.extern start_new_game
.extern set_game_over
.extern game_state

.extern menu_draw

/* ============================================================
 * REGISTROS PMC
 * ============================================================ */

.equ PMC_BASE,   0x400E0600
.equ PMC_PCER0,  0x0010

/* PIOC tiene Peripheral ID 13 */
.equ PIOC_CLK,   0x00002000


/* ============================================================
 * REGISTROS PIOC
 * ============================================================ */

.equ PIOC,       0x400E1200

.equ PIO_PER,    0x000
.equ PIO_OER,    0x010
.equ PIO_SODR,   0x030
.equ PIO_CODR,   0x034


/* ============================================================
 * PINES OLED
 * ============================================================ */

.equ OLED_SCK,   0x00000004      /* PC2 - D34 */
.equ OLED_MOSI,  0x00000008      /* PC3 - D35 */
.equ OLED_RES,   0x00000010      /* PC4 - D36 */
.equ OLED_DC,    0x00000020      /* PC5 - D37 */
.equ OLED_CS,    0x00000040      /* PC6 - D38 */

.equ OLED_ALL,   0x0000007C


/* ============================================================
 * FRAMEBUFFER
 * 128 * 64 / 8 = 1024 bytes
 * ============================================================ */

.section .bss
.align 4

.global framebuffer

framebuffer:
    .space 1024


/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2


/* ------------------------------------------------------------
 * Arduino core llama setup() con nombre C++:
 *
 * void setup() -> _Z5setupv
 * ------------------------------------------------------------ */
 .global setup
.type setup, %function
.thumb_func

setup:

    push {r3-r7, lr}


    /* ========================================================
     * OLED
     * ======================================================== */

    bl gpio_oled_init

    bl oled_reset

    bl oled_init


    /* ========================================================
     * Joystick
     * ======================================================== */

    bl joystick_init


    /* ========================================================
     * Máquina de estados
     *
     * Arrancamos en MENU.
     * ======================================================== */

    bl state_init


    /* ========================================================
     * Mostrar menú inicial
     * ======================================================== */

    bl menu_draw

    bl oled_flush


    pop {r3-r7, pc}

/* ------------------------------------------------------------
 * void loop()
 *
 * No necesitamos hacer nada todavía.
 * ------------------------------------------------------------ */
.global loop
.type loop, %function
.thumb_func

loop:

    push {r4, lr}


    /* ========================================================
     * Leer estado actual
     * ======================================================== */

    ldr r4, =game_state

    ldr r0, [r4]


    /* MENU = 0 */

    cmp r0, #0
    beq loop_menu


    /* PLAYING = 1 */

    cmp r0, #1
    beq loop_playing


    /* Si no es ninguno:
     * GAME OVER = 2
     */

    b loop_game_over



/* ============================================================
 * ESTADO: MENU
 * ============================================================ */

loop_menu:

    /*
     * Esperamos una nueva pulsación de Z.
     */

    bl button_event

    cmp r0, #0

    beq loop_end


    /*
     * Z presionado:
     *
     * iniciar partida.
     */

    bl start_new_game


    /*
     * Mostrar inmediatamente
     * el primer frame.
     */

    bl clear_buffer

    bl game_draw

    bl ui_draw

    bl player_draw

    bl oled_flush


    b loop_end



/* ============================================================
 * ESTADO: PLAYING
 * ============================================================ */

loop_playing:

    /* ========================================
     * Esperar tick de TC0
     * ======================================== */

    ldr r4, =frame_tick

    ldr r0, [r4]

    cmp r0, #0

    beq loop_end


    /* Consumir tick */

    movs r0, #0

    str r0, [r4]


    /* ========================================
     * Actualizar jugador y enemigos
     * ======================================== */

    bl player_update

    bl game_update


    /* ========================================
     * Colisiones
     * ======================================== */

    bl collision_check


    /* ========================================
     * ¿Se acabaron las vidas?
     * ======================================== */

    ldr r0, =game_over_flag

    ldr r0, [r0]

    cmp r0, #0

    bne transition_game_over


    /* ========================================
     * ¿Llegó a la meta?
     * ======================================== */

    bl goal_check


    /* ========================================
     * Dibujar frame normal
     * ======================================== */

    bl clear_buffer

    bl game_draw

    bl ui_draw

    bl player_draw

    bl oled_flush


    b loop_end



/* ============================================================
 * TRANSICIÓN A GAME OVER
 * ============================================================ */

transition_game_over:

    /*
     * Dibujar pantalla final.
     */

    bl game_over_draw

    bl oled_flush


    /*
     * Cambiar estado y detener timer.
     */

    bl set_game_over


    b loop_end



/* ============================================================
 * ESTADO: GAME OVER
 * ============================================================ */

loop_game_over:

    /*
     * Esperar otra pulsación de Z.
     */

    bl button_event

    cmp r0, #0

    beq loop_end


    /* ========================================
     * Reiniciar partida
     * ======================================== */

    bl start_new_game


    /* Primer frame */

    bl clear_buffer

    bl game_draw

    bl ui_draw

    bl player_draw

    bl oled_flush

/* ============================================================
 * FIN
 * ============================================================ */

loop_end:

    pop {r4, pc}

/* ============================================================
 * GAME OVER
 * ============================================================ */

show_game_over:

    /*
     * Dibujamos pantalla final.
     */

    bl game_over_draw

    bl oled_flush

    /*
     * Detenemos las físicas.
     */

    bl timer_stop

no_frame:

    pop {r4, pc}

loop_no_redraw:

    pop {r4, pc}

/* ============================================================
 * gpio_oled_init
 *
 * Configura PC2-PC6 como GPIO de salida.
 * ============================================================ */

.type gpio_oled_init, %function
.thumb_func

gpio_oled_init:

    push {r4-r5, lr}

    /* Activar reloj de PIOC */
    ldr r4, =PMC_BASE
    ldr r5, =PIOC_CLK
    str r5, [r4, #PMC_PCER0]


    /* Configurar PC2-PC6 */
    ldr r4, =PIOC
    ldr r5, =OLED_ALL

    /* Control GPIO */
    str r5, [r4, #PIO_PER]

    /* Salidas */
    str r5, [r4, #PIO_OER]


    /* Estado inicial */

    /* CLK = LOW */
    ldr r5, =OLED_SCK
    str r5, [r4, #PIO_CODR]

    /* MOSI = LOW */
    ldr r5, =OLED_MOSI
    str r5, [r4, #PIO_CODR]

    /* DC = LOW */
    ldr r5, =OLED_DC
    str r5, [r4, #PIO_CODR]

    /* RESET = HIGH */
    ldr r5, =OLED_RES
    str r5, [r4, #PIO_SODR]

    /* CS = HIGH */
    ldr r5, =OLED_CS
    str r5, [r4, #PIO_SODR]

    pop {r4-r5, pc}



/* ============================================================
 * wait_short
 *
 * Pequeña espera únicamente durante inicialización.
 *
 * NO será utilizada para las físicas del videojuego.
 * El juego utilizará Timer + NVIC.
 * ============================================================ */

.type wait_short, %function
.thumb_func

wait_short:

    ldr r0, =200000

wait_loop:

    subs r0, r0, #1
    bne wait_loop

    bx lr



/* ============================================================
 * oled_reset
 * ============================================================ */

.type oled_reset, %function
.thumb_func

oled_reset:

    push {r4-r5, lr}

    ldr r4, =PIOC
    ldr r5, =OLED_RES

    /* RESET LOW */
    str r5, [r4, #PIO_CODR]

    bl wait_short

    /* RESET HIGH */
    str r5, [r4, #PIO_SODR]

    bl wait_short

    pop {r4-r5, pc}



/* ============================================================
 * spi_send_byte
 *
 * Entrada:
 *   r0 = byte a transmitir
 *
 * SPI software:
 *   MSB primero
 *   Mode 0
 * ============================================================ */

.type spi_send_byte, %function
.thumb_func

spi_send_byte:

    push {r4-r6, lr}

    ldr r4, =PIOC

    mov r5, #8


spi_bit_loop:

    /* Revisar bit 7 */
    tst r0, #0x80

    beq spi_bit_zero


/* bit = 1 */

    ldr r6, =OLED_MOSI
    str r6, [r4, #PIO_SODR]

    b spi_clock


spi_bit_zero:

    ldr r6, =OLED_MOSI
    str r6, [r4, #PIO_CODR]


spi_clock:

    /* CLK HIGH */
    ldr r6, =OLED_SCK
    str r6, [r4, #PIO_SODR]

    nop
    nop

    /* CLK LOW */
    str r6, [r4, #PIO_CODR]

    /* Próximo bit */
    lsls r0, r0, #1

    subs r5, r5, #1
    bne spi_bit_loop

    pop {r4-r6, pc}



/* ============================================================
 * oled_command
 *
 * Entrada:
 *   r0 = comando SSD1306
 * ============================================================ */

.type oled_command, %function
.thumb_func

oled_command:

    push {r4-r5, lr}

    /* Guardar comando */
    mov r5, r0

    ldr r4, =PIOC

    /* DC = 0 -> comando */
    ldr r0, =OLED_DC
    str r0, [r4, #PIO_CODR]

    /* CS = 0 */
    ldr r0, =OLED_CS
    str r0, [r4, #PIO_CODR]

    mov r0, r5
    bl spi_send_byte

    /* CS = 1 */
    ldr r0, =OLED_CS
    str r0, [r4, #PIO_SODR]

    pop {r4-r5, pc}



/* ============================================================
 * oled_init
 *
 * Secuencia de inicialización SSD1306
 * ============================================================ */

.type oled_init, %function
.thumb_func

oled_init:

    push {lr}


    /* Display OFF */
    mov r0, #0xAE
    bl oled_command


    /* Clock divide */
    mov r0, #0xD5
    bl oled_command

    mov r0, #0x80
    bl oled_command


    /* Multiplex 1/64 */
    mov r0, #0xA8
    bl oled_command

    mov r0, #0x3F
    bl oled_command


    /* Display offset */
    mov r0, #0xD3
    bl oled_command

    mov r0, #0x00
    bl oled_command


    /* Start line = 0 */
    mov r0, #0x40
    bl oled_command


    /* Charge pump */
    mov r0, #0x8D
    bl oled_command

    mov r0, #0x14
    bl oled_command


    /* Horizontal addressing */
    mov r0, #0x20
    bl oled_command

    mov r0, #0x00
    bl oled_command


    /* Segment remap */
    mov r0, #0xA1
    bl oled_command


    /* COM scan direction */
    mov r0, #0xC8
    bl oled_command


    /* COM pins */
    mov r0, #0xDA
    bl oled_command

    mov r0, #0x12
    bl oled_command


    /* Contrast */
    mov r0, #0x81
    bl oled_command

    mov r0, #0xCF
    bl oled_command


    /* Precharge */
    mov r0, #0xD9
    bl oled_command

    mov r0, #0xF1
    bl oled_command


    /* VCOMH */
    mov r0, #0xDB
    bl oled_command

    mov r0, #0x40
    bl oled_command


    /* Resume RAM display */
    mov r0, #0xA4
    bl oled_command


    /* Normal display */
    mov r0, #0xA6
    bl oled_command


    /* Display ON */
    mov r0, #0xAF
    bl oled_command


    pop {pc}



/* ============================================================
 * framebuffer_test
 *
 * Mitad superior apagada
 * Mitad inferior encendida
 *
 * SSD1306:
 * 8 páginas × 128 bytes = 1024 bytes
 *
 * 4 páginas negras  = 512 bytes
 * 4 páginas blancas = 512 bytes
 * ============================================================ */

.type framebuffer_test, %function
.thumb_func

framebuffer_test:

    push {r4-r6, lr}

    ldr r4, =framebuffer

    /* ----------------------------------------
     * Primeros 512 bytes = 0x00
     * ---------------------------------------- */

    movw r5, #512
    mov r6, #0x00

fb_black:

    strb r6, [r4]
    adds r4, r4, #1

    subs r5, r5, #1
    bne fb_black


    /* ----------------------------------------
     * Siguientes 512 bytes = 0xFF
     * ---------------------------------------- */

    movw r5, #512
    mov r6, #0xFF

fb_white:

    strb r6, [r4]
    adds r4, r4, #1

    subs r5, r5, #1
    bne fb_white


    pop {r4-r6, pc}

    push {r4-r7, lr}

    ldr r4, =framebuffer

    movw r5, #1024

    mov r6, #0xAA
    mov r7, #0x55


fb_test_loop:

    strb r6, [r4]
    adds r4, r4, #1

    subs r5, r5, #1
    beq fb_test_end


    strb r7, [r4]
    adds r4, r4, #1

    subs r5, r5, #1
    bne fb_test_loop


fb_test_end:

    pop {r4-r7, pc}



/* ============================================================
 * oled_flush
 *
 * Envía los 1024 bytes de framebuffer a la OLED.
 * ============================================================ */
.global oled_flush
.type oled_flush, %function
.thumb_func

oled_flush:

    push {r4-r7, lr}


    /* Columna inicial/final */

    mov r0, #0x21
    bl oled_command

    mov r0, #0
    bl oled_command

    mov r0, #127
    bl oled_command


    /* Página inicial/final */

    mov r0, #0x22
    bl oled_command

    mov r0, #0
    bl oled_command

    mov r0, #7
    bl oled_command


    /* Preparar transferencia de datos */

    ldr r4, =PIOC


    /* DC = HIGH -> datos */

    ldr r5, =OLED_DC
    str r5, [r4, #PIO_SODR]


    /* CS = LOW */

    ldr r5, =OLED_CS
    str r5, [r4, #PIO_CODR]


    /* Dirección framebuffer */

    ldr r6, =framebuffer

    movw r7, #1024


oled_flush_loop:

    ldrb r0, [r6]

    bl spi_send_byte

    adds r6, r6, #1

    subs r7, r7, #1

    bne oled_flush_loop


    /* CS = HIGH */

    ldr r5, =OLED_CS
    str r5, [r4, #PIO_SODR]


    pop {r4-r7, pc}