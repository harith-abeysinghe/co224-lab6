`include "alu.v"
`include "reg_file.v"
`timescale 1ns/100ps

module cpu(PC, INSTRUCTION, CLK, RESET, READ, WRITE, ADDRESS, WRITEDATA, READDATA, BUSYWAIT, INSTR_BUSYWAIT);

	//Input Port Declaration
	input [31:0] INSTRUCTION;
	input [7:0] READDATA;
	input CLK, RESET, BUSYWAIT, INSTR_BUSYWAIT;

	//Output Port Declaration
	output reg [31:0] PC;
	output [7:0] ADDRESS, WRITEDATA;
	output reg READ, WRITE;

	//Connections for Register File
	wire [2:0] READREG1, READREG2, WRITEREG;
	wire [7:0] REGOUT1, REGOUT2;
	reg WRITEENABLE;

	//Connections for ALU
	wire [7:0] OPERAND1, OPERAND2, ALURESULT;
	reg [2:0] ALUOP;
	wire ZERO;

	//Connections for negation MUX
	wire [7:0] negatedOp;
	wire [7:0] registerOp;
	reg signSelect;

	//Connections for immediate value MUX
	wire [7:0] IMMEDIATE;
	reg immSelect;

	//PC+4 value and PC value to be updated stored inside CPU
	wire [31:0] PCplus4;
	wire [31:0] PCout;
	
	//Connections for BUSYWAIT MUX
	wire [31:0] newPC;

	//Connections for Jump/Branch Adder
	wire [31:0] TARGET;
	wire [7:0] OFFSET;
	
	//Connections for flow control combinational unit
	reg JUMP;
	reg BRANCH;

	//Connections for flow control MUX
	wire flowSelect;
	
	//Connections to Data memory
	assign ADDRESS = ALURESULT;
	assign WRITEDATA = REGOUT1;
	
	//Connections for data memory MUX
	reg dataSelect;
	wire [7:0] REGIN;

	//Current OPCODE stored in CPU
	reg [7:0] OPCODE;

	//Instantiation of CPU modules
	//8x8 Register File
	//Register File WRITEENABLE signal is ANDed with the negation of the BUSYWAIT so that writes do not happen while data memory is busy
	reg_file my_reg(REGIN, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET);
	
	//ALU
	alu my_alu(REGOUT1, OPERAND2, ALURESULT, ZERO, ALUOP);
	
	//2's Complement Unit
	twosComp my_twosComp(REGOUT2, negatedOp);
	
	//Negation MUX (Chooses between +ve and -ve value of REGOUT2)
	mux negationMUX(REGOUT2, negatedOp, signSelect, registerOp);
	
	//Immediate Value MUX (Chooses between immediate value and register value for Operand 2 of ALU)
	mux immediateMUX(registerOp, IMMEDIATE, immSelect, OPERAND2);

	//PC+4 Adder
	pcAdder my_pcAdder(PC, PCplus4);
	
	//Jump/Branch Target Adder
	jumpbranchAdder my_jumpbranchAdder(PCplus4, OFFSET, TARGET);
	
	//Flow Control Combinational Logic Unit (Handles combinational logic for select input of Flow Control MUX)
	flowControl my_flowControl(JUMP, BRANCH, ZERO, flowSelect);
	
	//Flow Control MUX (Chooses between normal PC value or offset value for flow control instructions)
	mux32 flowctrlmux(PCplus4, TARGET, flowSelect, PCout);
	
	//Data Memory MUX
	mux datamux(ALURESULT, READDATA, dataSelect, REGIN);
	
	//MUX to Change PC value based on BUSYWAIT signal
	//If BUSYWAIT is HIGH, newPC is the same PC value(Stalled)
	//Else newPC is next PC value
	mux32 busywaitMUX(PCout, PC, (BUSYWAIT | INSTR_BUSYWAIT), newPC);
	
	
	//-----------------------
	// Control Logic for CPU
	//-----------------------
	
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
	
	
	//Relevant portions of INSTRUCTION are mapped to the respective units
	
	///////////////////////////////////////////////////////////////////
	/*    OP-CODE    /     RD/IMM    /       RT      /     RS/IMM    */
	/*    [31:24]    /    [23:16]    /     [15:8]    /      [7:0]    */
	///////////////////////////////////////////////////////////////////
	/*       |       /        |      /        |      /       |       */
	/*    OPCODE     /    WRITEREG   /    READREG1   /    READREG2   */
	/*               /     OFFSET    /               /   IMMEDIATE   */
	/*****************************************************************/
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
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output 
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
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
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
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
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
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
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
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
								end
								
				//or instruction
				8'b00000101:	begin
									ALUOP = 3'b011;			//Set ALU to OR
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
								end
				
				//j instruction
				8'b00000110:	begin
									JUMP = 1'b1;			//Set JUMP control signal to 1
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		//Disable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
								end
				
				//beq instruction
				8'b00000111:	begin
									ALUOP = 3'b001;			//Set ALU to ADD
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b1;		//Set sign select MUX to negative sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b1;			//Set BRANCH control signal to 1
									WRITEENABLE = 1'b0;		//Disable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b0;			//Set WRITE control signal to zero
									dataSelect = 1'b0;		//Set Data Memory MUX to ALU output
								end
								
				//lwd instruction
				8'b00001000:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b1;			//Set READ control signal to HIGH
									WRITE = 1'b0;			//Set WRITE control signal to zero
									dataSelect = 1'b1;		//Set Data Memory MUX to Data memory input
								end
								
				//lwi instruction
				8'b00001001:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b1;		//Set MUX to select immediate value
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b1;		//Enable writing to register
									READ = 1'b1;			//Set READ control signal to HIGH
									WRITE = 1'b0;			//Set WRITE control signal to zero
									dataSelect = 1'b1;		//Set Data Memory MUX to Data memory input
								end
				
				//swd instruction
				8'b00001010:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b0;		//Set MUX to select register input
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b1;			//Set WRITE control signal to HIGH
								end
								
				//swi instruction
				8'b00001011:	begin
									ALUOP = 3'b000;			//Set ALU to forward
									immSelect = 1'b1;		//Set MUX to select immediate value
									signSelect = 1'b0;		//Set sign select MUX to positive sign
									JUMP = 1'b0;			//Set JUMP control signal to zero
									BRANCH = 1'b0;			//Set BRANCH control signal to zero
									WRITEENABLE = 1'b0;		//Enable writing to register
									READ = 1'b0;			//Set READ control signal to zero
									WRITE = 1'b1;			//Set WRITE control signal to HIGH
								end
			endcase
		//end
	end
	
endmodule

module twosComp(IN, OUT);

	//Declaration of input and output ports
	input [7:0] IN;
	output [7:0] OUT;
	
	//Combinational logic to assign two's complement value of input to output after a delay of #1
	assign #1 OUT = ~IN + 1;

endmodule


//The Jump/Branch Adder calculates the target instruction address by adding the offset value to the PC+4 value
//after sign extension and multiplication by 4
//Contains a delay of 2 time units
module jumpbranchAdder(PC, OFFSET, TARGET);
	
	//Declaration of input and output ports
	input [31:0] PC;
	input [7:0] OFFSET;
	output [31:0] TARGET;
	
	wire [21:0] signBits;		//Bus to store extended sign bits
	
	assign signBits = {22{OFFSET[7]}};	//assigning the sign bit (MSB) of OFFSET to all 22 bits in signBits
	
	//GENERATING TARGET address by adding the OFFSET * 4 to the PC value after a delay of 2 time units
	//First 22 bits contain the extended sign bits, next 8 bits contain the actual offset, the next two bits are zeros due to shifting left by 2 (multiplication by 4)
	assign #2 TARGET = PC + {signBits, OFFSET, 2'b0};	
	
endmodule


//The pcAdder module generates the PC+4 value from the PC input after a delay of 1 time unit
module pcAdder(PC, PCplus4);
	
	//Declaration of input and output ports
	input [31:0] PC;
	output [31:0] PCplus4;

	//Assign PC+4 value to the output after 1 time unit delay
	assign #1 PCplus4 = PC + 4;
	
endmodule


//Generic 8-bit MUX module to be used inside the CPU
//Operation: SELECT == 0 : OUT = IN1
//			 SELECT == 1 : OUT = IN2
//Does not contain delays
module mux(IN1, IN2, SELECT, OUT);

	//Input and output port declaration
	input [7:0] IN1, IN2;
	input SELECT;
	output reg [7:0] OUT;
	
	//MUX should update output value upon change of any of the inputs
	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		//If SELECT is HIGH, switch to 2nd input
		begin
			OUT = IN2;
		end
		else					//If SELECT is LOW, switch to 1st input
		begin
			OUT = IN1;
		end
	end

endmodule


//32-bit MUX module for flow control operations
//Operation: SELECT == 0 : OUT = IN1
//			 SELECT == 1 : OUT = IN2
//Does not contain delays
module mux32(IN1, IN2, SELECT, OUT);

	//Input and output port declaration
	input [31:0] IN1, IN2;
	input SELECT;
	output reg [31:0] OUT;
	
	//MUX should update output value upon change of any of the inputs
	always @ (IN1, IN2, SELECT)
	begin
		if (SELECT == 1'b1)		//If SELECT is HIGH, switch to 2nd input
		begin
			OUT = IN2;
		end
		else					//If SELECT is LOW, switch to 1st input
		begin
			OUT = IN1;
		end
	end

endmodule


//Combinational Control Unit for flow control operations
//Operation: JUMP = 0  BRANCH = 0          : OUT = 0 (Normal flow)
//			 JUMP = 1                      : OUT = 1 (Offset flow)
//			 JUMP = 0  BRANCH = 1 ZERO = 0 : OUT = 0 (Normal flow)
//			 JUMP = 0  BRANCH = 1 ZERO = 1 : OUT = 1 (Offset flow)
//Contains no delays
module flowControl(JUMP, BRANCH, ZERO, OUT);

	//Input and output port declaration
	input JUMP, BRANCH, ZERO;
	output OUT;
	
	//Assigns OUT based on values of JUMP, BRANCH and ZERO using simple combinational logic
	assign OUT = JUMP | (BRANCH & ZERO);

endmodule


