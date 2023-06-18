`timescale 1ns/100ps
module ALU(DATA1, DATA2, RESULT, SELECT,ZERO,SHIFT,CHOICE);
    // Defining ports
    input [7:0] DATA1, DATA2;
    output [7:0] RESULT;
    input [2:0] SELECT;
    reg [7:0] RESULT;


    //Shift amount
    input [3:0] SHIFT;

    //choice for shifting left or right
    input CHOICE;

    //Zero port
    output ZERO;

    // Wires for the different cases
    wire [7:0] C0 , C1 , C2, C3;

    // Wires for Extended ISA 
    wire [7:0] C4, C5, C6, C7;
    
    // Forward
    FORWARD case0(DATA1, DATA2,C0);

    // Add
    ADD case1(DATA1,DATA2,C1);

    // AND
    AND case2(DATA1,DATA2,C2);

    // OR
    OR case3(DATA1,DATA2,C3);
    
    //multiplication
    multiplication case4(DATA1,DATA2,C4);
    
    //arthimetic right shift
    Arith_right case5(SHIFT,DATA1,C5);

    //rotate
    Rotate_right case6(SHIFT,DATA1,C6);

    //shift
    Shift case7(SHIFT,DATA1,C7,CHOICE);

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

        //multiiplication
        3'b100:
            begin
                RESULT = C4;
            end

        //Aritchmetic Right Shift
        3'b101:
            begin
                RESULT = C5;
            end

        //Rotate
        3'b110:
            begin
                RESULT = C6;
            end
        
        //Shift
        
        3'b111:
            begin
                RESULT = C7;
            end
        default: RESULT = DATA2 ;
        endcase
    end

    //The combinational logic to generate the ZERO output
	assign ZERO = ~(RESULT[0] | RESULT[1] | RESULT[2] | RESULT[3] | RESULT[4] | RESULT[5] | RESULT[6] | RESULT[7]);
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

// This module is used for multiplication ALUOP = 100
module multiplication(
  input [7:0] IN1,
  input [7:0] IN2,
  output [7:0] New_Num
);

  reg [7:0] partial_products[7:0];  // Array to store the partial products
  reg [7:0] sum;

  always @*
  begin
    #2  // Introduce a delay of 2 time units for multiplication

    // Generate partial products for each bit of the multiplier and multiplicand
    
    // Bit 0
    partial_products[0] = {(IN1[7] & IN2[0]), (IN1[6] & IN2[0]), (IN1[5] & IN2[0]), (IN1[4] & IN2[0]),
                           (IN1[3] & IN2[0]), (IN1[2] & IN2[0]), (IN1[1] & IN2[0]), (IN1[0] & IN2[0])};
    
    // Bit 1
    partial_products[1] = {(IN1[6] & IN2[1]), (IN1[5] & IN2[1]), (IN1[4] & IN2[1]), (IN1[3] & IN2[1]),
                           (IN1[2] & IN2[1]), (IN1[1] & IN2[1]), (IN1[0] & IN2[1]), 1'b0};
    
    // Bit 2
    partial_products[2] = {(IN1[5] & IN2[2]), (IN1[4] & IN2[2]), (IN1[3] & IN2[2]), (IN1[2] & IN2[2]),
                           (IN1[1] & IN2[2]), (IN1[0] & IN2[2]), 2'b0};
    
    // Bit 3
    partial_products[3] = {(IN1[4] & IN2[3]), (IN1[3] & IN2[3]), (IN1[2] & IN2[3]), (IN1[1] & IN2[3]),
                           (IN1[0] & IN2[3]), 3'b0};
    
    // Bit 4
    partial_products[4] = {(IN1[3] & IN2[4]), (IN1[2] & IN2[4]), (IN1[1] & IN2[4]), (IN1[0] & IN2[4]), 4'b0};
    
    // Bit 5
    partial_products[5] = {(IN1[2] & IN2[5]), (IN1[1] & IN2[5]), (IN1[0] & IN2[5]), 5'b0};
    
    // Bit 6
    partial_products[6] = {(IN1[1] & IN2[6]), (IN1[0] & IN2[6]), 6'b0};
    
    // Bit 7
    partial_products[7] = {(IN1[0] & IN2[7]), 7'b0};
    
    // Compute the final product by summing up the partial products
    sum = partial_products[0] + partial_products[1] + partial_products[2] +
          partial_products[3] + partial_products[4] + partial_products[5] +
          partial_products[6] + partial_products[7];
  end

  assign New_Num = sum;

endmodule





//testing the multiplication module
/* module mult_tb;
    reg clk;
    
    reg [7:0] in1 = 2;
    reg [7:0] in2 = 3;
    wire [7:0] out;

     multiplication mult(in1, in2, out);

    always begin
        #1 clk = ~clk;  // Toggle the clock every 5 time units
    end

    initial begin
        clk = 0;  
        
        // Apply inputs and display output
        
        in1 = 8'd3;
        in2 = 8'd7;
        #10;

        $finish;  // End the simulation
    end

    // Display the output
    always @(out)
        $display("Output: %d", out);

endmodule  */


// Arithmetic Right Shift : ALUOP = 101
module Arith_right(SHIFT,Number,Out_num);
    
    input [3:0] SHIFT;
    input [7:0] Number;
    output [7:0] Out_num;
    reg [7:0] New_Num;

     
    always @(SHIFT or Number or Out_num) 
    begin
         #1                              // for shifting delay is 1 time unit 
           case (SHIFT)                               // we can shift maximum 8 other then then always smae value 
          4'd0:
            New_Num = Number;
          4'd1:
            New_Num = { Number[7],Number[7:1] };
          4'd2:
            New_Num = { Number[7],Number[7],Number[7:2] };
          4'd3: 
            New_Num = { Number[7],Number[7],Number[7],Number[7:3] };
          4'd4:
            New_Num = { Number[7],Number[7],Number[7],Number[7],Number[7:4] };
          4'd5:
            New_Num = { Number[7],Number[7],Number[7],Number[7],Number[7],Number[7:5] };
          4'd6:
            New_Num = { Number[7],Number[7],Number[7],Number[7],Number[7],Number[7],Number[7:6] };
          4'd7:
            New_Num = { Number[7],Number[7],Number[7],Number[7],Number[7],Number[7],Number[7],Number[7:7] };

        default: New_Num={ Number[7],Number[7],Number[7],Number[7],Number[7],Number[7],Number[7],Number[7:7] };
          endcase
          
          
          
      end 
        assign Out_num = New_Num;
endmodule


module  Rotate_right(SHIFT,Number,Out_num);
    input [3:0] SHIFT;
    input [7:0] Number;
    output [7:0] Out_num; 
    reg [7:0] New_Num;

    always @(SHIFT or Number or Out_num) 
    begin      
        #1                                       // for shifting delay is 1 time unit                     
        case (SHIFT) 
          3'd0:
            New_Num = Number;
          3'd1:
            New_Num = { Number[0],Number[7:1]};
          3'd2:
            New_Num = { Number[1],Number[0],Number[7:2]};
          3'd3:
            New_Num = { Number[2],Number[1],Number[0],Number[7:3]};
          3'd4:
            New_Num = { Number[3],Number[2],Number[1],Number[0],Number[7:4]};
          3'd5:
            New_Num = { Number[4],Number[3],Number[2],Number[1],Number[0],Number[7:5]};
          3'd6:
            New_Num = { Number[5],Number[4],Number[3],Number[2],Number[1],Number[0],Number[7:6]};
          3'd7:
            New_Num = { Number[6],Number[5],Number[4],Number[3],Number[2],Number[1],Number[0],Number[7:7]};
          default: New_Num=8'b0;
          
        endcase
          
          
      end 
      assign Out_num = New_Num;
    

endmodule

// module for testing logical left
/* module ls_tb;
    reg clk;
    
    reg [7:0] shift;
    reg [7:0] in;
    wire [7:0] out;

    Rotate_right mult(shift, in, out);

    always begin
        #1 clk = ~clk;  // Toggle the clock every 5 time units
    end

    initial begin
        clk = 0;  
        
        // Apply inputs and display output
        
        shift = 2;
        in = 14;
        #10;

        $finish;  // End the simulation
    end

    // Display the output
    always @(out)
        $display("Output: %d", out);

endmodule */

module Shift(SHIFT,Number,Out_num,Chocie);
    input [7:0] Number;
    input [3:0] SHIFT;
    input Chocie;
    output [7:0] Out_num; 
    reg [7:0] New_Num;

    always @(SHIFT or Number or Out_num) 
    begin
        case(Chocie)
        1'b0 : //left shift
            begin
                #1                                                 // for shifting delay is 1 time unit 
                case (SHIFT)                                               // we can shift maximum 8 other then then always smae value 
                    4'd0:
                        New_Num = Number;
                    4'd1:
                        New_Num = { Number[6:0],1'b0 };
                    4'd2:
                        New_Num = { Number[5:0],2'b0 };
                    4'd3:
                        New_Num = { Number[4:0],3'b0 };
                    4'd4:
                        New_Num = { Number[3:0],4'b0 };
                    4'd5:
                        New_Num = { Number[2:0],5'b0 };
                    4'd6:
                        New_Num = { Number[1:0],6'b0 };
                    4'd7:
                        New_Num = { Number[0:0],7'b0 };
                    
                        
                    default: New_Num=8'b0;
                endcase 
                
            end
        
        1'b1 :
            begin
                #1                                       // for shifting delay is 1 time unit                     
                case (SHIFT)                          // we can shift maximum 8 other then then always smae value 
                    4'd0:
                        New_Num = Number;                    
                    4'd1:
                        New_Num = { 1'b0,Number[7:1] };
                    4'd2:
                        New_Num = { 2'b0,Number[7:2] };
                    4'd3:
                        New_Num = { 3'b0,Number[7:3] };
                    4'd4:
                        New_Num = { 4'b0,Number[7:4] };
                    4'd5:
                        New_Num = { 5'b0,Number[7:5] };
                    4'd6:
                        New_Num = { 6'b0,Number[7:6] };
                    4'd7:
                        New_Num = { 7'b0,Number[7:7] };
                    default: New_Num=8'b0;
                endcase
                
            end
        endcase
    end
    assign Out_num = New_Num;


endmodule

/* module tb_shift;
    reg [7:0] in;
    reg [3:0] shift;
    reg chocie;
    reg clk;
    wire [7:0] out;
    Shift mult(shift, in, out, chocie);

    always begin
        #1 clk = ~clk;  // Toggle the clock every 5 time units
    end

    initial begin
        clk = 0;  
        
        // Apply inputs and display output
        chocie = 1;
        shift = 2;
        in = 14;
        #10;

        chocie = 1;
        shift = 2;
        in = 14;
        #10;

        $finish;  // End the simulation
    end

    // Display the output
    always @(out)
        $display("Output: %d", out);

endmodule
 */



/* module Logic_right(SHIFT,Number,New_Num);
    input [3:0] SHIFT;
    input [7:0] Number;
    output reg [7:0] New_Num;

     
    
    always @(SHIFT or Number or New_Num) 
    begin
       #1                                             // for shifting delay is 1 time unit 
        case (SHIFT)                          // we can shift maximum 8 other then then always smae value 
          4'd0:
            New_Num = Number;                    
          4'd1:
            New_Num = { 1'b0,Number[7:1] };
          4'd2:
            New_Num = { 2'b0,Number[7:2] };
          4'd3:
            New_Num = { 3'b0,Number[7:3] };
          4'd4:
            New_Num = { 4'b0,Number[7:4] };
          4'd5:
            New_Num = { 5'b0,Number[7:5] };
          4'd6:
            New_Num = { 6'b0,Number[7:6] };
          4'd7:
            New_Num = { 7'b0,Number[7:7] };
          
            
            default: New_Num=8'b0;
          endcase
      end 
endmodule



module Logic_left(SHIFT,Number,New_Num);
    input [3:0] SHIFT;
    input [7:0] Number;
    output reg [7:0] New_Num;
    
    always @(SHIFT or Number or New_Num) 
    begin
        #1                                                 // for shifting delay is 1 time unit 
            case (SHIFT)                                               // we can shift maximum 8 other then then always smae value 
                4'd0:
                    New_Num = Number;
                4'd1:
                    New_Num = { Number[6:0],1'b0 };
                4'd2:
                    New_Num = { Number[5:0],2'b0 };
                4'd3:
                    New_Num = { Number[4:0],3'b0 };
                4'd4:
                    New_Num = { Number[3:0],4'b0 };
                4'd5:
                    New_Num = { Number[2:0],5'b0 };
                4'd6:
                    New_Num = { Number[1:0],6'b0 };
                4'd7:
                    New_Num = { Number[0:0],7'b0 };
                
                    
                default: New_Num=8'b0;
             endcase 
      end
endmodule */