`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 10:27:28 AM
// Design Name: 
// Module Name: edge_detector
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
module edge_detector(
    input i_clk,
    input i_rst_n,
    input sig_in,
    output sig_out
);
    reg sig_dlay;
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            sig_dlay <= 0;
        end
        else begin
            sig_dlay <= sig_in;
        end
    end
    assign sig_out = sig_in & ~sig_dlay;

endmodule

