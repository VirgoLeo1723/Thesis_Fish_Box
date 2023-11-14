`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 06:16:24 PM
// Design Name: 
// Module Name: sp_sram
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


module sp_sram 
# (
    parameter WIDTH  = 10,
    parameter DEPTH  = 128,
    parameter ADDRB  = $clog2(DEPTH)
)
(
    input                   i_clk,
    input                   ena,
    input                   wea,
    input                   rea,
    input       [ADDRB-1:0] addr_i,
    input       [ADDRB-1:0] addr_o,
    input       [WIDTH-1:0] dina_0,
    input       [WIDTH-1:0] dina_1,
    input       [WIDTH-1:0] dina_2,
    input       [WIDTH-1:0] dina_3,
    output reg  [WIDTH-1:0] douta
);


//===============================================================================
// REGISTER/WIRE
//===============================================================================
reg     [WIDTH-1:0] mem [DEPTH-1:0];

//===============================================================================
// MODULE BODY
//===============================================================================
always @ (posedge i_clk)
begin
    if (ena & rea) begin
        if (addr_o < DEPTH) begin
            douta <= mem[addr_o];
        end
    end
end

always @ (posedge i_clk)
begin
    if (ena & wea) begin
    
        if (addr_i < DEPTH) begin
            mem[addr_i]  <= dina_0;
            mem[addr_i+1]  <= dina_1;
            mem[addr_i+2]  <= dina_2;
            mem[addr_i+3]  <= dina_3;
        end
    end
end

endmodule