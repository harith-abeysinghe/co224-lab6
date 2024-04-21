`include "ALU.v"
`include "REGFILE.v"

module cpu(PC,INSTRUCTION,CLK,RESET);
    //Input
    input [31:0] INSTRUCTION;
    input CLK,RESET;

    //output
    output reg [31:0] PC;

    //Wires for reg_file
    wire [2:0] READREG1, READREG2, WRITEREG;
	wire [7:0] REGOUT1, REGOUT2;
	reg WRITEENABLE;

    //Wires for ALU
    wire [7:0] OPERAND1, OPERAND2, ALURESULT;
	reg [2:0] ALUOP;
	wire reg ZERO; 

    //Wires for MUX1
	wire [7:0] negatedOp;
	wire [7:0] registerOp;
	reg signSelect;
	
	//Wires for MUX2
	wire [7:0] IMMEDIATE;
	reg immSelect;
	
	//reg for PC
	reg [31:0] PCreg;
	
	//reg for OPCODE
	reg [7:0] OPCODE;

    //Instantiation reg_file
	reg_file reg_file1(ALURESULT, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET);
	
	//Instantiation alu
	ALU alu1(REGOUT1, OPERAND2, ALURESULT, ALUOP, ZERO);
	
	// Instantiation twoscomplement
	twocomp twocomp1(REGOUT2, negatedOp);
	
	//Instantiation muxs
	mux mux1(REGOUT2, negatedOp, signSelect, registerOp);
	mux mux2(registerOp, IMMEDIATE, immSelect, OPERAND2);

	//Adder ports
	//PC,PCreg Already defined

	
	//Flow control ports
	reg jump, branch;
	wire flow_out;

	
	
	//Flow control 
	flowcontrol flow(jump, branch, ZERO, flow_out);
    
	
	
	
	
	//Update PC in every positive edge clock cycles
	always @ ( posedge CLK)
	begin
		if (RESET == 1'b1) 
		begin  // Reset the PC counter
			#1
			PC = 0;	
			PCreg = 0;
		end
		else #1 PC = PCreg;	// Else update the PC counter
	end
	
	
	//Increase the PC counter
	always @ (PC)
	begin
		#1 PCreg = PCreg + 4;
	end

    //Split the instruction word into acording registeraddres and opcodes
    assign READREG1 = INSTRUCTION[15:8];
	assign IMMEDIATE = INSTRUCTION[7:0];
	assign READREG2 = INSTRUCTION[7:0];
	assign WRITEREG = INSTRUCTION[23:16];

    //Controller unit for decoding the instruction
	always @ (INSTRUCTION)
	begin
	
		OPCODE = INSTRUCTION[31:24];	//Extract OPCODE from instruction
		#1	
		//Mux

		// New reg values (jump & branch) are added to each opcode
		case (OPCODE)
		
			//loadi - 0 
			8'b00000000:	begin
								ALUOP = 3'b000;			//Set ALU to forward
								immSelect = 1'b1;		//Set MUX to select immediate value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end
		
			//mov - 1
			8'b00000001:	begin
								ALUOP = 3'b000;			//Set ALU to FORWARD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end
			
			//add - 2
			8'b00000010:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end	
		
			//sub - 3
			8'b00000011:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b1;		//Set sign select MUX to negative sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end

			//and - 4
			8'b00000100:	begin
								ALUOP = 3'b010;			//Set ALU to AND
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end
							
			//or - 5
			8'b00000101:	begin
								ALUOP = 3'b011;			//Set ALU to OR
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								jump = 1'b0;			// Jump is 0
								branch = 1'b0;			// Branch is 0
							end
			
			// j and beq are new instructions


			//j - 6
			8'b00000110:	begin
								WRITEENABLE = 1'b0;		//Enable writing to register
								jump = 1'b1;			// Jump is 1
								branch = 1'b0;			// Branch is 0
							end
						
			//beq - 7
			8'b00000111:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								WRITEENABLE = 1'b0;		//Enable writing to register
								immSelect = 1'b1;		//Set MUX to select immediate value
								signSelect = 1'b1;		//Set sign select MUX to negative sign
								jump = 1'b0;			// Jump is 0
								branch = 1'b1;			// Branch is 1
							end
		endcase
		
	end

endmodule


// This module calculates 2nd's complement
module twocomp(IN, OUT);

	//Input
	input [7:0] IN;

    //Output
	output [7:0] OUT;
	
	//Calculate 2nd's complement
	assign #1 OUT = ~IN + 1;

endmodule

module mux(IN1, IN2, SELECT, OUT);

	//Input
	input [7:0] IN1, IN2;
	input SELECT;

    //Output
	output reg [7:0] OUT;
	
	//Select input acroding to select bit
	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		//Select input 2
		begin
			OUT = IN2;
		end
		else					//Select input 1
		begin
			OUT = IN1;
		end
	end

endmodule


// Newly Added Modules 

// Module for Flow Control
module flowcontrol(jump, branch, zero, out);

    // Input ports

	// jump & branch are from CU
	// zero is from ALU
    input jump, branch, zero;

    // Output ports
    output out;

    assign out = jump | (branch & zero);
    // Flow control output (out) is true if jump is true or if both branch and zero are true

endmodule


// Module to Calculate PC + 4
module PC_Adder(PC, PC_Next);
    // Input
    input [31:0] PC;

    // Output
    output [31:0] PC_Next;
    
    assign #1 PC_Next = PC + 4;
    // PC_Next is calculated by adding 4 to the input PC with a delay of 1 time unit

endmodule


// OFFSET Adder module to support jump and branch functions
module OFFSETADDER (PC, Offset, Target);

	// Input
	input [31:0] PC;     // Program Counter input
    input [7:0] Offset;     // Offset value input (8-bit)
    
	// Output
	output [31:0] Target;    // Target address output



    // Wire to store sign extension of the offset value
    wire [21:0] signBits;   

    // Perform sign extension by replicating the MSB of Offset 22 times
    assign signBits = {22{Offset[7]}};

    // Calculate the target address by adding the sign-extended offset to PC
    assign #2 Target = PC + {signBits, Offset, 2'b0};
    // Target address is obtained by concatenating sign-extended offset, Offset, and two zero bits, and adding it to PC
    // There is a delay of 2 time units in calculating the Target

endmodule
