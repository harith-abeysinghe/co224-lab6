`timescale 1ns/100ps

module alu(DATA1, DATA2, RESULT, ZERO, SELECT);
	
	//Declaration of input ports
	input [7:0] DATA1, DATA2;
	input [2:0] SELECT;
	
	//Output port declaration
	output reg [7:0] RESULT;
	output ZERO;
	
	//Set of wires for outputs of each functional unit
	wire [7:0] forwardOut, addOut, andOut, orOut;
	
	
	//The functional units relevant to the different operations are instantiated here
	//They will output their result to the relevant Out wire
	FORWARD forwardUnit(DATA2, forwardOut);
	ADD addUnit(DATA1, DATA2, addOut);
	AND andUnit(DATA1, DATA2, andOut);
	OR orUnit(DATA1, DATA2, orOut);
	
	
	//This section of the ALU is analogous to a MUX
	//One of the functional units' results is sent to the RESULT output based on the SELECT value
	always @ (forwardOut, addOut, andOut, orOut, SELECT)	//RESULT output must be updated whenever the SELECT input or any of the functional units' outputs changes
	begin
		case (SELECT)		//Case statement to switch between the outputs

			3'b000 :	RESULT = forwardOut;	//SELECT = 0 : FORWARD
			
			3'b001 :	RESULT = addOut;		//SELECT = 1 : ADD
			
			3'b010 :	RESULT = andOut;		//SELECT = 2 : AND
			
			3'b011 :	RESULT = orOut;			//SELECT = 3 : OR
			
		endcase
	end
		
	//This section of the ALU contains the combinational logic to generate the ZERO output
	assign ZERO = ~(RESULT[0] | RESULT[1] | RESULT[2] | RESULT[3] | RESULT[4] | RESULT[5] | RESULT[6] | RESULT[7]);
	
endmodule



module FORWARD(DATA, RESULT);

	//Input port declaration
	input [7:0] DATA;
	
	//Output port declaration
	output [7:0] RESULT;
	
	//Assigns the value of DATA to RESULT after a delay of 1 time unit
	assign #1 RESULT = DATA;

endmodule

module ADD(DATA1, DATA2, RESULT);

	//Declaration of two 8-bit data inputs
	input [7:0] DATA1, DATA2;
	
	//Declaration of output
	output [7:0] RESULT;
	
	//Assigns evaluated addition of DATA1 and DATA2 to RESULT after 2 time unit delay
	assign #2 RESULT = DATA1 + DATA2;
	
endmodule

module AND(DATA1, DATA2, RESULT);

	//Input port declaration
	input [7:0] DATA1, DATA2;
	
	//Declaration of output port
	output [7:0] RESULT;
	
	//Assigns logical AND result of DATA1 and DATA2 to RESULT after 1 time unit delay
	assign #1 RESULT = DATA1 & DATA2;
	
endmodule
module OR(DATA1, DATA2, RESULT);

	//Input port declaration
	input [7:0] DATA1, DATA2;
	
	//Declaration of output port
	output [7:0] RESULT;
	
	//Assigns logical OR result of DATA1 and DATA2 to RESULT after 1 time unit delay
	assign #1 RESULT = DATA1 | DATA2;
	
endmodule