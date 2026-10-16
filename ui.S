/*
 * ui.S
 *
 * Interfaz gráfica de Frogger:
 *
 * - Fuente 5x7
 * - Texto
 * - SCORE
 * - LIVES
 * - GAME OVER
 */

.syntax unified
.cpu cortex-m3
.thumb


.extern draw_pixel
.extern clear_buffer

.extern score
.extern lives

.extern level

.extern draw_hline
.extern draw_sprite8x8
.extern frog_sprite

.global draw_char5x7
.global draw_text
.global draw_score3
.global ui_draw
.global game_over_draw
.global menu_draw


/* ============================================================
 * FUENTE 5x7
 *
 * Cada carácter = 5 bytes.
 * Cada byte representa una columna vertical de 7 pixels.
 * ============================================================ */

.section .rodata
.align 2


/* ------------------------------------------------------------
 * Dígitos 0-9
 * ------------------------------------------------------------ */

font_digits:

/* 0 */
.byte 0x3E, 0x51, 0x49, 0x45, 0x3E

/* 1 */
.byte 0x00, 0x42, 0x7F, 0x40, 0x00

/* 2 */
.byte 0x42, 0x61, 0x51, 0x49, 0x46

/* 3 */
.byte 0x21, 0x41, 0x45, 0x4B, 0x31

/* 4 */
.byte 0x18, 0x14, 0x12, 0x7F, 0x10

/* 5 */
.byte 0x27, 0x45, 0x45, 0x45, 0x39

/* 6 */
.byte 0x3C, 0x4A, 0x49, 0x49, 0x30

/* 7 */
.byte 0x01, 0x71, 0x09, 0x05, 0x03

/* 8 */
.byte 0x36, 0x49, 0x49, 0x49, 0x36

/* 9 */
.byte 0x06, 0x49, 0x49, 0x29, 0x1E



/* ------------------------------------------------------------
 * Letras A-Z
 * ------------------------------------------------------------ */

font_letters:

/* A */
.byte 0x7E, 0x11, 0x11, 0x11, 0x7E

/* B */
.byte 0x7F, 0x49, 0x49, 0x49, 0x36

/* C */
.byte 0x3E, 0x41, 0x41, 0x41, 0x22

/* D */
.byte 0x7F, 0x41, 0x41, 0x22, 0x1C

/* E */
.byte 0x7F, 0x49, 0x49, 0x49, 0x41

/* F */
.byte 0x7F, 0x09, 0x09, 0x09, 0x01

/* G */
.byte 0x3E, 0x41, 0x49, 0x49, 0x7A

/* H */
.byte 0x7F, 0x08, 0x08, 0x08, 0x7F

/* I */
.byte 0x00, 0x41, 0x7F, 0x41, 0x00

/* J */
.byte 0x20, 0x40, 0x41, 0x3F, 0x01

/* K */
.byte 0x7F, 0x08, 0x14, 0x22, 0x41

/* L */
.byte 0x7F, 0x40, 0x40, 0x40, 0x40

/* M */
.byte 0x7F, 0x02, 0x0C, 0x02, 0x7F

/* N */
.byte 0x7F, 0x04, 0x08, 0x10, 0x7F

/* O */
.byte 0x3E, 0x41, 0x41, 0x41, 0x3E

/* P */
.byte 0x7F, 0x09, 0x09, 0x09, 0x06

/* Q */
.byte 0x3E, 0x41, 0x51, 0x21, 0x5E

/* R */
.byte 0x7F, 0x09, 0x19, 0x29, 0x46

/* S */
.byte 0x46, 0x49, 0x49, 0x49, 0x31

/* T */
.byte 0x01, 0x01, 0x7F, 0x01, 0x01

/* U */
.byte 0x3F, 0x40, 0x40, 0x40, 0x3F

/* V */
.byte 0x1F, 0x20, 0x40, 0x20, 0x1F

/* W */
.byte 0x3F, 0x40, 0x38, 0x40, 0x3F

/* X */
.byte 0x63, 0x14, 0x08, 0x14, 0x63

/* Y */
.byte 0x07, 0x08, 0x70, 0x08, 0x07

/* Z */
.byte 0x61, 0x51, 0x49, 0x45, 0x43



/* ============================================================
 * TEXTOS
 * ============================================================ */

score_str:
    .asciz "SCORE"

lives_str:
    .asciz "LIVES"

game_over_str:
    .asciz "GAME OVER"

frogger_str:
    .asciz "FROGGER"

press_z_str:
    .asciz "PRESS Z"

level_str:
    .asciz "LV"

/* ============================================================
 * CÓDIGO
 * ============================================================ */

.section .text
.align 2



/* ============================================================
 * draw_char5x7
 *
 * Entrada:
 *
 * r0 = X
 * r1 = Y
 * r2 = código ASCII
 *
 * Soporta:
 *
 * '0' - '9'
 * 'A' - 'Z'
 * espacio
 * ============================================================ */

.type draw_char5x7, %function
.thumb_func

draw_char5x7:

    /*
     * 24 bytes -> stack alineado.
     */

    push {r3-r7, lr}


    /* Guardamos posición */

    mov r4, r0
    mov r5, r1


    /* ========================================================
     * ESPACIO
     * ======================================================== */

    cmp r2, #32
    beq char_end


    /* ========================================================
     * ¿Dígito?
     *
     * ASCII:
     * 0 = 48
     * 9 = 57
     * ======================================================== */

    cmp r2, #48
    blo check_letter

    cmp r2, #57
    bhi check_letter


    /*
     * índice = ASCII - '0'
     */

    subs r3, r2, #48


    /*
     * offset = índice * 5
     *
     * index*4 + index
     */

    lsls r0, r3, #2
    adds r0, r0, r3


    ldr r6, =font_digits
    adds r6, r6, r0

    b char_ready



/* ============================================================
 * ¿Letra A-Z?
 * ============================================================ */

check_letter:

    cmp r2, #65
    blo char_end

    cmp r2, #90
    bhi char_end


    /*
     * índice = ASCII - 'A'
     */

    subs r3, r2, #65


    /*
     * offset = índice * 5
     */

    lsls r0, r3, #2
    adds r0, r0, r3


    ldr r6, =font_letters
    adds r6, r6, r0



/* ============================================================
 * Dibujar 5 columnas
 * ============================================================ */

char_ready:

    movs r7, #0


char_col_loop:

    /*
     * r3 = patrón vertical de la columna
     */

    ldrb r3, [r6, r7]


    /*
     * fila = 0
     */

    movs r2, #0


char_row_loop:

    /*
     * máscara = 1 << fila
     */

    movs r0, #1
    lsls r0, r0, r2


    /*
     * ¿Pixel encendido?
     */

    tst r3, r0

    beq char_skip_pixel


    /*
     * Tenemos que preservar:
     *
     * r2 = fila
     * r3 = columna bitmap
     */

    push {r2, r3}


    /* X = baseX + columna */

    adds r0, r4, r7


    /* Y = baseY + fila */

    adds r1, r5, r2


    /* color = blanco */

    movs r2, #1


    bl draw_pixel


    pop {r2, r3}


char_skip_pixel:

    adds r2, r2, #1

    cmp r2, #7

    blt char_row_loop


    adds r7, r7, #1

    cmp r7, #5

    blt char_col_loop


char_end:

    pop {r3-r7, pc}



/* ============================================================
 * draw_text
 *
 * Entrada:
 *
 * r0 = X
 * r1 = Y
 * r2 = dirección string ASCII terminado en 0
 * ============================================================ */

.type draw_text, %function
.thumb_func

draw_text:

    push {r3-r7, lr}


    /* X */

    mov r4, r0


    /* Y */

    mov r5, r1


    /* cadena */

    mov r6, r2


text_loop:

    ldrb r7, [r6]


    cmp r7, #0

    beq text_end


    mov r0, r4
    mov r1, r5
    mov r2, r7

    bl draw_char5x7


    /*
     * 5 píxeles del carácter
     * + 1 píxel de separación
     */

    adds r4, r4, #6

    adds r6, r6, #1

    b text_loop


text_end:

    pop {r3-r7, pc}



/* ============================================================
 * draw_score3
 *
 * Dibuja número de 000 a 999.
 *
 * Entrada:
 *
 * r0 = X
 * r1 = Y
 * r2 = valor
 * ============================================================ */

.type draw_score3, %function
.thumb_func

draw_score3:

    push {r3-r7, lr}


    /* número */

    mov r4, r2


    /* X */

    mov r5, r0


    /* Y */

    mov r6, r1


    /* Si > 999 mostramos 999 */

    movw r3, #999

    cmp r4, r3

    bls score_valid

    mov r4, r3


score_valid:


    /* ========================================================
     * CENTENAS
     * ======================================================== */

    movs r7, #0


score_hundreds:

    cmp r4, #100

    blo score_hundreds_done

    subs r4, r4, #100

    adds r7, r7, #1

    b score_hundreds


score_hundreds_done:

    mov r0, r5
    mov r1, r6

    mov r2, r7
    adds r2, r2, #48

    bl draw_char5x7


    adds r5, r5, #6


    /* ========================================================
     * DECENAS
     * ======================================================== */

    movs r7, #0


score_tens:

    cmp r4, #10

    blo score_tens_done

    subs r4, r4, #10

    adds r7, r7, #1

    b score_tens


score_tens_done:

    mov r0, r5
    mov r1, r6

    mov r2, r7
    adds r2, r2, #48

    bl draw_char5x7


    adds r5, r5, #6


    /* ========================================================
     * UNIDADES
     * ======================================================== */

    mov r0, r5
    mov r1, r6

    mov r2, r4
    adds r2, r2, #48

    bl draw_char5x7


    pop {r3-r7, pc}



/* ============================================================
 * ui_draw
 *
 * HUD:
 *
 * SCORE 000                       LIVES 3
 * ============================================================ */

.type ui_draw, %function
.thumb_func

ui_draw:

    push {r4, lr}


    /* SCORE */

    movs r0, #0
    movs r1, #0

    ldr r2, =score_str

    bl draw_text


    /* Valor SCORE */

    movs r0, #34
    movs r1, #0

    ldr r2, =score
    ldr r2, [r2]

    bl draw_score3

        /* ========================================================
     * NIVEL
     *
     * Internamente:
     *   0, 1, 2
     *
     * Visualmente:
     *   LV1, LV2, LV3
     * ======================================================== */

    movs r0, #58
    movs r1, #0

    ldr r2, =level_str

    bl draw_text


    /* Dígito nivel */

    movs r0, #70
    movs r1, #0

    ldr r3, =level
    ldr r2, [r3]

    /* Nivel humano = nivel interno + 1 */

    adds r2, r2, #1

    /* ASCII */

    adds r2, r2, #48

    bl draw_char5x7


    /* LIVES */

    movs r0, #80
    movs r1, #0

    ldr r2, =lives_str

    bl draw_text


    /* Número de vidas */

    movs r0, #116
    movs r1, #0

    ldr r3, =lives
    ldr r2, [r3]

    adds r2, r2, #48

    bl draw_char5x7


    pop {r4, pc}



/* ============================================================
 * game_over_draw
 *
 * Dibuja pantalla de final de partida.
 * ============================================================ */
.type game_over_draw, %function
.thumb_func

game_over_draw:

    push {r4, lr}


    bl clear_buffer


    /* Línea */

    movs r0, #26
    movs r1, #14
    movs r2, #76
    movs r3, #1

    bl draw_hline


    /* GAME OVER */

    movs r0, #37
    movs r1, #20

    ldr r2, =game_over_str

    bl draw_text


    /* Línea */

    movs r0, #26
    movs r1, #30
    movs r2, #76
    movs r3, #1

    bl draw_hline


    /* SCORE */

    movs r0, #36
    movs r1, #36

    ldr r2, =score_str

    bl draw_text


    movs r0, #70
    movs r1, #36

    ldr r2, =score
    ldr r2, [r2]

    bl draw_score3


    /* Nivel alcanzado */

    movs r0, #48
    movs r1, #46

    ldr r2, =level_str

    bl draw_text


    movs r0, #62
    movs r1, #46

    ldr r3, =level
    ldr r2, [r3]

    adds r2, r2, #1
    adds r2, r2, #48

    bl draw_char5x7


    /* Reiniciar */

    movs r0, #43
    movs r1, #54

    ldr r2, =press_z_str

    bl draw_text


    pop {r4, pc}

/* ============================================================
 * menu_draw
 *
 * Pantalla inicial.
 * ============================================================ */
.type menu_draw, %function
.thumb_func

menu_draw:

    push {r4, lr}


    bl clear_buffer


    /* Línea decorativa superior */

    movs r0, #24
    movs r1, #10
    movs r2, #80
    movs r3, #1

    bl draw_hline


    /* Título */

    movs r0, #43
    movs r1, #16

    ldr r2, =frogger_str

    bl draw_text


    /* Línea bajo título */

    movs r0, #24
    movs r1, #26
    movs r2, #80
    movs r3, #1

    bl draw_hline


    /* Nuestra ranita */

    movs r0, #60
    movs r1, #32

    ldr r2, =frog_sprite

    bl draw_sprite8x8


    /* Instrucción */

    movs r0, #43
    movs r1, #48

    ldr r2, =press_z_str

    bl draw_text


    /* Línea inferior */

    movs r0, #34
    movs r1, #58
    movs r2, #60
    movs r3, #1

    bl draw_hline


    pop {r4, pc}