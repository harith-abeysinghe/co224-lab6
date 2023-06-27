`timescale 1ns/100ps

module icache(clock, reset, address, readinst, busywait, mem_read, mem_address, mem_inst, mem_busywait);
	//Input and output port declaration
	input clock, reset, mem_busywait;
	input [9:0] address;
	input [127:0] mem_inst;
	
	output reg mem_read, busywait;
	output reg [5:0] mem_address;
	output [31:0] readinst;
	
	//Instruction Cache Storage
	reg [127:0] instr_block_array [7:0]; // Storage for instruction blocks
	reg tag_array [7:0]; // Array to store tags for each block
	reg valid_array [7:0]; // Array to store validity status for each block

	//Variables for indexing
	wire [2:0] tag, index; // Breaking down the address into tag, index, and offset
	wire [1:0] offset;
	
	wire [127:0] instr_block; // Selected instruction block from the cache
	wire [2:0] cache_tag; // Tag of the selected instruction block
	wire valid; // Validity status of the selected instruction block
	
	//Variables for tag comparison and validation
	wire tagMatch; // Signal indicating whether the tag matches the cache tag
	wire hit; // Signal indicating whether there is a cache hit
	
	//Wires for instruction word selection
	reg [31:0] loaded_instr; // Selected instruction word from the cache
	
	//Asserting busywait signal upon read control signal
	always @ (address)	busywait = 1'b1;

	//Breaking down address
	assign {tag, index, offset} = address[9:2]; // Extracting tag, index, and offset from the address
	
	//Indexing of cache storage
	assign #1 instr_block = instr_block_array[index]; // Selecting the instruction block based on the index
	assign #1 cache_tag = tag_array[index]; // Selecting the tag associated with the instruction block
	assign #1 valid = valid_array[index]; // Checking the validity status of the instruction block
	
	//Tag comparison
	assign #0.9 tagMatch = (tag == cache_tag) ? 1 : 0; // Comparing the tag with the cache tag
	
	//Assigning hit status based on tag comparison and validation
	assign hit = tagMatch & valid; // A hit occurs if the tag matches and the block is valid
	
	//Instruction Word Selection
	always @ (*)
	begin
		case (offset)
			2'b00:	loaded_instr = #1 instr_block[31:0]; // Selecting the appropriate instruction word based on the offset
			2'b01:	loaded_instr = #1 instr_block[63:32];
			2'b10:	loaded_instr = #1 instr_block[95:64];
			2'b11:	loaded_instr = #1 instr_block[127:96];
		endcase
	end
	
	//Assigning selected instruction word to output if it is a hit
	assign readinst = (hit) ? loaded_instr : 32'bx; 
	// If it's a hit, assign the selected instruction word to the output; otherwise, assign an "x" value
	
	//Read Hit Handling
	always @ (clock)
		if (hit) busywait = 1'b0; // If it's a hit, set the busywait signal to 0 to indicate completion
	
	/* Cache Controller FSM Start */
	parameter IDLE = 3'b000, MEM_READ = 3'b001;
	reg [2:0] state, next_state;

	// combinational next state logic
	always @(*)
	begin
		case (state)
			IDLE:
				if (!hit)
					next_state = MEM_READ; // If there's a miss, transition to the MEM_READ state
				else
					next_state = IDLE; // If there's a hit, stay in the IDLE state

			MEM_READ:
				if (!mem_busywait)
					next_state = IDLE; // If memory is not busy, transition back to IDLE state
				else    
					next_state = MEM_READ; // If memory is busy, stay in the MEM_READ state
		endcase
	end

	// combinational output logic
	always @ (*)
	begin
		case (state)
            /*
                In the IDLE state, the FSM waits for an instruction access request. If the requested instruction is already in the 
                cache (hit), the FSM stays in the IDLE state and outputs the instruction word to the readinst output. 
                If the requested instruction is not in the cache (miss), the FSM transitions to the MEM_READ state.
            */

			IDLE:
			begin
				mem_read = 0; // Set the memory read control signal to 0
				mem_address = 8'dx; // Set the memory address to an undefined value
			end

			MEM_READ: 
			begin
				busywait = 1; // Set the busywait signal to 1 to indicate a read operation is in progress
				mem_read = 1; // Set the memory read control signal to 1
				mem_address = {tag, index}; // Set the memory address using the tag and index
				
				// waiting until mem_busywait=0 and then taking #1 unit read data from instruction memory
				// At the same time, the valid bit and the tag array bit are changed with the relevant value
				#1 
				if (mem_busywait == 0) 
				begin
					mem_read = 0; // Set the memory read control signal back to 0
					mem_address = 8'dx; // Set the memory address back to an undefined value
					instr_block_array[index]  = mem_inst; // Store the read instruction block in the cache storage
					if (mem_inst != 32'dx) valid_array[index] = 1; // Set the valid bit for the stored block if the read instruction is not undefined
					tag_array[index] = tag; // Set the tag for the stored block
				end
			end
		endcase
	end

	// sequential logic for state transitioning
	integer i;
	always @(posedge clock, reset)
	begin
		if (reset)
		begin
			state = IDLE; // Initialize the state to IDLE
			for (i = 0; i < 8; i = i + 1)
				valid_array[i] = 0; // Reset the validity status of all blocks to 0
		end
		else
			state = next_state; // Update the state based on the next state
	end
	/* Cache Controller FSM End */
	
endmodule
