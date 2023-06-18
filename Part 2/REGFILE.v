`timescale 1ns/100ps
module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET,BUSYWAIT);

    // Defining Ports 
    input [7:0] IN; // The data input port
    input [2:0] INADDRESS; //The address of the register to write to
    
    output [7:0] OUT1, OUT2; // The data output ports
    input [2:0] OUT1ADDRESS, OUT2ADDRESS; // The address of the registers to read from
    //reg [7:0] OUT1, OUT2;



    input WRITE; // The write enable signal
    input CLK; // The clock signal
    input RESET; // The reset signal
    input BUSYWAIT;

    reg [7:0] registers[7:0]; // The array of 8-bit registers



    // Asynchronously assigning OUT1 and OUT2
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];
    integer i;

    // Positive Edge Triggered
    // All operations happenat the positive edge of the clock
    always @(posedge CLK)
    begin

        // When RESET signal is HIGH , all registers should be cleared (written zero)
        if (RESET) //RESET Block 
            begin
                
                for(i = 0; i < 8; i++) // For-loop to iterate through the array of registers
                begin
                    #1; // Writing requires a delay of 1 time unit
                    registers[i] = 0;
                end
            end
        

        // When WRITE signal is HIGH, data in input port IN should be written to registers[INADDRESS]
        else if (WRITE && !BUSYWAIT ) //WRITE Block
            begin
                //$display("Write");
                #1; // Writing requires a delay of 1 time unit
                registers[INADDRESS] = IN;
            end        
    end
   

endmodule