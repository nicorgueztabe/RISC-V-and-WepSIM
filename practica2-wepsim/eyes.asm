.data
#Posicion inicial ojos
m1: .byte
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1, 1,1,1,0,0,0,1,1, 1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1, 1,1,1,0,0,0,1,1, 1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1, 1,1,1,0,0,0,1,1, 1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1, 1,1,1,0,0,0,1,1, 1,1,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

#Ojos cerrados
m2: .byte
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,1, 1,1,1,0,0,0,0,1, 1,1,1,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

#Ojos mirando a la derecha
m3r: .byte
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 1,1,1,1,1,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 1,1,1,1,1,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,1,1,1,0,0,0, 1,1,1,1,1,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,1,1,1,0,0,0, 1,1,1,1,1,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

#Ojos mirando a la izquierda
m3l: .byte
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,1,1, 1,1,1,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,1,1, 1,1,1,0,0,0,1,1, 1,0,0,0,0,0,0,0,
     0,0,0,0,0,0,1,1, 1,1,1,0,0,0,1,1, 1,0,0,0,0,0,0,0,
     0,0,0,0,0,0,1,1, 1,1,1,0,0,0,1,1, 1,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

#Lista de los punteros a las distintas matrices para animar los ojos del personaje
seq1: .word m2, m3r, m3l, m2, 0x0

.text
# Comparacion de registros; a0 = x9, t0 = x1, t1 = x2; s0 = x10
show_eyes:
        # Los valores 0x3108, 0x3100 y 0x3104 son puntos fisicos de hardware indicados en el enunciado. No podemos poner etiquetas en su lugar

    # out a0, 0x3108; dirección base de la imagen
    out x9 0x3108

    # t0 = 8 → número de filas
    move 0x8 x1            # el move es equivalente al li de RISCV; li t0, 0x8 = move 0x8, x1
    out  x1 0x3100     # out numero de filas

    # t0 = 0x80 → activar DMA. El DMA sirve para pintar la imagen.
    move 0x80 x1
    out  x1 0x3104     # configurar el control del DMA

    # el retardo sirve para poder esperar un tiempo antes de mostrar la siguiente imagen, y conseguir así una animación visible;
    move 20 x1         # t0 = 20
w1:
    tst x1             # Z=1 si t0==0
    beq f1             # if Z==1 → salir del bucle
    addi -1 x1         # t0 = t0 - 1
    jmp w1                       # vuelve a w1
f1:
    rts                              # sale de la funcion


main:

    lea m1 x9          # la a0, m1. Carga la dirección de inicio de m1 en a0
    rdcycle x4         # t3 = ciclos antes de show_eyes
    bsr show_eyes      # llamada a subrutina show_eyes
    rdcycle x5         # t4 = ciclos después de show_eyes


    lea seq1 x10       # la  s0, seq1; Metemos en s0 la dirección de inicio de seq1

w2:
    move.w (x10) x9    # a0 = MEM[s0]; Meto en a0 lo que hay en la posicion de memoria que almacena s0; lw  a0, 0(s0); cargo nueva posicion en a0

    # if (a0 == 0) salto a e2
    tst x9                       # Z=1 si a0==0; Cuando lleguemos al final de la lista de seq1 saldremos del bucle
    beq e2                       # if Z==1 → salir del bucle

    # show_eyes(a0)
    bsr show_eyes

    # show_eyes(m1)
    lea m1 x9                    # la a0, m1. Carga la dirección de inicio de m1 en a0; muestra la posicion inicial de los ojos entre posicion y posicion
    bsr show_eyes

    # s0 = s0 + 4 (avanzar al siguiente puntero en seq1, para cambiar asi la posicion de los ojos)
    addi 4 x10

    jmp w2                    # vuelve a w2

e2:
    stop                          # jr ra

# El número total de ciclos del main es 4719-1=4718, y el de show_eyes es 508 (519-11); 11=Ciclos necesarios para llegar al bsr show_eyes y 508=Ciclos desde que llega a bsr show_eyes hasta que sale de rdcycle x2. (En la Tabla 3 del enunciado los ciclos de show_eyes se calculan igual).
