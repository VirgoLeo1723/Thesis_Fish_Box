`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 04:53:12 PM
// Design Name: 
// Module Name: bram_reader_tb
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


module bram_reader_tb();
    
    reg clk;
    reg rst;
    wire [7:0] data_out;
    reg en;
    wire valid;
    
    // DUT instance  
    bram_read_test_wrapper inst_0(
        .clk(clk),
        .data_out(data_out),
        .en(en),
        .rst(rst)
//        .valid(valid)
    );
    
    initial 
    begin
        clk = 0;
        repeat (100) #1 clk = ~clk;
    end
    
    initial
    begin
        rst = 1;
        #1 rst = 0;
        #1 rst = 1;
    end
    
    initial 
    begin
        en = 1'b1;
//        wait(rst == 0) en = 1'b1;
    end
    
    initial
    begin
//        $monitor("data from bram: %h", data_out);
    end
    
    initial 
    begin
        wait(valid == 1'b1) $display(data_out);
    end
endmodule
