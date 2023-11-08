`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2023 04:08:16 PM
// Design Name: 
// Module Name: core_overlap_prsc
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


module core_overlap_prsc#(
    parameter SIZE_OF_EACH_CORE_INPUT   = 2,
    parameter SIZE_OF_EACH_KERNEL       = 3,
    parameter STRIDE                    = 1, 
    parameter PIX_WIDTH                 = 8,     
    parameter NON_OVERLAPPED_CONST      = SIZE_OF_EACH_CORE_INPUT * STRIDE,
    parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_EACH_CORE_INPUT-1) + SIZE_OF_EACH_KERNEL,
    parameter SIZE_OF_PRSC_OUTPUT       = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST)
)(
    input                                     clk_i             ,
    input                                     rst_i             ,
    input                                     en_i              ,
    input                                     valid_i           ,
    input [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_0_i     ,
    input [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_1_i     ,
    input [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_2_i     ,
    input [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_3_i     ,
    output                                    valid_o           ,
    output[PIX_WIDTH*SIZE_OF_PRSC_OUTPUT-1:0] overlapped_column_o
    );
    
    reg [PIX_WIDTH*SIZE_OF_PRSC_OUTPUT-1:0]                     overlapped_column_0_2;
    reg [PIX_WIDTH*SIZE_OF_PRSC_OUTPUT*SIZE_OF_PRSC_INPUT-1:0]  overlapped_column_1_3;
    localparam OVERLAPPED_CONST = SIZE_OF_PRSC_INPUT - NON_OVERLAPPED_CONST;
    
    assign overlapped_column_o = overlapped_column_0_2;
    assign valid_o = column_loop_var == SIZE_OF_PRSC_OUTPUT;
    
    integer column_loop_var;
    integer wr_ptr;
    integer rd_ptr;
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i || column_loop_var == SIZE_OF_PRSC_OUTPUT)
        begin
            column_loop_var <= 0;
        end
        else
        begin
            if (en_i && valid_i)
            begin
                column_loop_var <= column_loop_var + 1;
            end 
            else 
            begin
                column_loop_var <= column_loop_var; 
            end
        end
    end
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i || column_loop_var == SIZE_OF_PRSC_OUTPUT)
        begin
            overlapped_column_0_2 <= 0;
            overlapped_column_1_3 <= 0; 
            wr_ptr <= 0;
            rd_ptr <= 0;
        end 
        else
        begin
            if (en_i && valid_i)
            begin
                wr_ptr  <= wr_ptr + 1;
                overlapped_column_1_3[wr_ptr*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT+:PIX_WIDTH*SIZE_OF_PRSC_OUTPUT] 
                        <= {core_data_3_i[OVERLAPPED_CONST*PIX_WIDTH+:NON_OVERLAPPED_CONST*PIX_WIDTH],
                            core_data_3_i[0+:OVERLAPPED_CONST*PIX_WIDTH] + core_data_1_i[PIX_WIDTH*NON_OVERLAPPED_CONST+:PIX_WIDTH*OVERLAPPED_CONST],
                            core_data_1_i[0+:NON_OVERLAPPED_CONST*PIX_WIDTH]
                            };
                if (column_loop_var < OVERLAPPED_CONST)
                begin
                    overlapped_column_0_2
                            <= {core_data_2_i[OVERLAPPED_CONST*PIX_WIDTH+:NON_OVERLAPPED_CONST*PIX_WIDTH],
                                core_data_2_i[0+:OVERLAPPED_CONST*PIX_WIDTH] + core_data_0_i[PIX_WIDTH*NON_OVERLAPPED_CONST+:PIX_WIDTH*OVERLAPPED_CONST],
                                core_data_0_i[0+:NON_OVERLAPPED_CONST*PIX_WIDTH]
                                };
                end
                else if (column_loop_var >= OVERLAPPED_CONST && column_loop_var < SIZE_OF_PRSC_OUTPUT)
                begin
                    rd_ptr <= rd_ptr + 1;
                    overlapped_column_0_2
                            <= {core_data_2_i[OVERLAPPED_CONST*PIX_WIDTH+:NON_OVERLAPPED_CONST*PIX_WIDTH],
                                core_data_2_i[0+:OVERLAPPED_CONST*PIX_WIDTH] + core_data_0_i[PIX_WIDTH*NON_OVERLAPPED_CONST+:PIX_WIDTH*OVERLAPPED_CONST],
                                core_data_0_i[0+:NON_OVERLAPPED_CONST*PIX_WIDTH]
                                } + overlapped_column_1_3[rd_ptr*SIZE_OF_PRSC_OUTPUT*PIX_WIDTH+:SIZE_OF_PRSC_OUTPUT*PIX_WIDTH];
                end
                else
                begin
                    overlapped_column_0_2
                            <= {core_data_3_i[OVERLAPPED_CONST*PIX_WIDTH+:NON_OVERLAPPED_CONST*PIX_WIDTH],
                                core_data_3_i[0+:OVERLAPPED_CONST*PIX_WIDTH] + core_data_1_i[PIX_WIDTH*NON_OVERLAPPED_CONST+:PIX_WIDTH*OVERLAPPED_CONST],
                                core_data_1_i[0+:NON_OVERLAPPED_CONST*PIX_WIDTH]
                               };
                end
            end
        end
    end
endmodule
