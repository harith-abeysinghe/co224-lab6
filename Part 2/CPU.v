`include "ALU.v"
`include "REGFILE.v"



module cpu(PC,INSTRUCTION,CLK,RESET,BUSYWAIT, READMEM, WRITEMEM, ADDRESS, WRITEDATA, READDATA);
    //Input
    input [31:0] INSTRUCTION;
    input CLK,RESET;

    //output
    output reg [31:0] PC;

	//New wires and regs for data memory
	//----------------------------------
	input BUSYWAIT;
    input [7:0] READDATA;

	output reg READMEM, WRITEMEM;
    output [7:0] ADDRESS, WRITEDATA;
	//----------------------------------

    //Wires for reg_file
    wire [2:0] READREG1, READREG2, WRITEREG;
	wire [7:0] REGOUT1, REGOUT2;
	reg WRITEENABLE;

    //Wires for ALU
    wire [7:0] OPERAND1, OPERAND2, ALURESULT;
	reg [2:0] ALUOP;
	wire reg ZERO;
	wire [3:0] Shift;
	reg Shift_Choice = 1'b0 ; 

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
	ALU alu1(REGOUT1, OPERAND2, ALURESULT, ALUOP, ZERO,Shift,Shift_Choice);
	
	// Instantiation twoscomplement
	twocomp twocomp1(REGOUT2, negatedOp);
	
	//Instantiation muxs
	mux mux1(REGOUT2, negatedOp, signSelect, registerOp);
	mux mux2(registerOp, IMMEDIATE, immSelect, OPERAND2);

	//Adder ports
	//PC,PCreg Already defined

	//Target Adder
	wire [31:0] offset_out ;
	wire [7:0] OFFSET;
	OFFSETADDER target(PCreg, OFFSET, offset_out);
	
	//mux 3
	wire flow_out;
	wire [31:0] NewPC; 
	muxNew MUX4(PCreg, offset_out,flow_out, NewPC);

	//Flow control ports
	reg [1:0] bj;
	

	//Flow control 
	flowcontrol flow(bj, ZERO, flow_out);
    
	//ISA Extended Parts

	//Multiplication
	
	wire [7:0] in1_multi, in2_multi;
	wire [7:0] out_multi;
	multiplication mult(in1_multi, in2_multi, out_multi);
	
	//Data memory
    assign WRITEDATA = REGOUT1;
    assign ADDRESS = ALURESULT;

	//New Mux
	//Using ALURESULT, READDATA, MUX5
	reg SEL_MUX4 = 0;
	wire [7:0] MUX5;
	mux mux4(ALURESULT, READDATA,SEL_MUX4, MUX5);
	
	
	//Update PC in every positive edge clock cycles
	always @ ( posedge CLK)
	begin
		if (RESET == 1'b1) 
		begin  // Reset the PC counter
			#1
			PC = 0;	
			PCreg = 0;
		end
		else if (BUSYWAIT == 1'b1);	
		else #1 PC = NewPC;	// Else update the PC counter
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
	assign Shift = INSTRUCTION[7:0];
	
	assign in2_multi = INSTRUCTION[7:0];
	assign in1_multi = INSTRUCTION[15:8];
	

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
								bj = 2'b00;			// Branch is 0
								SEL_MUX4 = 0;
								
							end
		
			//mov - 1
			8'b00000001:	begin
								ALUOP = 3'b000;			//Set ALU to FORWARD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;
							end
			
			//add - 2
			8'b00000010:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;

							end	
		
			//sub - 3
			8'b00000011:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b1;		//Set sign select MUX to negative sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;

							end

			//and - 4
			8'b00000100:	begin
								ALUOP = 3'b010;			//Set ALU to AND
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;

							end
							
			//or - 5
			8'b00000101:	begin
								ALUOP = 3'b011;			//Set ALU to OR
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;

							end
			
			// j and beq are new instructions


			//j - 6
			8'b00000110:	begin
								WRITEENABLE = 1'b0;		//Enable writing to register
								bj = 2'b01;				// jump
								SEL_MUX4 = 0;

							end
						
			//beq - 7
			8'b00000111:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								WRITEENABLE = 1'b0;		//Enable writing to register
								immSelect = 1'b1;		//Set MUX to select immediate value
								signSelect = 1'b1;		//Set sign select MUX to negative sign
								bj = 2'b10;				// BEQ
								SEL_MUX4 = 0;
							end


			//EXTENDED ISA PARTS

			//mult - 8
			8'b00001000:	begin
								ALUOP = 3'b100;			//Set ALU to Multiply
								WRITEENABLE = 1'b1;		//Enable writing to register
								immSelect = 1'b0;		//Set MUX to select register value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								bj = 2'b00;			// No branch or jump
								SEL_MUX4 = 0;
							end


			//bne - 9 
			8'b00001001:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								WRITEENABLE = 1'b0;		//Enable writing to register
								immSelect = 1'b1;		//Set MUX to select register value
								signSelect = 1'b1;		//Set sign select MUX to positive sign
								bj = 2'b11;				// BNE
								SEL_MUX4 = 0;
							end

			//arithmetic rigth - 10 
			8'b00001010:	begin
								ALUOP = 3'b101;			//Set ALU to Arithmetic Right
								WRITEENABLE = 1'b1;		//Enable writing to register
								immSelect = 1'b0;		//Set MUX to select register value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								bj = 2'b00;				// Normal
								SEL_MUX4 = 0;
							end


			// Rotate - 11 
			8'b00001011:	begin
								ALUOP = 3'b110;			//Set ALU to ADD
								WRITEENABLE = 1'b1;		//Enable writing to register
								immSelect = 1'b0;		//Set MUX to select register value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								bj = 2'b00;				//Normal
								SEL_MUX4 = 0;
							end
			// Left Shift - 12 
			8'b00001100:	begin
								ALUOP = 3'b111;			//Set ALU to ADD
								WRITEENABLE = 1'b1;		//Enable writing to register
								immSelect = 1'b0;		//Set MUX to select register value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								bj = 2'b00;				//Normal
								SEL_MUX4 = 0;
							end

			// Left Shift - 12 
			8'b00001101:	begin
								ALUOP = 3'b111;			//Set ALU to ADD
								WRITEENABLE = 1'b1;		//Enable writing to register
								immSelect = 1'b0;		//Set MUX to select register value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								bj = 2'b00;				//Normal
								Shift_Choice = 1'b1; //Changing to right shift
								SEL_MUX4 = 0;
							end


			//New OPCODES for Data Memory

			//Load word
			8'b00001110:	begin
								WRITEENABLE = 1'b1;   		//Trigerring the write enable
								signSelect = 0;    		//Selecting the positive number
								immSelect = 0;   		//Selecting the immediate operand
								ALUOP = 3'b000;		//selecting the ADD operation from ALU
								bj = 2'b00; 	//normal flow
								READMEM = 1;			//assigning the READMEM into 1
								WRITEMEM = 0;
								
								SEL_MUX4 = 1;
								
							end
							


			//Load immediate
			8'b00001111:	begin
								WRITEENABLE = 1'b1;   		//Trigerring the write enable
								signSelect = 0;    		//Selecting the positive number
								immSelect = 1;   		//Selecting the immediate operand
								ALUOP = 3'b000;		//selecting the ADD operation from ALU
								bj = 2'b00; 	//normal flow
								READMEM = 1;			//assigning the READMEM into 1
								WRITEMEM = 0;
								//MUX5 = 1;			//selecting the readdata value into the register file
								SEL_MUX4 = 1;
								
							end
			//Stroe word
			8'b00010000:	begin
								WRITEENABLE = 1'b1;   		//Trigerring the write enable
								signSelect = 0;    		//Selecting the positive number
								immSelect = 0;   		//Selecting the immediate operand
								ALUOP = 3'b000;		//selecting the ADD operation from ALU
								bj = 2'b00; 	//normal flow
								WRITEMEM = 1;		//assigning the WRITEMEM into 1
								READMEM = 0;
				
								SEL_MUX4 = 0;
							end
			//Store immediate
			8'b00010001:	begin
								WRITEENABLE = 1'b1;   		//Trigerring the write enable
								signSelect= 0;    		//Selecting the positive number
								immSelect = 1;   		//Selecting the immediate operand
								ALUOP = 3'b000;		//selecting the ADD operation from ALU
								bj = 2'b00; 	//normal flow
								WRITEMEM = 1;		//assigning the WRITEMEM into 1
								READMEM = 0;
								
								SEL_MUX4 = 0;
								
							end
		endcase
		
	end


always @(BUSYWAIT)  
	begin
		if(~BUSYWAIT) 
		begin
			READMEM=0;
			WRITEMEM=0;
		end
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

//New flow control module
module flowcontrol(branch_jump, zero, out);
    input zero; //input ports declaration
    input [1:0] branch_jump;
    output out; //output port declaration

    assign out = branch_jump[0] ^ (branch_jump[1] & zero);

	/*
		branch_jump = branch , jump
		00 - No Branching or jumping
		01 - Jump
		10 - BEQ
		11 - BNE
	*/

endmodule

module muxNew(IN1, IN2, SELECT, OUT);

	//Input
	input [31:0] IN1, IN2;
	input SELECT;

    //Output
	output reg [31:0] OUT;
	
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