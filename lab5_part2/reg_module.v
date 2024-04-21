module reg_file_tb;

    reg [7:0] in;
    reg [2:0] inaddress, out1address, out2address;
    reg write;
    reg clk;
    reg reset;

    wire [7:0] out1, out2;

    reg_file test(in, out1, out2, inaddress, out1address, out2address, write, clk, reset);
    

    //Initial block to initialize control signals
	initial
	begin
		clk = 0;
		reset = 0;
		write = 1;
	end
	
	
	//Performing a set of operations on the register file
	initial
	begin
        //Handling wavedata dumpfile and monitor outputs
        $dumpfile("wavedata.vcd");
		$dumpvars(0, test);
		$monitor("Time = %g, OUT1 = %d, OUT2 = %d", $time, out1, out2);
        
		inaddress = 0;
        #1
        in = 5;

        
        #4
        out1address = 0;
        out2address = 1;
        		
		
		
		#4
        write = 0;
		inaddress = 1;
        in = 10;

        #4
        out1address = 1;
        	
        #10
        $finish;		
	end
	
	
	// This always block is executed every clock cycle
	always #1 clk = !clk;		

    
	
endmodule


module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS, WRITE, CLK, RESET);

    // Defining Ports 
    input [7:0] IN; // The data input port
    input [2:0] INADDRESS; //The address of the register to write to
    
    output [7:0] OUT1, OUT2; // The data output ports
    input [2:0] OUT1ADDRESS, OUT2ADDRESS; // The address of the registers to read from
    //reg [7:0] OUT1, OUT2;



    input WRITE; // The write enable signal
    input CLK; // The clock signal
    input RESET; // The reset signal

    reg [7:0] registers[7:0]; // The array of 8-bit registers



    // Asynchronously assigning OUT1 and OUT2
    assign #2 OUT1 = registers[OUT1ADDRESS];
    assign #2 OUT2 = registers[OUT2ADDRESS];

    // Positive Edge Triggered
    // All operations happenat the positive edge of the clock
    always @(posedge CLK)
    begin

        // When RESET signal is HIGH , all registers should be cleared (written zero)
        if (RESET) //RESET Block 
            begin
                for(integer i = 0; i < 8; i++) // For-loop to iterate through the array of registers
                begin
                    //$display("Clock");
                    #1; // Writing requires a delay of 1 time unit
                    registers[i] = 0;
                end
            end
        

        // When WRITE signal is HIGH, data in input port IN should be written to registers[INADDRESS]
        else if (WRITE) //WRITE Block
            begin
                //$display("Write");
                #1; // Writing requires a delay of 1 time unit
                registers[INADDRESS] = IN;
            end        
    end
    /*
    always @*
    begin
        
            // Reading requires a delay of 2 time units
            // Read the value of the register specified by the OUT1ADDRESS signal
            #2;
            OUT1 = registers[OUT1ADDRESS];

            // Read the value of the register specified by the OUT2ADDRESS signal
            #2;
            OUT2 = registers[OUT2ADDRESS];
        
    end
    */

endmodule