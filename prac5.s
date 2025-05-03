		AREA datos,DATA
VICIntEnabl		EQU 0xFFFFF010
VICIntEnClr		EQU 0xFFFFF014
	
VICVectAddr 	EQU 0xFFFFF030
VICVectAddr0	EQU 0xFFFFF100

UART_RDAT		EQU 0xE0010000

I_Bit 			EQU 0x80
T0_IR			EQU 0xE0004000

rand_x			DCD 0



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
		ldr r1, =rsi_crono		;
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
		
		push {registros}		;
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
		
		pop{registot}			;
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
		
		push {registros}		;
		mrs r1, cpsr			;
		bic r1, r1, #I_Bit		;
		msr cpsr_c, r1			;
		
;tratamiento interrupcion
		ldr r0, =UART_RDAT		;
		ldr r1, [r0]			;
		bic r1, r1, #2_100000	;paso a mayusculas
		
let_Q	cmp r1, #'Q'	
		ldr r2, =dir1			;
		bne let_A				;
		
		mov r3, #-1				;
		strb r3, [r2]			;
		b f_uart				;
		
let_A	cmp r1, #'A'			;
		bne let_O				;
		ldr r2, =dir1			;
		mov r3, #1				;
		strb r3, [r2]			;
		b f_uart

let_O	cmp r1, #'O'			;
		bne let_L				;
		ldr r2, =dir2			;
		mov r3, #-1				;
		strb r3, [r2]			;
		b f_uart

let_L	cmp r1, #'L'			;
		bne plus				;
		ldr r2, =dir2			;
		mov r3, #1				;
		strb r3, [r2]			;
		b f_uart

plus	cmp r1, #'+'			;
		bne minus				;
		ldr r2, =			;
		mov r3, #-1				;
		strb r3, [r2]			;
		b f_uart

minus	cmp r1, #'Q'			;
		bne let_A				;
		ldr r2, =dir1			;
		mov r3, #-1				;
		strb r3, [r2]			;
		b f_uart


		
		
;desactivar irq
f_uart	mrs r1, cpsr			;
		orr r1, r1, #I_Bit		;
		msr cpsr_cxsf, r1		;
		
		pop{registot}		
;retorno al programa principal
		pop{r14}				;
		msr spsr_cxsf, r14		;
		ldr r14, =VICVectAddr	;
		str r14, [r14]			;
		pop {pc}^				;


		END
