`timescale 1ns/100ps

module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);
    // Defining Ports 
    input [7:0] IN;            // Data input port
    input [2:0] INADDRESS;     // Address of the register to write to
    output [7:0] OUT1, OUT2;   // Data output ports
    input [2:0] OUT1ADDRESS, OUT2ADDRESS;   // Address of the registers to read from
    input WRITE;               // Write enable signal
    input CLK;                 // Clock signal
    input RESET;               // Reset signal
    
    // Array of 8 8-bit registers
    reg [7:0] REGISTER [7:0];
    
    // Iterator variable used in for loop
    integer i;
    
    // Reads data from registers asynchronously
    // Contains a delay of 2 time units
    assign #2 OUT1 = REGISTER[OUT1ADDRESS];  // Assigns the value of the relevant register address to the OUT1 terminal
    assign #2 OUT2 = REGISTER[OUT2ADDRESS];  // Assigns the value of the relevant register address to the OUT2 terminal
    
    // Synchronous register operations (Write and Reset)
    // Both operations contain a delay of 1 time unit each
    always @(posedge CLK)
    begin
        if (RESET == 1'b1)      // If the RESET signal is HIGH, registers must be cleared
        begin
            #1;
            for (i = 0; i < 8; i = i + 1)   // For loop to iterate over all 8 register addresses after a 1 time unit delay
            begin
                REGISTER[i] <= 8'b00000000;  // Setting each element of the REGISTER array to 0
            end
        end
        else if (WRITE == 1'b1) // If the RESET signal is LOW, write to the registers if the WRITE signal is HIGH
        begin
            #1;
            REGISTER[INADDRESS] <= IN;   // Assigns the input value IN to the relevant register address after a delay of 1
        end
    end
    
    // Logging register file contents
    initial
    begin
        #5;
        $display("\t\t\t\tTIME \t R0 \t\t R1 \t\t R2 \t\t R3 \t\t R4 \t\t R5 \t\t R6 \t\t R7");
        $monitor($time, "\t%d \t\t %d \t\t %d \t\t %d \t\t %d \t\t %d \t\t %d \t\t %d", REGISTER[0], REGISTER[1], REGISTER[2], REGISTER[3], REGISTER[4], REGISTER[5], REGISTER[6], REGISTER[7]);
    end
endmodule
