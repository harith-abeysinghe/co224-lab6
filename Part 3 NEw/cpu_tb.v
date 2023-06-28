// Computer Architecture (CO224) - Lab 05
// Design: Testbench of Integrated CPU of SINSTR_MEMple Processor
// Author: Kisaru Liyanage
`timescale 1ns/100ps
`include "cpu.v"
`include "dmem_for_dcache.v"
`include "imem_for_icache.v"
`include "icache.v"
`include "dcache.v"
module cpu_tb;

    reg CLK, RESET;
	
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
	
	wire READ, WRITE, BUSYWAIT;

	//MEM variables for data memory and cache
	wire MEM_READ, MEM_WRITE, MEM_BUSYWAIT;
	
	wire [7:0] ADDRESS, WRITEDATA, READDATA;
	wire [31:0] MEM_WRITEDATA, MEM_READDATA;
	wire [5:0] MEM_ADDRESS;
	
	//INSTR variables are used for instrcution memory and cache
	wire INSTR_BUSYWAIT;
	
	wire INSTR_MEM_READ, INSTR_MEM_BUSYWAIT;
	wire [5:0] INSTR_MEM_ADDRESS;
	wire [127:0] INSTR_MEM_INSTR;
	
	//Data Memory
	data_memory my_datamem(CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, MEM_BUSYWAIT);
	data_cache my_datacache (CLK, RESET, READ, WRITE, ADDRESS, WRITEDATA, READDATA, BUSYWAIT, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, MEM_BUSYWAIT);
	
	//Instruction Memory
	icache my_icache(CLK, RESET, PC[9:0], INSTRUCTION, INSTR_BUSYWAIT, INSTR_MEM_READ, INSTR_MEM_ADDRESS, INSTR_MEM_INSTR, INSTR_MEM_BUSYWAIT);
	instruction_memory my_INSTR_MEMemory(CLK, INSTR_MEM_READ, INSTR_MEM_ADDRESS, INSTR_MEM_INSTR, INSTR_MEM_BUSYWAIT);
	
	//CPU
	CPU mycpu(PC, INSTRUCTION, CLK, RESET, READ, WRITE, ADDRESS, WRITEDATA, READDATA, BUSYWAIT, INSTR_BUSYWAIT);

    initial
    begin

        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b1;
        
		#5
		RESET = 1'b0;

        #2500
        $finish;
        
    end
    
    always
        #4 CLK = ~CLK;
        

endmodule