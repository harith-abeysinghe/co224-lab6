/*
Module  : Data Cache 
Author  : Isuru Nawinne, Kisaru Liyanage
Date    : 25/05/2020

Description	:

This file presents a skeleton implementation of the cache controller using a Finite State Machine model. Note that this code is not complete.
*/
`timescale 1ns/100ps


module dcache (clk, read, write, reset, busywait ,mem_read ,mem_write ,mem_writedata ,mem_address ,readdata ,mem_busywait ,mem_readdata ,address ,writedata) ;
    //mem - Main memory , Has 32 bits for readdata, writedata, 5 bits for address
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
    

    // When a read or write is detected, set the busywait signal to high
    always @(posedge read, posedge write) begin
        busywait = 1;
        #1 readfromcache = (read && !write) ? 1 : 0; // Set readfromcache signal if it's a read operation
        writetocache = (!read && write) ? 1 : 0; // Set writetocache signal if it's a write operation
    end

    // Extracting data from cache based on readfromcache or writetocache signals
    always @(validbits, tag[index], index, posedge readfromcache, posedge writetocache, dirtybits) begin
        if (readfromcache || writetocache) begin
            #1 tag_of_block = tags[index]; // Extract the corresponding tag of the cache entry selected by the index
            valid = validbits[index]; // Extract the corresponding valid bit of the cache entry selected by the index
            dirty = dirtybits[index]; // Extract the corresponding dirty bit of the cache entry selected by the index
            checkhit = 1; // Signal to indicate the need to check for a hit
        end
    end

    // Extracting data words from the cache based on the index and offset
    always @(posedge readfromcache, cache[index], index, offset) begin
        #1 case (offset)
            2'b00: readdata = cache[index][7:0]; // Extract data word from cache at offset 00
            2'b01: readdata = cache[index][15:8]; // Extract data word from cache at offset 01
            2'b10: readdata = cache[index][23:16]; // Extract data word from cache at offset 10
            2'b11: readdata = cache[index][31:24]; // Extract data word from cache at offset 11
        endcase
    end

    // Generate hit signal once a read or write is detected or there is a change in tag of a cache entry or valid bit of a cache entry
    always @(tag_of_block, valid, tag, posedge checkhit) begin
        checkhit = 0; // Reset checkhit signal to zero
        if (valid && (tag == tag_of_block)) begin
            #0.9 hit = 1; // It's a hit if valid and tags are matching, set hit signal to high
            busywait = 0; // No need to stall the CPU, set busywait signal to 0
            readfromcache = 0; // If the operation is a write, this signal is used to indicate there is something to write at the end
                            // Since the write signal of the CPU is deasserted with busywait, this signal is used
        end
        else if ((!valid || (tag != tag_of_block))) begin
            #0.9 hit = 0; // It's a miss if not valid or tags are not matching, set hit signal to 0
            if (dirty) begin
                mem_write = 1; // Set memory write signal if the block is dirty
                mem_address = {tag_of_block, index}; // Set memory address for writing the block
                mem_writedata = cache[index]; // Write the data from the cache to memory
            end
            else begin
                mem_read = 1; // Set memory read signal if the block is not dirty
                mem_address = {tag, index}; // Set memory address for reading the missing block
            end
        end
    end

    // Writing data to the cache at the positive clock edge
    always @(posedge clk) 
    begin
        if (hit && writetocache) 
        begin
            // Check if there is a cache hit and a write operation is requested

            // Select the correct cache entry based on the index
            // Select the correct position to be written based on the offset
            case(offset)
                2'b00: cache[index][7:0] = writedata;
                2'b01: cache[index][15:8] = writedata;
                2'b10: cache[index][23:16] = writedata;
                2'b11: cache[index][31:24] = writedata;
            endcase

            // Set the writetocache signal to 0 after writing
            writetocache = 0;

            // Set the dirty bit of the cache entry high after a write operation
            // to indicate that the data in the cache is inconsistent with the memory
            dirtybits[index] = 1;
        end
    end

    // The update signal is used in the FSM to indicate that the cache needs to be updated
    // When the update signal changes from 1 to 0, the cache is updated
    always @(negedge update) 
    begin
        // Write the read data from the memory to the correct cache entry
        cache[index] = mem_readdata;

        // Set the valid bit high to indicate that the cache entry is valid
        validbits[index] = 1;

        // Set the dirty bit low to indicate that the cache data is consistent with the memory
        dirtybits[index] = 0;

        // Update the tag of the cache entry with the new tag value
        tags[index] = tag;
    end


    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010;
    reg [2:0] state, next_state;

    // Combinational next state logic
    always @(read, write, dirty, hit, mem_busywait) 
    begin
        case (state)
            IDLE:
                // If there is a read or write operation and the data in the cache entry is consistent (not dirty) and it's a cache miss, go to MEM_READ state
                if ((read || write) && !dirty && !hit)
                    next_state = MEM_READ;
                // If there is a read or write operation and the data in the cache entry is inconsistent (dirty) and it's a cache miss, go to MEM_WRITE state
                else if ((read || write) && dirty && !hit)
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE; // Stay in IDLE state when there is no cache miss

            MEM_READ:
                // After finishing reading from memory, go back to IDLE state
                // mem_busywait going low indicates that reading is finished
                if (!mem_busywait)
                    next_state = IDLE;
                else
                    next_state = MEM_READ; // Stay in MEM_READ state while reading from memory

            MEM_WRITE:
                // After finishing writing to memory, go to MEM_READ state
                // mem_busywait going low indicates that writing is finished
                if (!mem_busywait)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE; // Stay in MEM_WRITE state while writing to memory
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
                mem_address = 6'dx;
                mem_writedata = 32'dx;
                busywait = 0;
                update = 0;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                busywait = 1;
                update = 1;
            end

            MEM_WRITE:
            begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {tag_of_block, index};
                mem_writedata = cache[index];
                busywait = 1;
            end
            
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clk, reset)
    begin
        if(reset)
        begin
            state = IDLE;
            validbits = 0;	
            dirtybits = 0; 
        end
        else
            state = next_state;
    end

    /* Cache Controller FSM End */

initial 
begin
    $monitor($time,"\t Read = %d \t Write = %d", read, write);
end
endmodule