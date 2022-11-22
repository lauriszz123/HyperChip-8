main:
	CLS

	LD V0, 0
	LD V1, 0

	LD V2, 0x3
	LD F, V2

	DRW V0, V1, 

	loop: JP loop