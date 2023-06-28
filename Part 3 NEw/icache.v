`timescale 1ns/100ps

module icache(CLK, RESET, ADDRESS, readinst, BUSYWAIT, mem_read, mem_ADDRESS, mem_inst, mem_BUSYWAIT);

	//Input and output port declaration
	input CLK, RESET, mem_BUSYWAIT;

	//The CPU accesses a single instruction word at a time using a 10-bit word address
	// Last 2 LSBs are zero
	input [9:0] ADDRESS;

	//cache size 128 bits
	input [127:0] mem_inst;
	
	output reg mem_read, BUSYWAIT;
	output reg [5:0] mem_ADDRESS;

	//insturcion size 32 bits
	output [31:0] readinst;
	
	//Instruction Cache Storage
	reg [127:0] instr_block_array [7:0];
	reg tagbits [7:0];
	reg validbits [7:0];

	//Variables for indexing
	wire [2:0] tag, index;

	//16 blocks - 4 bits - 2bits are Zero
	wire [1:0] offset;
	
	wire [127:0] instr_block;
	wire [2:0] cache_tag;
	wire VALID;
	
	//Variables for tag comparison and validation
	wire tagMatch;
	wire HIT;
	
	//Wires for instruction word selection
	reg [31:0] loaded_instr;
	
	
	//Asserting BUSYWAIT signal upon read control signal
	always @ (ADDRESS)	 BUSYWAIT = 1'b1;
	

	//The instruction cache should split the address into Tag, Index and Offset sections
	assign {tag, index, offset} = ADDRESS[9:2];

	//Indexing of cache storage
	assign #1 instr_block = instr_block_array[index];
	assign #1 cache_tag = tagbits[index];
	assign #1 VALID = validbits[index];
	
	
	//Tag comparison
	assign #0.9 tagMatch = (tag == cache_tag)? 1:0;

	//Assigning HIT value
	assign HIT = tagMatch & VALID;
	
	//Instruction Word Selection
	always @ (*)
	begin
		case (offset)
			2'b00:	loaded_instr = #1 instr_block[31:0];
			2'b01:	loaded_instr = #1 instr_block[63:32];
			2'b10:	loaded_instr = #1 instr_block[95:64];
			2'b11:	loaded_instr = #1 instr_block[127:96];
		endcase
	end
	
	//Assigning selected instruction word to output if it is a HIT
	assign readinst = (HIT)? loaded_instr:32'bx;
	

	always @ (CLK) 
		if (HIT) 
			BUSYWAIT = 1'b0;
	
	/* Cache Controller FSM Start */
	// This section implements the finite state machine (FSM) for the cache controller.
	// It controls the state transitions and output values based on the current state and input conditions.
    
	parameter IDLE = 3'b000, MEM_READ = 3'b001;
    reg [2:0] state, next_state;
	
	// combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if (!HIT)  
                    next_state = MEM_READ;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_BUSYWAIT)
                    next_state = IDLE;
                else    
                    next_state = MEM_READ;
        endcase
    end
	
    // combinational output logic
    always @ (*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_ADDRESS = 8'dx;
            end
         
            MEM_READ: 
            begin
				BUSYWAIT = 1;
                mem_read = 1;
                mem_ADDRESS = {tag, index};
                #1 

				if(mem_BUSYWAIT == 0) 
				begin
					mem_read = 0;
					mem_ADDRESS = 8'dx;
                    instr_block_array[index]  = mem_inst;
                    if (mem_inst != 32'dx) validbits[index] = 1;
                    tagbits[index] = tag;
                end
            end 
        endcase
    end

    // sequential logic for state transitioning
	integer i;
    always @(posedge CLK, RESET)
    begin
        if(RESET) 
			begin
				state = IDLE;
				for(i = 0 ; i<8 ;i = i+1) 
					begin
						validbits[i] = 0;
					end
			end
        else
            state = next_state;
    end

	/* Cache Controller FSM End */
endmodule