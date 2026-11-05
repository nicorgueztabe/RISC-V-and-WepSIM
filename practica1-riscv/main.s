.data
Matrix: .zero 36        # 3x3 * 4 bytes = 9 * 4 = 36 bytes reservados
N:      .word 0        # tamaño de la matriz
a_val:  .float 1.5     # a = 1.0
b_val:  .float 0.5      # b = 2.0
c_val:  .float 2.5      # c = 2.0


.text
main:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Cargar parámetros
    la a0, Matrix       # dirección de inicio de la matriz
    la a1, N            # N = 3
    lw a1, 0(a1)
    la t0, a_val
    flw fa0, 0(t0)      # a = 1.0
    la t1, b_val
    flw fa1, 0(t1)      # b = 2.0
    la t2, c_val
    flw fa2, 0(t2)      # c = 2.0

    # Llamar a Compute_pows(Matrix, N, a, b, c)
    jal ra, Compute_pows

    # Imprimir matriz resultante
    la a0, Matrix
    la a1, N
    lw a1, 0(a1)
    jal ra, Print_matrix

    # Salir
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


# Print_matrix(A_ptr, N)
# a0 = &A[0]
# a1 = N
Print_matrix:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    mv s0, a0        # base matriz
    mv s1, a1        # N
    li s2, 0         # i (filas)
    li s4, 4         # tamaño de elemento (4 bytes)

Fila_loop:
    bge s2, s1, Fin_Print
    li s3, 0         # j = 0

Col_loop:
    bge s3, s1, Next_row
    mul t0, s2, s1   # i*N
    add t0, t0, s3   # i*N + j
    slli t0, t0, 2   # *4 bytes
    add t0, s0, t0   # &A[i][j]
    flw fa0, 0(t0)

    # imprimir float
    li a7, 2
    ecall

    # imprimir espacio
    la a0, ' '
    li a7, 11
    ecall

    addi s3, s3, 1
    j Col_loop

Next_row:
    # salto de línea
    la a0, '\n'
    li a7, 11
    ecall
    addi s2, s2, 1
    j Fila_loop

Fin_Print:
    lw ra, 20(sp)
    lw s0, 16(sp)
    lw s1, 12(sp)
    lw s2, 8(sp)
    lw s3, 4(sp)
    lw s4, 0(sp)
    addi sp, sp, 24
    jr ra


#-------------------------------------------------------------

#NOTA: Todas las veces que se utilizan los registros t o ft en nuestro programa es porque el valor que almacenan NO lo necesito mantener al volver del jal.

#EJERCICIO 1

#FUNCION FACTORIAL
# a0 = x
# devuelve a0 = x!
factorial:
    li  t1, 1         # t1 = 1  (acumulador)
    li  t0, 1         # t0 = 1  (i)

bucle:
    blt   a0, t0, fin       # if (i > x) -> fin
    mul   t1, t1, t0        # acc *= i
    addi  t0, t0, 1         # i =+ 1
    j     bucle

fin:
    mv    a0, t1            # return en a0
    jr    ra


#FUNCION BINOMIAL_COEF
# a0 = n, a1 = k
# return a0 = C(n,k) = n! / (k! * (n-k)!)
Binomial_coef:
    addi sp, sp, -20        # reserva frame
    sw   ra, 16(sp)
    sw   s0, 12(sp)
    sw   s1, 8(sp)
    sw   s2, 4(sp)
    sw   s3, 0(sp)

    mv   s0, a0              # s0 = n
    mv   s1, a1              # s1 = k

    # n!
    mv   a0, s0
    jal  ra, factorial
    mv   s2, a0              # s2 = n!

    # k!
    mv   a0, s1
    jal  ra, factorial
    mv   s3, a0              # s3 = k!

    # (n-k)!
    sub  a0, s0, s1
    jal  ra, factorial       # a0 = (n-k)!
    mul  a0, a0, s3          # (n-k)! * k!
    div  a0, s2, a0          # n! / ((n-k)! * k!)

    lw   s3, 0(sp)
    lw   s2, 4(sp)
    lw   s1, 8(sp)
    lw   s0, 12(sp)
    lw   ra, 16(sp)
    addi sp, sp, 20
    jr   ra

#FUNCION NEWTON_INT
# a0 = n; fa0 = a; fa1 = b
#return fa0 = (a + b)^n
Newton_int:
    addi sp,sp, -40
    sw   ra, 36(sp)
    sw   s0, 32(sp)     # n
    sw   s1, 28(sp)     # k
    fsw   fs0, 24(sp)   # a
    fsw   fs1, 20(sp)   # b
    fsw   fs2, 16(sp)   # resultado
    fsw   fs3, 12(sp)   # potencia1
    fsw  fs4, 8(sp)     # potencia2
    fsw  fs5, 4(sp)     # comb
    fsw  fs6, 0(sp)     # aux

    fmv.w.x fs2, x0 # fs2 = resultado = 0.0 (Copio el valor de un registro vacio)
    li s1, 0        # s1 = contador (k)
    fmv.s fs0, fa0  # fs0 = a
    fmv.s fs1, fa1  # fs1 = b
    mv s0, a0       # s0 = n
while:
    bgt s1,s0, end  # while k <= n
    # comb = C(n,k) (int) -> comb_f (float en fs5)
    mv a0,s0
    mv a1, s1
    jal ra, Binomial_coef
    fcvt.s.w fs5, a0        # fs5 = Binomial_coef(n,k) Paso de un entero con signo a un simple precision
    # pot1 = pow(a, n-k)
    fmv.s fa0, fs0
    sub a0,s0,s1
    jal ra, pow
    fmv.s fs3, fa0  # fs3 = pow(a,(n-k))
    # pot2 = pow(b, k)
    fmv.s fa0, fs1
    mv a0, s1
    jal ra, pow
    fmv.s fs4, fa0  # fs4 = pow(b,k)
    # aux = comb_f * pot1 * pot2
    fmul.s fs6,fs5,fs3
    fmul.s fs6,fs6,fs4
    fadd.s fs2,fs2,fs6  # fs2 = fs5 * fs3 * fs4
    addi s1,s1,1    # k += 1
    j while

end:
    fmv.s fa0,fs2
    lw   ra, 36(sp)
    lw   s0, 32(sp)
    lw   s1, 28(sp)
    flw   fs0, 24(sp)
    flw   fs1, 20(sp)
    flw   fs2, 16(sp)
    flw   fs3, 12(sp)
    flw  fs4, 8(sp)
    flw  fs5, 4(sp)
    flw  fs6, 0(sp)
    addi sp,sp, 40
    jr ra


#----------------------------------------------------------------------------------------------
#EJERCICIO 2

# Funcion Newton_real
# Calcula (a+b)^n usando el binomio de Newton
# Parametros: fa0=a, fa1=b, fa2=n
# Retorna: fa0 = resultado (o NaN si n < 0)

Newton_real:
    # Guardar todo en la pila
    addi sp, sp, -44        # Necesito mucho espacio (44 bytes = 11 words), uso muchos registros salvados
    sw ra, 40(sp)           # ra va al final, offset 40
    fsw fs0, 36(sp)         # fs0 guarda 'a', uso fsw porque es float
    fsw fs1, 32(sp)         # fs1 guarda 'b'
    fsw fs2, 28(sp)         # fs2 guarda 'n', el exponente
    fsw fs3, 24(sp)         # fs3 sera el contador k del bucle
    fsw fs4, 20(sp)         # fs4 es el acumulador, ahi sumo todos los terminos
    fsw fs5, 16(sp)         # fs5 guarda el limite (20), podria ser define pero asi es mas flexible
    fsw fs6, 12(sp)         # fs6 es el incremento (1.0), para sumar a k
    fsw fs7, 8(sp)          # fs7 guarda el coeficiente binomial C(n,k)
    fsw fs8, 4(sp)          # fs8 guarda a^(n-k)
    fsw fs9, 0(sp)          # fs9 guarda b^k, offset 0 es el ultimo

    # Copiamos los parametros a registros salvados
    fmv.s fs0, fa0          # Muevo a a fs0, asi no pierdo el valor en llamadas recursivas
    fmv.s fs1, fa1          # Muevo b a fs1, fa1 se puede sobreescribir
    fmv.s fs2, fa2          # Muevo n a fs2, necesito preservarlo

    # Verificar si n < 0 (devolver NaN en ese caso)
    fcvt.s.w ft0, zero      # Convierto 0 entero a float 0.0 en ft0
    flt.s t1, fs2, ft0      # flt.s pone 1 en t1 si fs2 < ft0, osea si n < 0
    li t2, 0                # Cargo 0 en t2 para comparar
    bne t1, t2, newton_retornar_nan  # Si t1 != 0 (osea n < 0), salto a retornar NaN

    # Inicializamos el acumulador en 0
    fcvt.s.w fs4, zero      # fs4 = 0.0, ahi voy a sumar los terminos del binomio
    fmv.s fs3, fs4          # k = 0.0, empiezo desde el primer termino

    # Preparamos las constantes que vamos a usar
    li t0, 1                # Cargo 1 entero
    fcvt.s.w fs6, t0        # Convierto a 1.0 float, lo uso para incrementar k

    li t0, 6               # Cargo 6, es el numero de terminos que voy a calcular. Aunque en la practica se indiquen 20 iteraciones, para evitar desbordamientos, hemos empleado 6
    fcvt.s.w fs5, t0        # Convierto a 6.0 float, limite del bucle.

newton_bucle:
    # Comprobamos si ya hemos terminado (k > 6)
    fle.s t0, fs5, fs3      # fle.s pone 1 en t0 si 6.0 <= k
    li t1, 1                # Cargo 1 para comparar
    beq t0, t1, newton_fin  # Si k >= 6, ya termine, salto al final

    # Paso 1: Calcular el coeficiente binomial C(n,k)
    fmv.s fa0, fs2          # Paso n en fa0, primer parametro de Coef_Binom_Gen
    fmv.s fa1, fs3          # Paso k en fa1, segundo parametro
    jal ra, Coef_Binom_Gen  # Llamo a la funcion, resultado vuelve en fa0
    fmv.s fs7, fa0          # Guardo C(n,k) en fs7, lo necesito despues

    # Paso 2: Calcular a^(n-k)
    fsub.s ft0, fs2, fs3    # ft0 = n - k, calculo el exponente
    fmv.s fa0, fs0          # fa0 = a, es la base
    fmv.s fa1, ft0          # fa1 = n-k, es el exponente
    jal ra, powf            # Llamo a powf para calcular a^(n-k)
    fmv.s fs8, fa0          # Guardo a^(n-k) en fs8

    # Paso 3: Calcular b^k
    fmv.s fa0, fs1          # fa0 = b, base
    fmv.s fa1, fs3          # fa1 = k, exponente
    jal ra, powf            # Llamo a powf para b^k
    fmv.s fs9, fa0          # Guardo b^k en fs9

    # Paso 4: Multiplicar todo y acumular
    # termino = C(n,k) * a^(n-k) * b^k
    fmul.s ft0, fs7, fs8    # ft0 = C(n,k) * a^(n-k), primera multiplicacion
    fmul.s ft0, ft0, fs9    # ft0 = ft0 * b^k, completo el termino
    fadd.s fs4, fs4, ft0    # suma += termino, acumulo en fs4

    # Incrementamos k para la siguiente iteracion
    fadd.s fs3, fs3, fs6    # k = k + 1.0, uso fs6 que tiene el 1.0
    j newton_bucle          # Salto incondicional al inicio del bucle

newton_retornar_nan:
    # Cargamos NaN (0x7FC00000) en fa0
    li t0, 0x7FC00000       # Este patron de bits representa NaN en IEEE 754
    fmv.w.x fa0, t0         # Muevo el patron de bits a fa0, fmv.w.x trata como raw bits
    j newton_salir          # Salto a salir

newton_fin:
    # Ya terminamos, devolvemos el resultado
    fmv.s fa0, fs4          # Muevo el acumulador a fa0, es el return value

newton_salir:
    # Recuperamos todo de la pila
    lw ra, 40(sp)           # Recupero ra, crucial para retornar
    flw fs0, 36(sp)         # Recupero fs0, flw es load float word
    flw fs1, 32(sp)         # Recupero fs1
    flw fs2, 28(sp)         # Recupero fs2
    flw fs3, 24(sp)         # Recupero fs3
    flw fs4, 20(sp)         # Recupero fs4
    flw fs5, 16(sp)         # Recupero fs5
    flw fs6, 12(sp)         # Recupero fs6
    flw fs7, 8(sp)          # Recupero fs7
    flw fs8, 4(sp)          # Recupero fs8
    flw fs9, 0(sp)          # Recupero fs9
    addi sp, sp, 44         # Libero los 44 bytes, importante hacer el cleanup
    jr ra                   # Retorno al caller usando ra


# Funcion powf
# Calcula a^b (potencia con exponentes reales)
# Parametros: fa0=a (base), fa1=b (exponente)
# Retorna: fa0 = a^b

powf:
    # Guardamos registros en la pila
    addi sp, sp, -16        # Reservo 16 bytes, 4 words
    sw ra, 12(sp)           # Guardo ra en offset 12
    fsw fs0, 8(sp)          # fs0 guardara 'a'
    fsw fs1, 4(sp)          # fs1 guardara 'b'
    fsw fs2, 0(sp)          # fs2 es temporal, por si acaso

    fmv.s fs0, fa0          # Copio a a fs0
    fmv.s fs1, fa1          # Copio b a fs1

    # Necesitamos el cero para comparaciones
    fcvt.s.w ft0, zero      # ft0 = 0.0, lo uso para comparar

    # Caso especial: si a = 0 y b > 0, resultado = 0
    feq.s t1, fs0, ft0      # t1 = 1 si a == 0.0
    li t2, 0                # Cargo 0 para comparar
    bne t1, t2, powf_a_es_cero  # Si a == 0, voy a verificar b
    j powf_no_cero          # Si a != 0, continuo normal

powf_a_es_cero:
    # Verificamos si b > 0
    flt.s t2, ft0, fs1      # t2 = 1 si 0.0 < b
    li t3, 0                # Cargo 0 para comparar
    bne t2, t3, powf_retornar_cero  # Si b > 0, 0^positivo = 0
    j powf_no_cero          # Si b <= 0, es caso especial, sigo normal

powf_retornar_cero:
    fmv.s fa0, ft0          # Devuelvo 0.0
    j powf_fin              # Salto al final

powf_no_cero:
    # Caso especial: si b = 0, resultado = 1
    feq.s t1, fs1, ft0      # t1 = 1 si b == 0.0
    li t2, 0                # Cargo 0
    bne t1, t2, powf_retornar_uno  # Si b == 0, cualquier cosa^0 = 1
    j powf_calculo          # Si b != 0, calculo normal

powf_retornar_uno:
    li t0, 1                # Cargo 1 entero
    fcvt.s.w fa0, t0        # Convierto a 1.0 y lo pongo en fa0
    j powf_fin              # Salto al final

powf_calculo:
    # Caso general: a^b = e^(b * ln(a))
    # Esta formula matematica funciona para exponentes reales
    # Primero calculamos ln(a)
    fmv.s fa0, fs0          # Paso a como parametro
    jal ra, Ln              # Llamo a Ln, resultado en fa0
    fmv.s fs2, fa0          # Guardo ln(a) en fs2

    # Multiplicamos b * ln(a)
    fmul.s fa0, fs1, fs2    # fa0 = b * ln(a)

    # Calculamos e^(b * ln(a))
    jal ra, E               # Llamo a E, resultado en fa0

powf_fin:
    # Recuperamos registros y salimos
    flw fs2, 0(sp)          # Recupero fs2
    flw fs1, 4(sp)          # Recupero fs1
    flw fs0, 8(sp)          # Recupero fs0
    lw ra, 12(sp)           # Recupero ra
    addi sp, sp, 16         # Libero los 16 bytes
    jr ra                   # Retorno


# Funcion E
# Calcula e^x usando serie de Taylor
# Parametros: fa0=x
# Retorna: fa0 = e^x

E:
    # Guardamos registros
    addi sp, sp, -8        # Reservo 8 bytes para 2 words
                            # NO hace falta guardar ra porque es funcion terminal
    fsw fs0, 4(sp)          # fs0 guardara x (Utilizamos registros s, por lo que tenemos que guardarlos en pila)
    fsw fs1, 0(sp)          # fs1 guardara el termino actual

    fmv.s fs0, fa0          # Copio x a fs0

    # Inicializamos suma = 1.0 y termino = 1.0
    # La serie es: 1 + x + x^2/2! + x^3/3! + ...
    # Empiezo con el primer termino que es 1
    li t0, 1                # Cargo 1
    fcvt.s.w fa0, t0        # fa0 = 1.0, es mi suma inicial
    fmv.s fs1, fa0          # fs1 = 1.0, es mi termino inicial

    li t0, 1                # k = 1, empiezo en el segundo termino
    li t1, 20               # Voy a calcular 20 terminos, da buena precision

e_bucle:
    bge t0, t1, e_fin       # Si k >= 20, termino el bucle

    # Calculamos el siguiente termino
    # termino = termino * x / k
    fmul.s fs1, fs1, fs0    # fs1 *= x, voy construyendo x^k/k!
    fcvt.s.w ft0, t0        # Convierto k a float
    fdiv.s fs1, fs1, ft0    # fs1 /= k, divido por el factorial incrementalmente

    # Sumamos el termino al resultado
    fadd.s fa0, fa0, fs1    # suma += termino

    # Incrementamos k
    addi t0, t0, 1          # k++, uso addi porque es entero
    j e_bucle               # Vuelvo al inicio

e_fin:
    # Restauramos y salimos
    flw fs1, 0(sp)          # Recupero fs1
    flw fs0, 4(sp)          # Recupero fs0
    addi sp, sp, 8         # Libero 8 bytes
    jr ra                   # Retorno


# Funcion Ln
# Calcula logaritmo natural usando serie de Taylor
# Parametros: fa0=x
# Retorna: fa0 = ln(x) (o NaN si x < 0)

Ln:
    # Guardamos registros
    addi sp, sp, -16        # Necesito 16 bytes, uso varios floats
                            # NO hace falta guardar ra porque es funcion terminal.(Utilizamos registros s, por lo que tenemos que guardarlos en pila)
    fsw fs0, 12(sp)         # fs0 = x
    fsw fs1, 8(sp)          # fs1 = y = (x-1)/(x+1)
    fsw fs2, 4(sp)          # fs2 = resultado acumulado
    fsw fs3, 0(sp)          # fs3 = y^2, lo precalculo

    fmv.s fs0, fa0          # Copio x a fs0

    # Verificar si x < 0 (devolver NaN en ese caso)
    fcvt.s.w ft0, zero      # ft0 = 0.0
    flt.s t1, fs0, ft0      # t1 = 1 si x < 0, ln de negativos no existe
    li t2, 0                # Cargo 0
    bne t1, t2, ln_retornar_nan  # Si x < 0, retorno NaN

    # Usamos la formula: ln(x) = 2 * sum( y^(2k+1) / (2k+1) )
    # donde y = (x-1)/(x+1)
    # Esta formula converge mas rapido que la serie basica
    li t0, 1                # Cargo 1
    fcvt.s.w ft0, t0        # ft0 = 1.0
    fsub.s ft1, fs0, ft0    # ft1 = x - 1
    fadd.s ft2, fs0, ft0    # ft2 = x + 1
    fdiv.s fs1, ft1, ft2    # fs1 = y = (x-1)/(x+1)

    # Iniciamos el resultado en 0
    fcvt.s.w fs2, zero      # fs2 = 0.0

    # Calculamos y^2 (lo usaremos mucho)
    fmul.s fs3, fs1, fs1    # fs3 = y^2, lo precalculo para ahorrar operaciones

    # El primer termino es y
    fmv.s ft3, fs1          # ft3 = y, es el termino actual

    li t0, 0                # k = 0
    li t1, 20               # 20 terminos

ln_bucle:
    bge t0, t1, ln_fin      # Si k >= 20, termino

    # Calculamos el denominador: 2*k + 1
    li t2, 2                # Cargo 2
    mul t3, t0, t2          # t3 = 2*k
    addi t3, t3, 1          # t3 = 2*k + 1
    fcvt.s.w ft4, t3        # Convierto a float

    # Dividimos el termino actual por (2k+1) y lo sumamos
    fdiv.s ft5, ft3, ft4    # ft5 = y^(2k+1) / (2k+1)
    fadd.s fs2, fs2, ft5    # Sumo al resultado

    # Actualizamos el termino: multiplicamos por y^2
    fmul.s ft3, ft3, fs3    # ft3 *= y^2, siguiente potencia impar

    addi t0, t0, 1          # k++
    j ln_bucle              # Vuelvo al bucle

ln_retornar_nan:
    # Cargamos NaN (0x7FC00000) en fa0
    li t0, 0x7FC00000       # Patron de bits para NaN
    fmv.w.x fa0, t0         # Lo muevo a fa0
    j ln_salir              # Salgo

ln_fin:
    # Multiplicamos por 2 (formula del ln)
    li t0, 2                # Cargo 2
    fcvt.s.w ft0, t0        # Convierto a 2.0
    fmul.s fa0, fs2, ft0    # fa0 = suma * 2

ln_salir:
    # Restauramos y salimos

    flw fs0, 12(sp)         # Recupero fs0
    flw fs1, 8(sp)          # Recupero fs1
    flw fs2, 4(sp)          # Recupero fs2
    flw fs3, 0(sp)          # Recupero fs3
    addi sp, sp, 16         # Libero 16 bytes
    jr ra                   # Retorno


# Funcion Factorial
# Calcula n! (solo para enteros)
# Parametros: fa0=n (como float pero sera convertido a entero)
# Retorna: fa0 = n!

Factorial:
    # Guardamos registros
    addi sp, sp, -8        # 8 bytes para 2 words
    fsw fs0, 4(sp)          # fs0 = n original
    fsw fs1, 0(sp)          # fs1 = resultado

    # Convertimos el float a entero
    fcvt.w.s a0, fa0        # a0 = (int)n, trunco la parte decimal
    mv t0, a0               # t0 = n, lo copio

    # Verificamos que n >= 0
    li t2, 0                # Cargo 0
    blt t0, t2, factorial_error  # Si n < 0, factorial no existe

    # Verificamos si n == 0 (caso especial: 0! = 1)
    li t3, 0                # Cargo 0
    bne t0, t3, factorial_no_cero  # Si n != 0, calculo normal
    j factorial_cero        # Si n == 0, retorno 1

factorial_no_cero:
    # Iniciamos resultado = 1.0
    li t1, 1                # Cargo 1
    fcvt.s.w fs1, t1        # fs1 = 1.0

factorial_bucle:
    blez t0, factorial_fin  # Si t0 <= 0, ya termine

    # Multiplicamos resultado por t0
    fcvt.s.w ft0, t0        # Convierto t0 a float
    fmul.s fs1, fs1, ft0    # resultado *= t0

    # Decrementamos t0
    addi t0, t0, -1         # t0--, voy bajando hasta 1
    j factorial_bucle       # Vuelvo

factorial_cero:
    # 0! = 1 por definicion
    li t1, 1                # Cargo 1
    fcvt.s.w fs1, t1        # fs1 = 1.0
    j factorial_fin         # Salgo

factorial_error:
    # Si n < 0, devolvemos 0 (error)
    fcvt.s.w fs1, zero      # fs1 = 0.0, indico error

factorial_fin:
    # Devolvemos el resultado
    fmv.s fa0, fs1          # Muevo resultado a fa0
    flw fs1, 0(sp)          # Recupero fs1
    flw fs0, 4(sp)          # Recupero fs0
    addi sp, sp, 8          # Libero 12 bytes
    jr ra                   # Retorno


# Funcion Coef_Binom_Gen
# Calcula el coeficiente binomial generalizado
# C(n,k) = n(n-1)(n-2)...(n-k+1) / k!
# Parametros: fa0=n (puede ser real), fa1=k (entero)
# Retorna: fa0 = C(n,k)

Coef_Binom_Gen:
    # Guardamos registros
    addi sp, sp, -20        # 20 bytes para 5 words
    sw ra, 16(sp)           # Guardo ra
    fsw fs0, 12(sp)         # fs0 = n
    fsw fs1, 8(sp)          # fs1 = k
    fsw fs2, 4(sp)          # fs2 = producto del numerador
    fsw fs3, 0(sp)          # fs3 = k! (denominador)

    fmv.s fs0, fa0          # Copio n a fs0
    fmv.s fs1, fa1          # Copio k a fs1

    # Verificamos que k >= 0
    fcvt.s.w ft0, zero      # ft0 = 0.0
    flt.s t1, fs1, ft0      # t1 = 1 si k < 0
    li t2, 0                # Cargo 0
    bne t1, t2, coef_cero   # Si k < 0, C(n,k) = 0

    # Convertimos k a entero para el bucle
    fcvt.w.s t0, fs1        # t0 = (int)k

    # Si k == 0, C(n,0) = 1
    li t1, 0                # Cargo 0
    beq t0, t1, coef_uno    # Si k == 0, retorno 1

    # Inicializamos el producto del numerador en 1.0
    li t1, 1                # Cargo 1
    fcvt.s.w fs2, t1        # fs2 = 1.0

    # Calculamos el producto n(n-1)(n-2)...(n-k+1)
    li t1, 0                # i = 0
coef_producto_bucle:
    bge t1, t0, coef_producto_fin   # Si i >= k, termine el producto

    # Convertimos i a float
    fcvt.s.w ft1, t1        # ft1 = (float)i

    # Calculamos (n - i)
    fsub.s ft2, fs0, ft1    # ft2 = n - i

    # Multiplicamos al producto acumulado
    fmul.s fs2, fs2, ft2    # numerador *= (n - i)

    # Incrementamos i
    addi t1, t1, 1          # i++
    j coef_producto_bucle   # Vuelvo

coef_producto_fin:
    # Ahora calculamos k!
    fmv.s fa0, fs1          # Paso k como parametro
    jal ra, Factorial       # Llamo a Factorial
    fmv.s fs3, fa0          # Guardo k! en fs3

    # Calculamos C(n,k) = numerador / k!
    fdiv.s fa0, fs2, fs3    # fa0 = numerador / k!
    j coef_fin              # Salgo

coef_uno:
    # C(n,0) = 1 siempre
    li t1, 1                # Cargo 1
    fcvt.s.w fa0, t1        # fa0 = 1.0
    j coef_fin              # Salgo

coef_cero:
    # Si k < 0, devolvemos 0
    fcvt.s.w fa0, zero      # fa0 = 0.0

coef_fin:
    # Restauramos y salimos
    lw ra, 16(sp)           # Recupero ra
    flw fs0, 12(sp)         # Recupero fs0
    flw fs1, 8(sp)          # Recupero fs1
    flw fs2, 4(sp)          # Recupero fs2
    flw fs3, 0(sp)          # Recupero fs3
    addi sp, sp, 20         # Libero 20 bytes
    jr ra                   # Retorno

#-------------------------------------------------------------------------------------
#EJERCICIO 3

# Compute_pows(A_ptr, N, a, b, c)
# a0 = &A[0]
# a1 = N       (int)
# fa0 = a      (float)
# fa1 = b      (float)
# fa2 = c      (float)

Compute_pows:
    addi sp, sp, -40
    sw   ra, 36(sp)
    sw   s0, 32(sp)     # s0 = base A
    sw   s1, 28(sp)     # s1 = N
    sw   s2, 24(sp)     # s2 = i
    sw   s3, 20(sp)     # s3 = j
    sw   s4, 16(sp)     # s4 = indice
    sw   s5, 12(sp)     # s5 = tamano de cada elemento de la matriz (4)
    fsw  fs0, 8(sp)    # fs0 = a
    fsw  fs1, 4(sp)    # fs1 = b
    fsw  fs2, 0(sp)    # fs2 = c


    mv    s0, a0        # base de la matriz
    mv    s1, a1        # N
    fmv.s fs0, fa0      # a
    fmv.s fs1, fa1      # b
    fmv.s fs2, fa2      # c
    li    s2, 0         # i = 0
    li    s5, 4         # Empleo el 4 para hallar la direccion de A[i][j]; 4 = p = tamano del elemento

Bucle_Filas:
    bge   s2, s1, fin_matriz    # if i >= N ve a fin
    li    s3, 0         # j = 0 y pasa a Bucle_Columnas que esta debajo


Bucle_Columnas:
    bge   s3, s1, Next_Fila # if j >= N ve a Next_Fila

    # fa0 = a + float(i)
    fcvt.s.w ft0, s2        # Meto en ft0 el valor de i convertido a float, NO lo guardo en pila porque al volver del jal NO lo necesito mantener
    fadd.s   fa0, fs0, ft0

    # fa1 = b + float(j)
    fcvt.s.w ft1, s3        # Meto en ft1 el valor de j convertido a float, NO lo guardo en pila porque al volver del jal NO lo necesito mantener
    fadd.s   fa1, fs1, ft1

    # fa2 = c
    fmv.s    fa2, fs2

    # llamar: Newton_real(a+i, b+j, c) -> fa0
    jal  ra, Newton_real

    # direccion de A[i][j]
    mul   s4, s2, s1     # i*N
    add   s4, s4, s3     # i*N + j
    mul  s4, s4, s5      # *4 bytes
    add   s4, s4, s0     # &A[i*N+j]

    # guardar el resultado proveniente de Newton_real (almacenado en fa0)
    fsw   fa0, 0(s4)

    addi  s3, s3, 1
    j     Bucle_Columnas

Next_Fila:
    addi  s2, s2, 1
    j     Bucle_Filas


fin_matriz:
    lw   ra, 36(sp)
    lw   s0, 32(sp)
    lw   s1, 28(sp)
    lw   s2, 24(sp)
    lw   s3, 20(sp)
    lw   s4, 16(sp)
    lw   s5, 12(sp)
    flw  fs0, 8(sp)
    flw  fs1, 4(sp)
    flw  fs2, 0(sp)
    addi sp, sp, 40
    jr   ra
