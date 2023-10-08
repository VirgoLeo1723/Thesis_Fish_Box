`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 12:19:33 PM
// Design Name: 
// Module Name: shift_register
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


module shift_register 
#(
    parameter BIT_WIDTH = 8,
    parameter N_COL_FEATURE = 8,
    parameter N_COL_KERNEL = 5,
    parameter NUM_STRIDE = 2,
    parameter N_PIX_IN = N_COL_FEATURE*N_COL_KERNEL, 
    parameter N_PIX_OUT = N_COL_FEATURE*N_COL_KERNEL - (N_COL_KERNEL-NUM_STRIDE)*(N_COL_FEATURE-1),
    parameter STRB_WIDTH = 2*BIT_WIDTH*N_PIX_IN/4
)
(
    input clk,
    input rst_n,
    input en_shift,
    input [STRB_WIDTH-1:0] data_strobe,
    input [2*BIT_WIDTH*N_PIX_IN-1:0] data_in,
    output [2*BIT_WIDTH*N_PIX_OUT-1:0] data_out,
    output accumn_fin
);
    localparam BIT_LEFT = 2*BIT_WIDTH*N_PIX_OUT - 2*BIT_WIDTH*N_COL_KERNEL;

    reg [2*BIT_WIDTH*N_PIX_OUT-1:0] tmp_data_out;
    reg [2*BIT_WIDTH*N_PIX_OUT-1:0] data_accumm;
    reg [2*BIT_WIDTH*N_COL_KERNEL-1:0] sub_data;


    integer byte_id; //index

    assign data_out = (accumn_fin) ? data_accumm : 0;

    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            sub_data <= 0;
            tmp_data_out <= 0;
        end
        else begin
            if(en_shift) begin
                for(byte_id = 0; byte_id < N_COL_FEATURE; byte_id = byte_id + 1) begin
                    if(data_strobe[byte_id] == 1) begin
                        sub_data <= data_in[(byte_id*2*BIT_WIDTH*N_COL_KERNEL)+:(2*BIT_WIDTH*N_COL_KERNEL)];
                        tmp_data_out <= {sub_data, {BIT_LEFT{1'b0}}} >> byte_id*2*BIT_WIDTH*NUM_STRIDE;
                    end
                end
            end 
        end
    end
    
    integer cnt_accumm;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_accumm <= 0;
            cnt_accumm <= 0;
        end
        else begin
            if(en_shift) begin
                for(byte_id = 0; byte_id < N_COL_FEATURE ; byte_id = byte_id + 1) begin
                    if(data_strobe[byte_id] == 1) begin
                        data_accumm <= data_accumm + tmp_data_out;
                        cnt_accumm <= cnt_accumm + 1;
                    end
                end
            end 
        end
    end

    assign accumn_fin = (cnt_accumm == N_COL_FEATURE-1) ? 1 : 0;
endmodule
