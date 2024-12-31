`ifndef CONTROLS_SV_INCLUDED
`define CONTROLS_SV_INCLUDED

// ALU control signals
`define ADD 'b0000
`define SUB 'b0001
`define SLL 'b0010
`define SRL 'b0011
`define SRA 'b0100
`define AND 'b0101
`define OR  'b0110
`define XOR 'b0111
`define SLT 'b1000
`define SLTU 'b1001
`define A   'b1010
`define B   'b1011
`define MUL 'b1100

// Opcode types
`define TYPE_R 	  7'b0110011
`define TYPE_I_COMP 7'b0010011
`define TYPE_I_LOAD 7'b0000011
`define TYPE_I_JALR 7'b1100111
`define TYPE_S		  7'b0100011
`define TYPE_SB     7'b1100011 
`define TYPE_U_LUI  7'b0110111
`define TYPE_U_AUIPC 7'b0010111
`define TYPE_UJ	  7'b1101111
`define TYPE_MEMCPY 7'b0001011

// Load and store types
`define LS_BYTE	2'b00
`define LS_HALF	2'b01
`define LS_WORD	2'b11

// Branch types (0 means no branch)
`define JMP_JAL	3'b001
`define JMP_JALR	3'b010
`define JMP_BEQ	3'b011	
`define JMP_BNE	3'b100	
`define JMP_BLT	3'b101	
`define JMP_BGT	3'b110

// Reg write source select
`define WR_ALU		2'b00
`define WR_MEM		2'b01
`define WR_PC		2'b10

`endif
