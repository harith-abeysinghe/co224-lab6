
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
	reg [127:0] instr_block_array [7:0];
	reg tag_array [7:0];
	reg valid_array [7:0];


	//Variables for indexing
	wire [2:0] tag, index;
	wire [1:0] offset;
	
	wire [127:0] instr_block;
	wire [2:0] cache_tag;
	wire valid;
	
	//Variables for tag comparison and validation
	wire tagMatch;
	wire hit;
	
	//Wires for instruction word selection
	reg [31:0] loaded_instr;
	
	
	//Asserting busywait signal upon read control signal
	always @ (address)	busywait = 1'b1;
	

	//Breaking down address
	assign {tag, index, offset} = address[9:2];

	//Indexing of cache storage
	assign #1 instr_block = instr_block_array[index];
	assign #1 cache_tag = tag_array[index];
	assign #1 valid = valid_array[index];
	
	
	//Tag comparison
	assign #0.9 tagMatch = (tag == cache_tag)? 1:0;

	//Assigning hit status based on tag comparison and validation
	assign hit = tagMatch & valid;
	
	
	
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
	
	//Assigning selected instruction word to output if it is a hit
	assign readinst = (hit)? loaded_instr:32'bx;
	
	
	
	//Read Hit Handling
	always @ (clock) if (hit) busywait = 1'b0;
	
	

	
	/* Cache Controller FSM Start */
    parameter IDLE = 3'b000, MEM_READ = 3'b001;
    reg [2:0] state, next_state;
	
	// combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if (!hit)  
                    next_state = MEM_READ;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
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
                mem_address = 8'dx;
                //busywait = 0;
            end
         
            MEM_READ: 
            begin
				busywait = 1;
                mem_read = 1;
                mem_address = {tag, index};
                
                // waiting until mem_busywait=0 and then takin #1 unit read data from instruction memory
                // At the same time valid bit and the tag array bit is changed with relevant value
                #1 
				if(mem_busywait == 0) 
				begin
					mem_read = 0;
					mem_address = 8'dx;
                    instr_block_array[index]  = mem_inst;
                    if (mem_inst != 32'dx) valid_array[index] = 1;
                    tag_array[index] = tag;
                end

            end

            
        endcase
    end


    // sequential logic for state transitioning
	integer i;
    always @(posedge clock, reset)
    begin
        if(reset) begin
            state = IDLE;
            for(i = 0 ; i<8 ;i = i+1) begin
                valid_array[i] = 0;
            end
        end
        else
            state = next_state;
    end
	
	
	
	/* Cache Controller FSM End */
	


endmodule