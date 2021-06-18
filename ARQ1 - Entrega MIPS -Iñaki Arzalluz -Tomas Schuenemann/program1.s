.data 
num0: .word 1 # posic 0
num1: .word 2 # posic 4
num2: .word 4 # posic 8 
num3: .word 8 # posic 12 
num4: .word 16 # posic 16 
num5: .word 32 # posic 20
num6: .word 0 # posic 24
num7: .word 0 # posic 28
num8: .word 0 # posic 32
num9: .word 0 # posic 36
num10: .word 0 # posic 40
num11: .word 0 # posic 44
.text 
main:
  lw $t1, 0($zero) //carga un 1 en reg9
  lw $t2, 4($zero) //carga un 2 en reg10
  lw $t3, 8($zero) //carga un 4 en reg11
  lw $t4, 12($zero) //carga un 8 en reg12
  lw $t5, 16($zero) //carga un 16d en reg13 (10h)
  lw $t6, 20($zero) //carga un 32d en reg14 (20h)
  sw $t1, 24($zero) //guarda en pos24 de datamem el dato en reg9 (un 1) 
  sw $t2, 28($zero) //guarda en pos28 de datamem el dato en reg10 (un 2)
  sw $t3, 32($zero) //guarda en pos32 de datamem el dato en reg11 (un 4)
  sw $t4, 36($zero) //guarda en pos36 de datamem el dato en reg12 (un 8)
  sw $t5, 40($zero) //guarda en pos40 de datamem el dato en reg13 (un 16) (10h)
  sw $t6, 44($zero) //guarda en pos44 de datamem el dato en reg14 (un 32) (20h)
  lw $t1, 24($zero) //carga un 1 reg9
  lw $t2, 28($zero) //carga un 2 reg10
  lw $t3, 32($zero) //carga un 4 reg11
lab1:
  lw $t4, 36($zero) //carga un 8 en reg12
  lw $t5, 40($zero) //carga un 16 en reg13
  lw $t6, 44($zero) //carga un 32 en reg14
  add $t7, $t1, $t2 //guarda en reg15 un 1+2 
  add $s0, $t3, $t4 //guarda en reg16 un 4+8
  sub $s1, $t5, $t1 //guarda en reg17 un 16-1
  sub $s2, $t6, $t2 //guarda en reg18 un 32-2
  and $s3, $t1, $t2 //guarda en reg19 un 01 and 10
  and $s4, $t7, $t2 //guarda en reg20 un 011 and 010
  or $s5, $t1, $t2  //guarda en reg21 un 01 or 10
  or $s6, $s0, $t2  //guarda en reg22 un (4+8)bin or 0010
  slt $s7, $t1, $t2 //guarda en reg23 un 01
  slt $t8, $s0, $t2 //guarda en reg24 un 00
  lui $t1, 1
  lui $t2, 2
  addi $t3, $t3, 6
  ori $t4, $t4, 112
  andi $t7, $t7, 2
  

