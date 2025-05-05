		AREA datos,DATA
VICIntEnabl		EQU 0xFFFFF010
VICIntEnClr		EQU 0xFFFFF014
	
VICVectAddr 	EQU 0xFFFFF030
VICVectAddr0	EQU 0xFFFFF100

UART_RDAT		EQU 0xE0010000

I_Bit 			EQU 0x80
T0_IR			EQU 0xE0004000

semilla 		EQU 55
	
base_r1			EQU 0x40007e01
base_r2			EQU 0x40007e1D
	
pelota			EQU '*'
raqueta			EQU 'X'

crono 			DCD 0 			; contador de centesimas de segundo
max				DCD 0 			; velocidad de movimiento en centesimas s. 
next 			DCD 0			; instante siguiente movimiento
dir1			DCB	0			; mov raqueta izda (-1 arriba, 0 stop, 1 abajo)
dir2			DCB 0 			; mov raqueta d (-1 arriba, 0 stop, 1 abajo)
dir3			DCB 0			; mov pelota
fin				DCB 0			; si 1 fin del programa


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
		ldr r0, [r0]		;
		push{r0}
		bl srand
		add sp, sp, #4	

		sub sp, sp, #4			; espacio para resultado (num aleatorio)
		bl rand
		pop {r0}				; r0= num aleatorio
		
		
		;dibujar pantalla inicial
		;dibujamos pelota en posicion aleatoria
		and r1, r0, #0xF		; r1= ultimos 4 bits del num aleatorio
		ldr r2, =0x40007e0F		; base pelota
		add r2, r2, r1, lsl#5	; r2= direccion aleatoria pelota
		mov r3, #pelota
		strb r3,[r2]			; dibujamos pelota 
		
		;dibujamos raquetas en las posiciones aleatorias
		and r1, r0, #0xF0
		mov r1, r1, lsr #4
		ldr r2, =0x40007e01		;base r1
		add r2,r2, r1, lsl#5	; 
		mov r3, #raqueta
		
		;limites r1
		ldr r10, =0x40007e01			; limite superior
		ldr r11, =0x40007fe1			; limite inferior
		
		mov r1, #5
if_a	cmp r1, #0
		beq f_a
		add r2, r2, #32		
		cmp r2, r10
		movlt r2, r11
		cmp r2, r11
		movgt r2, r10
		strb r3,[r2]
		sub r1, r1, #1
		b if_a
		
f_a		;raqueta 2
		and r1, r0, #0xF00
		mov r1, r1, lsr #8
		ldr r2, =0x40007e1D		;base r2
		add r2,r2, r1, lsl#5	; 
		mov r3, #raqueta
		
		;limites r2
		ldr r10, =0x40007e1D			; limite superior
		ldr r11, =0x40007f1D			; limite inferior
		
		mov r1, #5
if_b	cmp r1, #0
		beq f_b
		add r2, r2, #32		
		cmp r2, r10
		movlt r2, r11
		cmp r2, r11
		movgt r2, r10
		strb r3,[r2]
		sub r1, r1, #1
		b if_b
f_b
		
w_1		;while(fin==0)
		ldr r0, =fin
		ldr r1, [r0]			; r1=fin
		cmp r1, #0
		beq f_w_1
		
		
		
		
		
		
		
		
		b w_1
		
	

f_w_1
		
		;deshabilitamos interrupciones VIC
		ldr r0, =VICIntEnClr	;
		mov r1, #16				;
		add r1, r1, #128		;
		str r1, [r0]			;
		
		





rsi_timer
		sub lr, lr, #4			;
		push {lr}				;
		mrs r14, spsr			;
		push {r14}				;
		
		;push {registros}		;
		mrs r1, cpsr			;
		bic r1, r1, #I_Bit		;
		msr cpsr_c, r1			;
		
;tratamiento interrupcion


		
		ldr r0, =T0_IR			;
		mov r1, #1				;
		str r1, [r0]			;
		
		mrs r1, cpsr			;
		orr r1, r1, #I_Bit		;
		msr cpsr_cxsf, r1		;
		
		;pop{registot}			;
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
		ldr r1, [r0]			;
		bic r1, r1, #2_100000	;paso a mayusculas
		
		mov r4, #-1				;r4=-1
		mov r5, #0				; r5=0
		mov r6, #1				; r6=1
		
let_Q	cmp r1, #'Q'	
		bne let_A				;
		ldr r2, =dir1			;
		ldrb r3, [r2]			;
		cmp r3, #-1				;
		strbne r4, [r2]			;
		strbeq	r5, [r2]
		b f_uart				;
		
let_A	cmp r1, #'A'			;
		bne let_O				;
		ldr r2, =dir1
		ldr r3, [r2]
		cmp r3, #1				;
		strbne r6, [r2]			;
		strbeq r5, [r2]
		b f_uart

let_O	cmp r1, #'O'			;
		bne let_L
		ldr r2, =dir2			;
		ldrb r3, [r2]			;
		cmp r3, #-1				;
		strbne r4, [r2]			;
		strbeq	r5, [r2]
		b f_uart

let_L	cmp r1, #'L'			;
		bne plus				;
		ldr r2, =dir2
		ldr r3, [r2]
		cmp r3, #1				;
		strbne r6, [r2]			;
		strbeq r5, [r2]
		b f_uart

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
		ldreq r2, =fin
		strbeq r5, [r2]
		b f_uart
		
		
;desactivar irq
f_uart	mrs r1, cpsr			;
		orr r1, r1, #I_Bit		;
		msr cpsr_cxsf, r1		;
		
		pop{r0-r6, r10}		
;retorno al programa principal
		pop{r14}				;
		msr spsr_cxsf, r14		;
		ldr r14, =VICVectAddr	;
		str r14, [r14]			;
		pop {pc}^				;


		END
