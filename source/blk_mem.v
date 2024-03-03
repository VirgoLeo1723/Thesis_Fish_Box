`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2023 02:05:44 PM
// Design Name: 
// Module Name: blk_mem
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


module blk_mem 
#(
    parameter BIT_WIDTH = 16,
    parameter ADDR_WIDTH = 4
)
(
    input clk,
    input rst_n, 
    input wr_en,
    input rd_en,
    input [ADDR_WIDTH-1:0]  addr_in,
    input [ADDR_WIDTH-1:0]  addr_out,
    input [BIT_WIDTH-1:0]   wr_data,
    output [BIT_WIDTH-1:0]  rd_data
    
);

reg [BIT_WIDTH-1:0] mem [0: (1<<ADDR_WIDTH)];
reg [BIT_WIDTH-1:0] reg_rdata;

assign rd_data = reg_rdata;

//integer loop_var;
reg [ADDR_WIDTH:0] loop_var;
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        for (loop_var=0; loop_var<(1<<ADDR_WIDTH); loop_var=loop_var+1)
        begin
            mem[loop_var] <= 0;
        end
    end
    else begin
        if(wr_en) begin
            mem[addr_in] <= wr_data;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        reg_rdata <= 0;
    end
    else begin
    if (rd_en)
        reg_rdata <= mem[addr_out];
    end
end
endmodule
