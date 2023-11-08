`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 12:56:44 PM
// Design Name: 
// Module Name: tilling_machine_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tilling_machine_tb();
    parameter SIZE_OF_INPUT = 16;
    parameter SIZE_OF_FEATURE = 4;

    reg                         clk_i;
    reg                         rst_i;
  	reg  [SIZE_OF_INPUT*4-1:0]  overlapped_column_core_i;
    reg  [3:0]                  valid_data_core_i;
    wire [SIZE_OF_INPUT/2*4-1:0]tilling_machine_o;
    wire                        tilling_machine_valid_o;

    tilling_machine #(
      .SIZE_OF_INPUT  (SIZE_OF_INPUT),
      .SIZE_OF_FEATURE(SIZE_OF_FEATURE)
    ) tilling_machine_inst (
        .clk_i                    (clk_i                   ),
        .rst_i                    (rst_i                   ),
        .overlapped_column_core_i (overlapped_column_core_i),
        .valid_data_core_i        (valid_data_core_i       ),
        .tilling_machine_o        (tilling_machine_o       ),
        .tilling_machine_valid_o  (tilling_machine_valid_o )
    );

    initial 
    begin
        clk_i = 0;
        repeat (10000) #1 clk_i = ~clk_i;     
    end

    initial
    begin
           rst_i = 0;
        #2 rst_i = 1;
    end

    initial
    begin
        valid_data_core_i = 0;
        repeat (1000)
        begin
            wait(rst_i===1'b1);
            @(posedge clk_i);
            valid_data_core_i = 4'd15;
            overlapped_column_core_i = {$random, $random, $random,$random,$random, $random, $random,$random,$random, $random, $random,$random,$random, $random, $random,$random};
        end
    end
	
  initial
    begin
      $dumpfile("tilling_machine.vcd");
      $dumpvars(0);
    end
endmodule 
