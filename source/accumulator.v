`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2023 07:31:19 AM
// Design Name: 
// Module Name: accumulator
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
module accumulator #
(
    parameter DATA_WIDTH = 32,
    parameter N_CHANNEL = 32,
    parameter CNT_WIDTH = $clog2(32)
)(
    input i_clk,
    input i_rst_n,
    input [31:0] i_param_cfg_weight,
    input [DATA_WIDTH-1:0] data_in,
    input stop_accum, rec_accum,
    output [DATA_WIDTH-1:0] data_out,
    output [6:0] current_no_channel
);
    
    reg [DATA_WIDTH-1:0] tmp_dat;
    reg [DATA_WIDTH-1:0] reg_data_o;
    reg [6:0] cnt_accum;

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            tmp_dat <= 0;
            cnt_accum <= 0;
        end
        else begin
            if(!stop_accum && rec_accum) begin  
                tmp_dat <= tmp_dat + data_in;
                cnt_accum <= cnt_accum + 1;
            end
            else if(stop_accum) begin
                cnt_accum <= 0;
                tmp_dat <= 0;
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_data_o <= 0;
        end
        else begin
            if(stop_accum) begin
                reg_data_o <= tmp_dat;
//                tmp_dat <= 0;
            end
        end
    end

    assign data_out = reg_data_o;
    assign current_no_channel = cnt_accum;
endmodule
