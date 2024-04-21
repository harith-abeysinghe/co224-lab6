module alu(DATA1, DATA2, RESULT, SELECT);
    // Defining ports
    input [7:0] DATA1, DATA2;
    output [7:0] RESULT;
    input [2:0] SELECT;
    reg [7:0] RESULT;

    // Wires for the different cases
    wire [7:0] C0 , C1 , C2, C3 ;
    
    // Forward
    FORWARD case0(DATA1, DATA2,C0);

    // Add
    ADD case1(DATA1,DATA2,C1);

    // AND
    AND case2(DATA1,DATA2,C2);

    // OR
    OR case3(DATA1,DATA2,C3);


    always @*
    // Defining each case
    begin
        case(SELECT)
        //mov, loadi
        3'b000:
            begin
                RESULT = C0;
            end

        //add
        3'b001:
            begin
                RESULT = C1;
            end

        //bitwise and
        3'b010:
            begin
                RESULT = C2;
            end

        //bitwise or
        3'b011:
            begin
                RESULT = C3;
            end

        //reserved
        3'b1xx:
            begin
            ;
            end
        default: RESULT = DATA2 ;
        endcase
    end
endmodule

// This module forwards the second operand to the result
module FORWARD(DATA1, DATA2, RESULT);
    input [7:0] DATA1 , DATA2 ;
    output [7:0] RESULT;
    assign #1 RESULT = DATA2;
endmodule

// This module adds the two operands
module  ADD(DATA1, DATA2, RESULT);
    input [7:0] DATA1 , DATA2 ;
    output [7:0] RESULT;
    assign #2 RESULT = DATA1 + DATA2;
endmodule

// This module returns the bitwise-AND product of two operands
module AND(DATA1, DATA2, RESULT);
    input [7:0] DATA1 , DATA2 ;
    output [7:0] RESULT;
    assign #1 RESULT = DATA1 & DATA2;
endmodule

// This module returns the bitwise-OR product of two operands
module OR(DATA1, DATA2, RESULT);
    input [7:0] DATA1 , DATA2 ;
    output [7:0] RESULT;
    assign #1 RESULT = DATA1 | DATA2;
endmodule