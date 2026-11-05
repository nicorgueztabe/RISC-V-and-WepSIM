begin
{
   fetch: (T2, C0),
          (TA, R, BW=11, M1=1, C1=1),
          (M2, C2, T1, C3),
          (A0, B=0, C=0)
}

nop {
     co=100001,
     nwords=1,
     {
        (A0=1, B=1, C=0000) # NO HACE NADA Y VUELVE A FETCH
  }
}

stop {
     co=100010,
     nwords=1,
     {
        ( MR=1,                 # usar selectores desde la microinstrucción
          SELA=00000,           # RA = R0 (zero)
          T9=1                                  # Saco 0 al bus interno
                # escribir 0 en SP y PC:
          SELC=10000,           # RC = R16 (sp)
          LC=1,                     # (SP ← 0)
          C2=1, M2=0,           # (PC ← 0)
          A0=1, B=1,C=0000      # volver a fetch (ahora PC=0 ⇒ ejecución detenida)
        )
     }
}

add reg1 reg2 {
     co=100011,
     nwords=1,
     reg1=reg(25,21),
     reg2=reg(20,16),
     {
    ( MR=0,
      SELA=10000, SELB=10101,   # A<-R2, B<-R1
      MA=0, MB=00,              # ALU toma A y B
      SELCOP=01010,             # ADD
      T6=1, LC=1, SELC=10000,   # C → R2
      SELP=11, M7, C7                       # cargar SR desde flags de ALU (CVNZ)
      A0=1, B=1, C=0000,MC=1    # volver a fetch
    )
  }
}
addi val reg1 {
     co=100100,
     nwords=1,
     val=imm(20,13),
     reg1=reg(25,21),
     {
      # Primer ciclo: RT2 <- val
      (SE, SIZE=1000, OFFSET=1101, T3=1, C5),                   # Trasladar el valor (val) del codigo de instruccion a RT2

      # Segundo ciclo: reg1 <- val+reg1 Y fetch  (ASI REDUCIMOS EL NUMERO DE CICLOS)
      (MR=0, SELA=10101, SELCOP=01010, MC=1, MA=0, MB=01, T6=1, # realizar la suma de val y reg1 y lo cargamos en el bus
       SELP=11, M7, C7,                                         # actualizar SR
       LC=1, SELC=10101,                                        # guardar el resultado de la suma en reg1
       A0=1, B=1, C=0000)                                       # volver a fetch
     }
}

lea val reg1 {
     co=100101,
     nwords=2,
     val=imm(63,32),
     reg1=reg(25,21),
     {
       # Primer ciclo:
       (T2,C0),                                                      # Cargar en MAR el valor de PC

       # Segundo ciclo: MBR <- Mem[MAR] Y PC <- PC+4 (ASI REDUCIMOS EL NUMERO DE CICLOS)
       (Ta=1, R=1, BW=11, M1=1, C1=1, SE=0,                # Guardar en MBR el valor U32, que esta almacenado en PC
        M2, C2),                                     # PC <- PC+4

       # Tercer ciclo: BR[IR(R1)] <- MBR Y fetch (ASI REDUCIMOS EL NUMERO DE CICLOS)
       (T1, LC=1, MR=0, SELC=10101,                 # BR[IR(R1)] <- MBR
        A0=1, B=1, C=0000)                                                  # Volver a fetch
     }
}

move val reg2 {
  co=100110,
  nwords=1,
  val=imm(15,0),
  reg2=reg(25,21),
  {
    # Primer ciclo: RF[reg2] <- val Y fetch (ASI REDUCIMOS EL NUMERO DE CICLOS)
    (SE=0, SIZE=10000, OFFSET=0, T3=1,   # Cargar el valor val desde el codigo de instruccion
    MR=0, SELC=10101, LC=1, MC=1,            # Mover val al registro correspondiente
    A0=1, B=1, C=0000)                   # Volver a fetch
    }
}

move reg1 reg2 {
     co=100111,
     nwords=1,
     reg1=reg(25,21),
     reg2=reg(20,16),
     {
       # Primer ciclo: RF[reg2] <- RF[reg1] Y fetch (ASI REDUCIMOS EL NUMERO DE CICLOS)
       (MR=0, SELA=10101, T9, # Cargar el valor de reg1 al bus
       SELC=10000, LC, MC=1,  # Mover el valor de reg1 a reg2
       A0=1, B=1, C=0000)     # Volver a fetch
     }
}


tst reg1 {
  co=101000,
  nwords=1,
  reg1=reg(25,21),
  {
   # Primer ciclo: SR.Z ← (R1 == 0) Y fetch (ASI REDUCIMOS EL NUMERO DE CICLOS)
   (MR=0, SELA=10101, SELB=10101,    # RA <- R1 y RB <- R1
    MA=0, MB=00,                               # Sumamos RA y RB
    SELCOP=01010,                              # R1 + R1 = 0 (SI R1 es 0) o != 0 (Si R1 NO es 0)
    SELP=11, M7, C7,                           # cargar SR desde flags de ALU → Z correcto
    MC=1,A0=1, B=1, C=0000)          # volver a fetch
     }
}


jmp val {
  co=101001,
  nwords=1,
  val=address(24,0)abs,                                 # Necesario para que sea la direccion absoluta la que es representada
  {
    # Primer ciclo: PC ← dirección_absoluta Y fetch (ASI REDUCIMOS CICLOS)
    (SE=0, SIZE=11001, OFFSET=00000, T3=1, M2=0, C2=1,  # Cargar en PC la direccion de memoria que se encuentra en val del codigo de instrucción
    A0=1, B=1, C=0000)                                  # Volver a fetch
    }
}


beq val {
     co=101010,
     nwords=1,
     val=address(24,0)abs,
     {
       # Primer ciclo: IF (Z == 0) GOTO bck2ftch
       (A0=0, B=1, C=0110, MADDR=bck2ftch),            # C = 6 en binario, 6 = Z en la UC. Para saltar necesito que Z=0, y salto si A0=0, y A1=1.
                                                       # Necesito programar de tal forma que si Z = 0, A1= 1.
       # Segundo ciclo (opcion A): PC ← dirección_absoluta Y fetch (ASI REDUCIMOS CICLOS)
       (SE=0,SIZE=11001,OFFSET=00000,T3=1,M2=0,C2=1,   # Cargar en PC la direccion de memoria que se encuentra en val del codigo de instruccion
        A0=1,B=1,C=0000)                               # Volver a fetch

   bck2ftch:
       # Segundo ciclo (opcion B):
       (A0=1, B=1, C=0000)                             # Volver a fetch
     }
}

bsr val {
     co=101011,
     nwords=1,
     val=address(24,0)rel,
     {
       # Primer ciclo: SP <- SP - 4 Y MAR <- SP (ASI REDUCIMOS CICLOS)
       (MR=1, SELA=10000, MC=1, SELCOP=01011, MA=0, MB=10, T6, SELC=10000, LC,       # SP <- SP-4
        C0),                                                                         # MAR <- SP

       # Segundo ciclo: MBR <- PC Y RT2 <- PC (ASI REDUCIMOS CICLOS)
       (T2, C1, M1=0, C5),

       # Tercer ciclo: MEM[SP] <- PC Y RT1 <- S25 (ASI REDUCIMOS CICLOS)
       (Ta, Td, SE=1, W, BW=11,                                         # MEM[SP] <- PC
        SE=1, SIZE=11001, OFFSET=0000, T3, C4),                         # RT1 <- S25

       # Cuarto ciclo:
       (MA=1, MB=10, MC=1, SELCOP=01100, T6, C4),                       # RT1 <- 4*S25

       # Quinto ciclo: PC <- PC + 4*S25 Y fetch (ASI REDUCIMOS CICLOS)
       (MA=1, MB=01, MC=1, SELCOP=01010, T6, M2=0, C2,                  # PC <- PC + 4*S25
        A0=1, B=1, C=0000)                                              # Volver a fetch
     }
}

rts {
        co = 101100,
    nwords = 1,
  {
      # Primer ciclo:
      (MR=1, SELA=10000, T9, C0),        # MAR <- SP

      # Segundo ciclo: MBR <- MEM[SP] Y SP <- SP + 4 (ASI REDUCIMOS CICLOS)
        (Ta, R, BW=11, M1=1, C1,                                                  # MBR <- MEM[SP]
       MR=1, SELA=10000, MC=1, SELCOP=01010, MA=0, MB=10, T6, SELC=10000, LC),  # SP <- SP+4

      # Tercer ciclo: PC <- MEM[SP] y fetch (ASI REDUCIMOS CICLOS)
      (T1, M2=0, C2,             # PC <- MEM[SP]
       A0=1, B=1, C=0000)        # Volver a fetch
  }
}

move.w (reg1) reg2 {
  co=101101,
  nwords=1,
  reg1=reg(25,21),
  reg2=reg(20,16),
    {
        # Primer ciclo:
            (MR=0, SELA=10101, T9, C0),   # MAR <- R1

        # Segundo ciclo:
        (Ta, R, BW=11, M1=1, C1),     # MBR <- MEM[R1]

        # Tercer ciclo: R2(RC) <- MEM[R1] Y fetch (ASI REDUCIMOS CICLOS)
        (T1, MR=0, SELC=10000, LC,    # R2(RC) <- MEM[R1]
         A0=1, B=1, C=0000)           # Volver al fetch
        }
}

# Read from I/O device
in reg val {
     co=111111,
     nwords=1,
     reg=reg(25,21),
     val=imm(15,0),
     {
         (SE=0, OFFSET=00000, SIZE=10000, T3=1, C0=1),
         (TA=1, IOR=1, BW=11, M1=1, C1=1),
         (T1=1, LC=1,  MR=0, SELC=10101, A0=1, B=1, C=0)
     }
}

# Write to I/O device
out reg val {
     co=111111,
     nwords=1,
     reg=reg(25,21),
     val=imm(15,0),
     {
         (SE=0, OFFSET=0,   SIZE=10000,   T3=1, C0=1),
         (MR=0, SELA=10101, T9=1,         M1=0, C1=1),
         (TA=1, TD=1,       IOW=1, BW=11, A0=1, B=1, C=0)
     }
}

# Read clock cycles from the internal control register
rdcycle reg1  {
      co=111111,
      nwords=1,
      reg1=reg(25,21),
      {
           (MH=1, T12=1, SELC=10101, LC=1, A0=1, B=1, C=0)
      }
}

registers
{
      0=(zero, x0),
      1=(d0, x1),
      2=(d1, x2),
      3=(d2, x3),
      4=(d3, x4),
      5=(d4, x5),
      6=(d5, x6),
      7=(d6, x7),
      8=(d7, x8),
      9=(a0, x9),
     10=(a1, x10),
     11=(a2, x11),
     12=(a3, x12),
     13=(a4, x13),
     14=(a5, x14),
     15=(a6, x15),
     16=(a7, sp, x16)(stack_pointer)
}
