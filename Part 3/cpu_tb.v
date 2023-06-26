// Computer Architecture (CO224) - Lab 06
// Design: Testbench of Integrated CPU of Simple Processor with Data Memory
// Author: Isuru Nawinne

`include "CPU.v"
`include "dmem_for_dcache.v"
`include "dcacheFSM_skeleton.v"
`timescale 1ns/100ps
module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;

    //Adding wires and registers for data memory
    wire READ, WRITE;
    wire [7:0] READDATA;
    wire reg BUSYWAIT;

    wire [7:0] ADDRESS, WRITEDATA;


    //Adding wires for cache
    wire [31:0] MEM_IN,MEM_OUT;
    wire [5:0] MEM_ADDRESS;
    wire MEM_BUSYWAIT,MEM_READ,MEM_WRITE;

    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    reg [7:0] instr_mem [1023:0];

    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    assign #2 INSTRUCTION = {instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};
    
    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000000001000000000000000101;
        //{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000000000100000000000001001;
        //{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00000010000001100000010000000010;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET,BUSYWAIT, READ, WRITE, ADDRESS, WRITEDATA, READDATA);

    dcache mycache(CLK, READ, WRITE, RESET, BUSYWAIT, MEM_READ, MEM_WRITE, MEM_IN, MEM_ADDRESS, READDATA, MEM_BUSYWAIT, MEM_OUT, ADDRESS, WRITEDATA);
    //module dcache (clk, read, write, reset, busywait ,mem_read ,mem_write ,mem_writedata ,mem_address ,readdata ,mem_busywait ,mem_readdata ,address ,writedata) ;
    
    data_memory mymemory(CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_IN, MEM_OUT, MEM_BUSYWAIT);
    //module data_memory(clock, reset, read, write, address, writedata, readdata, busywait); //for main memory
    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        RESET = 1'b1;
        #5
        RESET = 1'b0;
        
        // finish simulation after some time
        #400
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule
