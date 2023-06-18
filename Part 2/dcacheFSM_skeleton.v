/*
Module  : Data Cache 
Author  : Isuru Nawinne, Kisaru Liyanage
Date    : 25/05/2020

Description	:

This file presents a skeleton implementation of the cache controller using a Finite State Machine model. Note that this code is not complete.
*/
`timescale 1ns/100ps


module dcache (clk, read, write, reset, busywait ,mem_read ,mem_write ,mem_writedata ,mem_address ,readdata ,mem_busywait ,mem_readdata ,address ,writedata) ;
    //mem - Main memory
    input read,write,mem_busywait,clk,reset;
    input [7:0] writedata,address;
    input [31:0] mem_readdata;

    output reg mem_write,mem_read,busywait;
    output reg [31:0] mem_writedata;
    output reg [5:0] mem_address;
    output reg [7:0] readdata;
    
   // Data cache memory: 8 blocks of 32-bit arrays
    reg [31:0] cache [7:0];

    // Valid and dirty bits for each cache data block
    reg [7:0] validbits, dirtybits;

    // Tags for each cache data block
    reg [2:0] tags [7:0];

    // Variables to store address components
    // tag: Stores the tag given by the address that the CPU wants to access
    // index: Stores the index given by the address that the CPU wants to access
    // tag_of_block: Stores the corresponding tag of the cache entry selected by the index
    wire [2:0] index; // 8 = 2^3 Since 3 bits for index
    
    // Variable to store the offset given by the address
    wire [1:0] offset; //Word size is 4 bytes, Hence 2 bits
    
    wire [2:0] tag; // remaining 3 bits
    reg [2:0] tag_of_block;

    

    // Cache control signals
    reg dirty, valid, hit, update, writetocache, readfromcache, checkhit;

    // 8-bit arrays used to extract data in a cache entry selected by the index
    reg [7:0] datablock [3:0];

    // Splitting the address given by the CPU into tag, index, and offset components

    assign tag = address[7:5];     // Extracting the tag from bits 7-5 of the address
    assign index = address[4:2];   // Extracting the index from bits 4-2 of the address
    assign offset = address[1:0];  // Extracting the offset from bits 1-0 of the address



    /*
    Combinational part for indexing, tag comparison for hit deciding, etc.
    ...
    ...
    */
    

    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001;
    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty && !hit)  
                    next_state = MEM_READ;
                else if (...)
                    next_state = ...;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = ...;
                else    
                    next_state = MEM_READ;
            
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 8'dx;
                busywait = 0;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                busywait = 1;
            end
            
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clock, reset)
    begin
        if(reset)
            state = IDLE;
        else
            state = next_state;
    end

    /* Cache Controller FSM End */

endmodule