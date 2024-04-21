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
	alu alu1(REGOUT1, OPERAND2, ALURESULT, ALUOP);
	// Instantiation twoscomplement
	twocomp twocomp1(REGOUT2, negatedOp);
	//Instantiation muxs
	mux mux1(REGOUT2, negatedOp, signSelect, registerOp);
	mux mux2(registerOp, IMMEDIATE, immSelect, OPERAND2);

    //Update PC in every positive edge clock cycles
	always @ ( posedge CLK)
	begin
		if (RESET == 1'b1) 
		begin  // Reset the PC counter
			#1;
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
		case (OPCODE)
		
			//loadi - 0 
			8'b00000000:	begin
								ALUOP = 3'b000;			//Set ALU to forward
								immSelect = 1'b1;		//Set MUX to select immediate value
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
							end
		
			//mov - 1
			8'b00000001:	begin
								ALUOP = 3'b000;			//Set ALU to FORWARD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
							end
			
			//add - 2
			8'b00000010:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
							end	
		
			//sub - 3
			8'b00000011:	begin
								ALUOP = 3'b001;			//Set ALU to ADD
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b1;		//Set sign select MUX to negative sign
								WRITEENABLE = 1'b1;		//Enable writing to register
							end

			//and - 4
			8'b00000100:	begin
								ALUOP = 3'b010;			//Set ALU to AND
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
							end
							
			//or - 5
			8'b00000101:	begin
								ALUOP = 3'b011;			//Set ALU to OR
								immSelect = 1'b0;		//Set MUX to select register input
								signSelect = 1'b0;		//Set sign select MUX to positive sign
								WRITEENABLE = 1'b1;		//Enable writing to register
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