`include "ALU.v"
`include "reg_file.v"
`timescale 1ns/100ps

module CPU(PC, INSTRUCTION, CLK, RESET, READ, WRITE, ADDRESS, WRITEDATA, READDATA, BUSYWAIT, INSTR_BUSYWAIT);

	//Input Ports
	input [31:0] INSTRUCTION;
	input [7:0] READDATA;
	input CLK, RESET, BUSYWAIT, INSTR_BUSYWAIT;

	//Output Ports
	output reg [31:0] PC;
	output [7:0] ADDRESS, WRITEDATA;
	output reg READ, WRITE;

	//Connections for Reg_File
	wire [2:0] READREG1, READREG2, WRITEREG;
	wire [7:0] REGOUT1, REGOUT2;
	reg WRITEENABLE;

	//Connections for ALU
	wire [7:0] OPERAND1, OPERAND2, ALURESULT;
	reg [2:0] ALUOP;
	wire ZERO,CHOICE;
	reg [3:0] SHIFT;

	reg [7:0] OPCODE;

	//Connections for negation MUX
	wire [7:0] negatedOp;
	wire [7:0] registerOp;
	reg signSelect;

	//Connections for immediate value MUX
	wire [7:0] IMMEDIATE;
	reg immSelect;

	//PC+4 and PCout
	wire [31:0] PCadd;
	wire [31:0] PCout;
	
	//BUSYWAIT MUX
	wire [31:0] newPC;

	//Jump/Branch Adder
	wire [31:0] TARGET;
	wire [7:0] OFFSET;
	
	//JUMP, BRANCH control
	reg JUMP;
	reg BRANCH;

	//flow control MUX
	wire flowSelect;
	
	//Data memory
	assign ADDRESS = ALURESULT;
	assign WRITEDATA = REGOUT1;
	
	//data memory MUX
	reg Data_MUX_Select;
	wire [7:0] REG_INPUT;
	
	//Register File 
	reg_file my_reg(REG_INPUT, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET);
	
	//ALU
	ALU my_alu(REGOUT1, OPERAND2, ALURESULT, ALUOP, ZERO,SHIFT, CHOICE);
	
	//2's Complement
	twoComp my_twoComp(REGOUT2, negatedOp);
	
	mux negationMUX(REGOUT2, negatedOp, signSelect, registerOp);
	mux immediateMUX(registerOp, IMMEDIATE, immSelect, OPERAND2);

	//PC+4 Adder
	PC_Adder PC_adder(PC, PCadd);
	
	//Jump/Branch Target Adder
	OFFSETADDER my_OFFSETADDER(PCadd, OFFSET, TARGET);
	
	//Flow Control
	flowControl my_flowControl(JUMP, BRANCH, ZERO, flowSelect);
	
	//Flow Control MUX
	mux32 flowctrlmux(PCadd, TARGET, flowSelect, PCout);
	
	//Data Memory MUX
	mux datamux(ALURESULT, READDATA, Data_MUX_Select, REG_INPUT);
	
	//MUX to Change PC value based on BUSYWAIT signal
	//If BUSYWAIT is HIGH, newPC is the same PC value(Stalled)
	//Else newPC is next PC value
	mux32 busywaitMUX(PCout, PC, (BUSYWAIT | INSTR_BUSYWAIT), newPC);
	
	//PC Update
	always @ (posedge CLK)
	begin
		if (RESET == 1'b1) #1 PC = 0;		//If RESET signal is HIGH, set PC to zero
		else #1 PC = newPC;					//Write new PC value
	end
	
	//Clearing READ/WRITE controls for Data Memory when BUSYWAIT is de-asserted
	always @ (BUSYWAIT)
	begin
		if (BUSYWAIT == 1'b0)
		begin
			READ = 0;
			WRITE = 0;
		end
	end
	
	assign READREG1 = INSTRUCTION[15:8];
	assign IMMEDIATE = INSTRUCTION[7:0];
	assign READREG2 = INSTRUCTION[7:0];
	assign WRITEREG = INSTRUCTION[23:16];
	assign OFFSET = INSTRUCTION[23:16];
	
	
	
	//Decoding the instruction
	always @ (INSTRUCTION)
	begin
		//if (!INSTR_BUSYWAIT)
		//begin
			#1			//1 Time Unit Delay for Decoding process
			OPCODE = INSTRUCTION[31:24];	//Mapping the OP-CODE section of the instruction to OPCODE
			case (OPCODE)
			
				//loadi instruction
				8'b00000000:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b1;		//Set MUX to select immediate value
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									Data_MUX_Select = 1'b0;		//Set Data Memory MUX to ALU output 
								end
			
				//mov instruction
				8'b00000001:	begin
									ALUOP = 3'b000;			//Set ALU to FORWARD
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									Data_MUX_Select = 1'b0;		//Set Data Memory MUX to ALU output
								end
				
				//add instruction
				8'b00000010:	begin
									ALUOP = 3'b001;			//Set ALU to ADD
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									Data_MUX_Select = 1'b0;		//Set Data Memory MUX to ALU output
								end	
			
				//sub instruction
				8'b00000011:	begin
									ALUOP = 3'b001;			//Set ALU to ADD
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b1;		//Set sign select MUX to negative sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									Data_MUX_Select = 1'b0;		//Set Data Memory MUX to ALU output
								end

				//and instruction
				8'b00000100:	begin
									ALUOP = 3'b010;			//Set ALU to AND
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									Data_MUX_Select = 1'b0;		//Set Data Memory MUX to ALU output
								end
								
				//or instruction
				8'b00000101:	begin
									ALUOP = 3'b011;			//Set ALU to OR
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			
									WRITE = 1'b0;			
									Data_MUX_Select = 1'b0;	
								end
				
				//j instruction
				8'b00000110:	begin
									JUMP = 1'b1;			//Set JUMP control signal to 1
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		//Disable writing to register
									READ = 1'b0;			
									WRITE = 1'b0;			
									Data_MUX_Select = 1'b0;		
								end
				
				//beq instruction
				8'b00000111:	begin
									ALUOP = 3'b001;			//Set ALU to ADD
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b1;		//Set sign select MUX to negative sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b1;			//Set BRANCH control signal to 1
									WRITEENABLE = 1'b0;		
									READ = 1'b0;			
									WRITE = 1'b0;			
									Data_MUX_Select = 1'b0;		
								end
								
				//lwd instruction
				8'b00001000:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		
									READ = 1'b1;			
									WRITE = 1'b0;			
									Data_MUX_Select = 1'b1;	
								end
								
				//lwi instruction
				8'b00001001:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b1;		//Set MUX to select immediate value
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		
									READ = 1'b1;			
									WRITE = 1'b0;			
									Data_MUX_Select = 1'b1;		
								end
				
				//swd instruction
				8'b00001010:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		
									READ = 1'b0;			
									WRITE = 1'b1;			
								end
								
				//swi instruction
				8'b00001011:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b1;		//Set MUX to select immediate value
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		
									READ = 1'b0;			
									WRITE = 1'b1;			
								end
			endcase
		//end
	end
	
endmodule

module twoComp(IN, OUT);

	//input and output ports
	input [7:0] IN;
	output [7:0] OUT;
	assign #1 OUT = ~IN + 1;

endmodule


module OFFSETADDER(PC, OFFSET, TARGET);
	
	//input and output ports
	input [31:0] PC;
	input [7:0] OFFSET;
	output [31:0] TARGET;
	
	wire [21:0] signBits;
	
	assign signBits = {22{OFFSET[7]}};
	
	assign #2 TARGET = PC + {signBits, OFFSET, 2'b0};	
	
endmodule


//The PC_Adder module 
module PC_Adder(PC, PCadd);
	
	//input and output ports
	input [31:0] PC;
	output [31:0] PCadd;

	//Assign PC+4 value
	assign #1 PCadd = PC + 4;
	
endmodule



module mux(IN1, IN2, SELECT, OUT);

	//Input and output port declaration
	input [7:0] IN1, IN2;
	input SELECT;
	output reg [7:0] OUT;
	
	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		
			begin
				OUT = IN2;
			end
		else					
			begin
				OUT = IN1;
			end
	end

endmodule


module mux32(IN1, IN2, SELECT, OUT);

	//Input and output port declaration
	input [31:0] IN1, IN2;
	input SELECT;
	output reg [31:0] OUT;
	

	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		
			begin
				OUT = IN2;
			end
		else					
			begin
				OUT = IN1;
			end
	end

endmodule


module flowControl(JUMP, BRANCH, ZERO, OUT);

	//Input and output port declaration
	input JUMP, BRANCH, ZERO;
	output OUT;

	assign OUT = JUMP | (BRANCH & ZERO);

endmodule


