		AREA datos,DATA
VICIntEnabl		EQU 0xFFFFF010
VICIntEnClr		EQU 0xFFFFF014
	
VICVectAddr 	EQU 0xFFFFF030
VICVectAddr0	EQU 0xFFFFF100

UART_RDAT		EQU 0xE0010000

I_Bit 			EQU 0x80
T0_IR			EQU 0xE0004000

semilla 		EQU 55
	
pos_r1			DCD 0			; empezando desde abajo
pos_r2			DCD 0
pos_pelota		DCD 0
	
puntosA			DCD 0
puntosB			DCD 0
	
pelota			EQU '*'
raqueta			EQU 'X'

crono 			DCD 0 			; contador de centesimas de segundo
max				DCD 8 			; velocidad de movimiento en centesimas s. 
next 			DCD 0			; instante siguiente movimiento pelota
next1			DCD 0			; instante siguiente movimiento raqueta1
dir1			DCB	0			; mov raqueta izda (-1 arriba, 0 stop, 1 abajo)
dir2			DCB 0 			; mov raqueta d (-1 arriba, 0 stop, 1 abajo)
dir3			DCB 0			; mov pelota(0-arriba izq, 1-arriba drch, 2-abajo izq, 3-abajo drch)
fin				DCB 0			; si 1 fin del programa
tecla_r1		DCB 0			; tecla para controlar raq1
tecla_r2		DCB 0			; tecla para controlar raq2

		AREA codigo,CODE
		EXPORT inicio			; forma de enlazar con el startup.s
		IMPORT srand			; para poder invocar SBR srand
		IMPORT rand				; para poder invocar SBR rand
inicio	; se recomienda poner punto de parada (breakpoint) en la primera
		; instruccion de c�digo para poder ejecutar todo el Startup de golpe
		;actualizamos vector de interupciones para IRQ4 y IRQ7
		ldr r0, =VICVectAddr0	;
		ldr r1, =rsi_timer		;
		mov r2, #4				;
		str r1, [r0, r2, LSL#2]	;
		
		ldr r1, =rsi_teclado	;
		mov r2, #7				;
		str r1, [r0, r2, lsl#2]	;
		
		;habilitamos interrupciones en VIC
		ldr r0, =VICIntEnabl	;
		mov r1, #16				;
		add r1, r1, #128		;
		str r1, [r0]			;
		
		;generador num aleatorios
		ldr r0, =semilla
		ldr r0, [r0]			;
		push{r0}
		bl srand
		add sp, sp, #4	

fin_jugada
		bl limpiar_pantalla
		
		ldr r10, =dir1
		mov r11, #0
		strb r11, [r10]
		
		ldr r10, =dir2
		mov r11, #0
		strb r11, [r10]

		sub sp, sp, #4			; espacio para resultado (num aleatorio)
		bl rand
		pop {r0}				; r0= num aleatorio
		

;dibujar pantalla inicial*******************************************************************************************************************
		;dibujamos pelota en posicion aleatoria
		and r1, r0, #0xF		; r1= ultimos 4 bits del num aleatorio
		ldr r2, =0x40007e0F		; base pelota
		add r2, r2, r1, lsl#5	; r2= direccion aleatoria pelota
		mov r3, #pelota
		strb r3,[r2]			; dibujamos pelota 
		ldr r3, =pos_pelota		;
		str r2, [r3]			;gurdamos la posicion de pelota en memoria
		
		; si la posicion aleatoria generada está en la última fila, las direcciones posibles solo son 0 y 1 
		; si esta en la primera fila, posinles moviemientos solo son 2 y 3 
		and r1, r0, #0x3000		; numero aleatorio para dirección de movimiento de la pelota
		mov r1, r1, lsr #12
		
		
		ldr r10, =0x40007e1f		; limite superior
		ldr r11, =0x40007FE0		;limite inferior
		
		cmp r2, r11
		cmpge r1, #2
		subge r1, r1, #2
		
		cmp r2, r10
		cmple r1, #1
		addle r1, r1, #2
		
		ldr r2, =dir3
		strb r1, [r2]			
		
		
		;dibujamos raquetas en las posiciones aleatorias
		and r1, r0, #0xF0
		mov r1, r1, lsr #4
		ldr r2, =0x40007e01		;base r1
		add r2,r2, r1, lsl#5	; 
		mov r3, #raqueta
		ldr r4, =pos_r1
		str r2, [r4]					; r2 = dirrecion de la ficha inferior de la raqueta
		
		;limites r1
		ldr r10, =0x40007e01			; base r1
		strb r3, [r2]					; 
		
		mov r1, #4
if_a	cmp r1, #0
		beq f_a

		sub r2, r2, #32
		and r4, r2, #0xFF0
		mov r4, r4, lsr #5
		and r4, r4, #0xF				; mod 16 
		
		add r11, r10, r4, lsl#5
		strb r3, [r11]
		sub r1, r1, #1
		b if_a
		
f_a		;raqueta 2
		and r1, r0, #0xF00
		mov r1, r1, lsr #8
		ldr r2, =0x40007e1D		;base r2
		add r2,r2, r1, lsl#5	; 
		mov r3, #raqueta
		ldr r4, =pos_r2
		str r2, [r4]
		
		;limites r2
		ldr r10, =0x40007e1D			; limite superior
		strb r3, [r2]					; 
		
		mov r1, #4
if_b	cmp r1, #0
		beq f_b
		sub r2, r2, #32
		and r4, r2, #0xFF0
		mov r4, r4, lsr #5
		and r4, r4, #0xF				; mod 16 
		
		add r11, r10, r4, lsl#5
		strb r3, [r11]
		sub r1, r1, #1
		b if_b
f_b
;fin dibujar pantalla inicial---------------------------------------------------------------------------------------------------------------

		;instante siguiente movimiento pelota
		ldr r0, =crono
		ldr r0, [r0]			; r0=crono
		
		ldr r1, =next			; r1=dir next 
		
		ldr r3, =max
		ldr r3, [r3]
		
		add r2, r0, r3
		str r2, [r1]
		
;bucle principal *********************************************************************************************************************
		
bucle	;while(fin==0)
		ldr r0, =fin
		ldrb r1, [r0]			; r1=fin
		cmp r1, #0
		bne fin_bucle
		
		;areglamos el timer
		ldr r1, =next			; r1=dir next 
		ldr r2, [r1]			; r2=next
		
		ldr r0, =crono
if_c	ldr r4, [r0]			; r4=crono
		cmp r4, r2				; crono < next
		bne if_c		
		
		ldr r3, =max
		ldr r3, [r3]
		add r2, r4, r3
		str r2, [r1]	

		
;aclualizamos variables de direccion ----------------------------------------------------------------------------------------------------------
	
control_r1
		ldr r0, =tecla_r1
		ldrb r1,[r0]				; r1 = tecla_r1
		
		mov r4, #-1				;r4=-1
		mov r5, #0				; r5=0
		mov r6, #1				; r6=1
		
		ldr r2, =dir1	
		ldrsb r3, [r2]
		
let_Q	cmp r1, #'Q'	
		bne else_A
		cmp r3, #-1
		strbeq r5, [r2]
		strbne r4, [r2]
		b control_r2
		
else_A 	cmp r1, #'A'	
		bne control_r2
		cmp r3, #1
		strbeq r5, [r2]
		strbne r6, [r2]
		b control_r2


control_r2
		strb r5, [r0]				; hemos atendido a la tecla_r1
		ldr r0, =tecla_r2
		ldrb r1,[r0]				; r1 = tecla
		
		ldr r2, =dir2	
		ldrsb r3, [r2]
		
let_O	cmp r1, #'O'	
		bne else_L
		cmp r3, #-1
		strbeq r5, [r2]
		strbne r4, [r2]
		b control_vel
else_L 	cmp r1, #'L'	
		bne control_vel
		cmp r3, #1
		strbeq r5, [r2]
		strbne r6, [r2]
		b control_vel
		
control_vel	strb r5, [r0]		; heos atendido a la tecla 2

plus	cmp r1, #'+'			;
		bne minus				;
		ldr r2, =max			;
		ldr r3, [r2]
		cmp r3, #128			;¿velocidad maxima? se puede aumentar vel?
		movne r3, r3, lsl#2
		strne r3, [r2]
		b f_uart

minus	cmp r1, #'-'			;
		bne fin_6				;
		ldr r2, =max			;
		ldr r3, [r2]
		cmp r3, #1				;¿velocidad minima? se puede disinuir vel?
		movne r3, r3, lsr#2
		strne r3, [r2]
		b f_uart

fin_6	cmp r1, #'6'	
		bne f_uart
		ldr r2, =fin
		strb r5, [r2]
		
;----------------------------------------------------------------------------------------------------------------------------------------------------
f_uart
		
		bl mover1
		bl mover2
		
		
		
		

; movimiento pelota			r0, r2
						; next= crono+max
		
		;borrar elemento anterior 
		ldr r0, =pos_pelota		; r0=dir pos_pelota!!!!!!!!!!!!!!!!!!!!!!!
		ldr r1, [r0]			; r1=pos_pelota
		mov r2, #' '			;espacio en blanco
		strb r2, [r1]
		
		;calcular nueva posicion 
		ldr r2, =dir3			; r2=dir dir3
		ldrb r3, [r2]			; r3= dir3
		
		ldr r8, =0x40007FFD			; limite inferior drch
		ldr r9, =0x40007e01		; limite superior izqd
		ldr r10, =0x40007E1D		; limite superior derecha
		ldr r11, =0x40007FE1		;limite inferior izqd
		mov r12, #'*'
;movimiento arriba izquierda-----------------------------------------------------------------------------------------------------------------
dir3_0	cmp r3, #0
		bne dir3_1
		sub r1, #33
		
		cmp r1, r9
		blt f_else_a
		cmpge r1, r10
		bgt	f_if_0
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #2
		strb r3, [r2]			; rebotamos 
		b f_dir3
		
f_if_0	ldr r6, =pos_r1
		ldr r6, [r6]			; r6= pos_r1
		sub r5, r1, #1			; r5=pos_pelota -1
		mov r4, #5				;	r4=i 
else_a	cmp r4, #0
		beq f_else_a
if_d	cmp r5, r6
		bne f_if_d
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #1
		strb r3, [r2]			; rebotamos 
		b f_dir3
f_if_d	sub r6, r6, #32
		sub r4, r4, #1
		b else_a
		
f_else_a	
		ldr r5, =0x40007e00		; direccion base columna 0
		mov r4, #16				; i 
else_b	cmp r4, #0
		beq f_else_b
		
if_e	cmp r1, r5				; ¿posicion_pelota == alguna direccion de columna 0?
		bne f_if_e
		strb r12, [r1]			;dibujamos en la posicion nueva 
		ldr r6, =puntosB		; puntosB++
		ldr r7, [r6]
		add r7, r7, #1
		str r7, [r6]
		b fin_jugada
		
f_if_e	add r5, r5, #32
		sub r4, r4, #1
		b else_b
		
f_else_b
		strb r12, [r1]
		str r1, [r0]
		b f_dir3

;------------------------------------------movimiento pelota arriba derecha---------------------------------------------------------------------------------------------------------

dir3_1	cmp r3, #1
		bne dir3_2
		sub r1, #31
		
		cmp r1, r9
		blt f_else_c
		cmpge r1, r10				; comparamos con limite superior
		bgt	f_if_1
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #3
		strb r3, [r2]			; rebotamos 
		b f_dir3
		
f_if_1	ldr r6, =pos_r2
		ldr r6, [r6]			; r6= pos_r2
		add r5, r1, #1			; r5=pos_pelota +1
		mov r4, #5				;	r4=i 
else_c	cmp r4, #0
		beq f_else_c
if_f	cmp r5, r6
		bne f_if_f
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #0
		strb r3, [r2]			; rebotamos 
		b f_dir3
f_if_f	sub r6, r6, #32
		sub r4, r4, #1
		b else_c
		
f_else_c	
		ldr r5, =0x40007e1E		; direccion base columna 31
		mov r4, #16				; i 
else_d	cmp r4, #0
		beq f_else_d
		
if_g	cmp r1, r5				; ¿posicion_pelota == alguna direccion de columna 31?
		bne f_if_g
		strb r12, [r1]			;dibujamos en la posicion nueva 
		ldr r6, =puntosA		; puntosB++
		ldr r7, [r6]
		add r7, r7, #1
		str r7, [r6]
		b fin_jugada
		
f_if_g	add r5, r5, #32
		sub r4, r4, #1
		b else_d
		
f_else_d
		strb r12, [r1]
		str r1, [r0]
		b f_dir3
;----------------------------------------------------movimiento pelota abajo izquierda-----------------------------------------------------------------------------------------------
		
dir3_2	cmp r3, #2
		bne dir3_3
		add r1, #31
		
		cmp r1, r8				; comparamos con limite inferior drch
		bgt f_else_e
		cmple r1, r11			; comparamos con limite inferior izqd
		blt	fin_if_3
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #0
		strb r3, [r2]			; rebotamos 
		b f_dir3
		
fin_if_3		
		ldr r6, =pos_r1
		ldr r6, [r6]			; r6= pos_r1
		sub r5, r1, #1			; r5=pos_pelota -1
		mov r4, #5				;	r4=i 
else_e	cmp r4, #0
		beq f_else_e
if_k	cmp r5, r6
		bne f_if_k
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #3
		strb r3, [r2]			; rebotamos 
		b f_dir3
f_if_k	sub r6, r6, #32
		sub r4, r4, #1
		b else_e
		
f_else_e	
		ldr r5, =0x40007e00		; direccion base columna 0
		mov r4, #16				; i 
else_f	cmp r4, #0
		beq f_else_f
		
if_l	cmp r1, r5				; ¿posicion_pelota == alguna direccion de columna 0?
		bne f_if_l
		strb r12, [r1]			;dibujamos en la posicion nueva 
		ldr r6, =puntosB		; puntosB++
		ldr r7, [r6]
		add r7, r7, #1
		str r7, [r6]
		b fin_jugada
		
f_if_l	add r5, r5, #32
		sub r4, r4, #1
		b else_f
		
f_else_f
		strb r12, [r1]
		str r1, [r0]
		b f_dir3
;---------------------------------------------------------------------------------------------------------------------------------------------------
		
dir3_3	cmp r3, #3
		bne error
		add r1, #33
		
if_3	cmp r1, r8				; comparamos con limite inferior drch
		bgt f_else_g
		cmple r1, r11			; comparamos con limite inferior
		blt	f_if_3
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #1
		strb r3, [r2]			; rebotamos 
		b f_dir3
		
f_if_3	ldr r6, =pos_r2
		ldr r6, [r6]			; r6= pos_r2
		add r5, r1, #1			; r5=pos_pelota +1
		mov r4, #5				;	r4=i 
else_g	cmp r4, #0
		beq f_else_g
if_m	cmp r5, r6
		bne f_if_m
		str r1, [r0]			;actualizamos pos_pelota 
		strb r12, [r1]			;dibujamos en la posicion nueva 
		mov r3, #2
		strb r3, [r2]			; rebotamos 
		b f_dir3
f_if_m	sub r6, r6, #32
		sub r4, r4, #1
		b else_g
		
f_else_g	
		ldr r5, =0x40007e1E		; direccion base columna 31
		mov r4, #16				; i 
else_h	cmp r4, #0
		beq f_else_h
		
if_n	cmp r1, r5				; ¿posicion_pelota == alguna direccion de columna 31?
		bne f_if_n
		strb r12, [r1]			;dibujamos en la posicion nueva 
		ldr r6, =puntosA		; puntosA++
		ldr r7, [r6]
		add r7, r7, #1
		str r7, [r6]
		b fin_jugada
		
f_if_n	add r5, r5, #32
		sub r4, r4, #1
		b else_h
		
f_else_h
		strb r12, [r1]
		str r1, [r0]
		b f_dir3
		
		
f_dir3		
		
		
		
		b bucle
		
	
;fin bucle principal*******************************************************************************************************************
fin_bucle
		
		;deshabilitamos interrupciones VIC
		ldr r0, =VICIntEnClr	;
		mov r1, #16				;
		add r1, r1, #128		;
		str r1, [r0]			;
		
bfin 	b bfin 

;*************************************************************************************************************************************************
error



;************************************************************************************************************************************************
;**********************************************************************************************************************************************
rsi_timer
		sub lr, lr, #4			;
		push {lr}				;
		mrs r14, spsr			;
		push {r14}				;
		
		push {r0-r2}		;
		mrs r1, cpsr			;
		bic r1, r1, #I_Bit		;
		msr cpsr_c, r1			;
		
;tratamiento interrupcion
		ldr r0, =crono
		ldr r1, [r0]
		add r1, r1, #1
		str r1, [r0] 
		
		ldr r0, =T0_IR			;
		mov r1, #1				;
		str r1, [r0]			;
		
		mrs r1, cpsr			;
		orr r1, r1, #I_Bit		;
		msr cpsr_cxsf, r1		;
		
		pop{r0-r2}				;
		pop{r14}				;
		msr spsr_cxsf, r14		;
		ldr r14, =VICVectAddr	;
		str r14, [r14]			;
		pop {pc}^				;
		


rsi_teclado
		sub lr, lr, #4			;
		push {lr}				;
		mrs r14, spsr			;
		push {r14}				;
		
		push {r0-r6, r10}		;
		mrs r1, cpsr			;
		bic r1, r1, #I_Bit		;
		msr cpsr_c, r1			;
		
;tratamiento interrupcion
		ldr r0, =UART_RDAT		;
		ldrb r1, [r0]
		bic r1, r1, #2_100000	;paso a mayusculas
		
		ldr r2, =tecla_r1
		cmp r1, #'A'
		cmpne r1, #'Q'
		bne tecla2
		strbeq r1, [r2]
		b fin_int
		
tecla2	ldr r2, =tecla_r2
		cmp r1, #'O'
		cmpne r1, #'L'
		strbeq r1, [r2]
		b fin_int
		
fin_int	
;desactivar irq
		mrs r1, cpsr			;
		orr r1, r1, #I_Bit		;
		msr cpsr_cxsf, r1		;
		
		pop{r0-r6, r10}		
;retorno al programa principal
		pop{r14}				;
		msr spsr_cxsf, r14		;
		ldr r14, =VICVectAddr	;
		str r14, [r14]			;
		pop {pc}^				;






limpiar_pantalla
		push{lr, sp}
		mov r11, sp
		push{r0-r2}
		
		ldr r0, =0x40007E00
		ldr r1, =0x40007FFF
		mov r2,#' '
buc_lp	cmp r0, r1
		bgt fin_lp
		strb r2, [r0]
		add r0, r0, #1
		b buc_lp
		
fin_lp	pop{r0-r2}
		pop{fp,pc}



;subrutina para mover raquetas arg: dirrecion base raqueta1, dir pos_raq1, dir1 (-1 arriba, 0 stop, 1 abajo)
;******************************* MOVIMIENTO RAQQUETA 1 *********************************************************************************************
mover1 
		push {lr, fp}
		push{r0-r11}
		
		ldr r0, =0x40007E01		; r0=pos_base_raqueta
		ldr r1, =pos_r1		; r1=dir pos_raq
		ldr r2, [r1]			; r2=pos_raq
		ldr r3, =dir1			; r3=dir raqueta
		ldrsb r3, [r3]
		
		mov r7, #' '
		mov r8, #raqueta
		
		cmp r3, #0
		beq fin_mover
mov_arriba
		cmp r3, #-1
		bne mov_abajo
		
		strb r7, [r2]			; quitamos X de abajo
		sub r2, r2, #32			; nueva posicion actual
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; sale del tablero?
		str r2, [r1]			; guardamos posicion actual en memoria
		
		mov r10, #4
		sub r2, r10, lsl#5		; posicion de la nueva ficha
		
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; 
		strb r8, [r2]			; dibujar nueva ficha
		b fin_mover
		
mov_abajo
		cmp r3, #1
		bne fin_mover
		
		add r2, r2, #32			
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; sale del tablero?
		str r2, [r1]
		strb r8, [r2]			; dibujamos nueva ficha
								; guardamos posicion actual en memoria
		
		mov r10, #5
		sub r2, r10, lsl#5			; posicion de la ficha para quitar
		
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF				; mod 16 
		
		add r2, r0, r2, lsl#5			; 
		strb r7, [r2]					; quitar ficha del arriba
		b fin_mover

fin_mover
		pop{r0-r11}
		pop{fp, pc}

;*********************************FIN MOVIMIENTO RAQUETA 1 *****************************************************************************************
;********************************************************************************************************************************************

;******************************* MOVIMIENTO RAQQUETA 2 *********************************************************************************************

mover2 
		push {lr, fp}
		push{r0-r11}
		
		ldr r0, =0x40007E1D		; r0=pos_base_raqueta
		ldr r1, =pos_r2			; r1=dir pos_raq
		ldr r2, [r1]			; r2=pos_raq
		ldr r3, =dir2			; r3=dir raqueta
		ldrsb r3, [r3]
		
		mov r7, #' '
		mov r8, #raqueta
		
		cmp r3, #0
		beq fin_mover2
mov_arriba2
		cmp r3, #-1
		bne mov_abajo2
		
		strb r7, [r2]			; quitamos X de abajo
		sub r2, r2, #32			; nueva posicion actual
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; sale del tablero?
		str r2, [r1]			; guardamos posicion actual en memoria
		
		mov r10, #4
		sub r2, r10, lsl#5		; posicion de la nueva ficha
		
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; 
		strb r8, [r2]			; dibujar nueva ficha
		b fin_mover2
		
mov_abajo2
		cmp r3, #1
		bne fin_mover2
		
		add r2, r2, #32			
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF		; mod 16 
		add r2, r0, r2, lsl#5	; sale del tablero?
		str r2, [r1]
		strb r8, [r2]			; dibujamos nueva ficha
								; guardamos posicion actual en memoria
		
		mov r10, #5
		sub r2, r10, lsl#5			; posicion de la ficha para quitar
		
		and r2, r2, #0xFF0
		mov r2, r2, lsr #5
		and r2, r2, #0xF				; mod 16 
		
		add r2, r0, r2, lsl#5			; 
		strb r7, [r2]					; quitar ficha del arriba
		b fin_mover2

fin_mover2
		pop{r0-r11}
		pop{fp, pc}


		END




;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!A CONSIDERAR!!!!!!!!!!!!!!!!
;al hacer la rutina para mover raquetas, en memoria tenemos guardadas variables pos_r1 y pos_r2 que tienen que guardar la posicision (uan dirrecion de memoria)
;base de cada raqueta. al mover las raquetas actualizamos la posicion 