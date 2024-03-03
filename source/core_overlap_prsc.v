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
    parameter N_PIX_IN                  = (SIZE_OF_EACH_CORE_INPUT)*SIZE_OF_EACH_KERNEL,                                            
    parameter STRB_WIDTH                = 2*PIX_WIDTH*N_PIX_IN/4 ,                                                      
    parameter N_PIX_OUT                 = (SIZE_OF_EACH_CORE_INPUT)*SIZE_OF_EACH_KERNEL - 
                                          (SIZE_OF_EACH_KERNEL-STRIDE)*(SIZE_OF_EACH_CORE_INPUT-1) ,  
    parameter NON_OVERLAPPED_CONST      = SIZE_OF_EACH_CORE_INPUT * STRIDE,
    parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_EACH_CORE_INPUT-1) + SIZE_OF_EACH_KERNEL,
    parameter SIZE_OF_PRSC_OUTPUT       = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST)
)(
    input                               clk_i             ,
    input                               rst_i             ,
    input                               en_i              ,
    input                               valid_i           ,
    input [N_PIX_OUT*2*PIX_WIDTH-1:0]   core_data_0_i     ,
    input [N_PIX_OUT*2*PIX_WIDTH-1:0]   core_data_1_i     ,
    input [N_PIX_OUT*2*PIX_WIDTH-1:0]   core_data_2_i     ,
    input [N_PIX_OUT*2*PIX_WIDTH-1:0]   core_data_3_i     ,
    output reg                          valid_o           ,
    output[2*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT-1:0] overlapped_column_o
    );
    
    integer column_loop_var;
    reg [2*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT-1:0]                     overlapped_column_0_2;
    reg [2*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT*SIZE_OF_PRSC_INPUT-1:0]  overlapped_column_1_3;
    reg finish_received_input;
    localparam OVERLAPPED_CONST = SIZE_OF_PRSC_INPUT - NON_OVERLAPPED_CONST;
    
    assign overlapped_column_o = overlapped_column_0_2;
    
    integer wr_ptr;
    integer rd_ptr;
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i || column_loop_var == SIZE_OF_PRSC_OUTPUT)
        begin
            column_loop_var <= 0;
            valid_o         <= 0;
            finish_received_input <= 1'b0;
        end
        else
        begin
            if ( (en_i & valid_i) | finish_received_input)
            begin
                column_loop_var <= column_loop_var + 1;
                valid_o         <= 1'b1;
                if (column_loop_var == SIZE_OF_PRSC_INPUT-1) finish_received_input <= 1'b1;
            end 
            else 
            begin
                valid_o         <= 1'b0;
                finish_received_input <= 1'b0;
                column_loop_var <= column_loop_var; 
            end
        end
    end
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i )
        begin
            overlapped_column_0_2 <= 0;
            overlapped_column_1_3 <= 0; 
            wr_ptr <= 0;
            rd_ptr <= 0;
        end 
        else
        begin
            if ((en_i && valid_i)|finish_received_input)
            begin
                if (column_loop_var < SIZE_OF_PRSC_OUTPUT)
                begin
                    wr_ptr  <= wr_ptr + 1;
                    overlapped_column_1_3[wr_ptr*2*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT+:2*PIX_WIDTH*SIZE_OF_PRSC_OUTPUT] 
                            <= {core_data_3_i[OVERLAPPED_CONST*2*PIX_WIDTH+:NON_OVERLAPPED_CONST*2*PIX_WIDTH],
                                core_data_3_i[0+:OVERLAPPED_CONST*2*PIX_WIDTH] + core_data_1_i[2*PIX_WIDTH*NON_OVERLAPPED_CONST+:2*PIX_WIDTH*OVERLAPPED_CONST],
                                core_data_1_i[0+:NON_OVERLAPPED_CONST*2*PIX_WIDTH]
                                };
                    if (column_loop_var < NON_OVERLAPPED_CONST)
                    begin
                        overlapped_column_0_2
                                <= {core_data_2_i[OVERLAPPED_CONST*2*PIX_WIDTH+:NON_OVERLAPPED_CONST*2*PIX_WIDTH],
                                    core_data_2_i[0+:OVERLAPPED_CONST*2*PIX_WIDTH] + core_data_0_i[2*PIX_WIDTH*NON_OVERLAPPED_CONST+:2*PIX_WIDTH*OVERLAPPED_CONST],
                                    core_data_0_i[0+:NON_OVERLAPPED_CONST*2*PIX_WIDTH]
                                    };
                    end
                    else if (column_loop_var >= NON_OVERLAPPED_CONST && column_loop_var < SIZE_OF_PRSC_INPUT)
                    begin
                        rd_ptr <= rd_ptr + 1;
                        overlapped_column_0_2
                                <= {core_data_2_i[OVERLAPPED_CONST*2*PIX_WIDTH+:NON_OVERLAPPED_CONST*2*PIX_WIDTH],
                                    core_data_2_i[0+:OVERLAPPED_CONST*2*PIX_WIDTH] + core_data_0_i[2*PIX_WIDTH*NON_OVERLAPPED_CONST+:2*PIX_WIDTH*OVERLAPPED_CONST],
                                    core_data_0_i[0+:NON_OVERLAPPED_CONST*2*PIX_WIDTH]
                                    } + overlapped_column_1_3[rd_ptr*SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH+:SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH];
                    end
                    else
                    begin
                        rd_ptr <= rd_ptr + 1;
                        overlapped_column_0_2
                                <= overlapped_column_1_3[rd_ptr*SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH+:SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH];
                    end
                end
                else 
                begin
                     wr_ptr <= 0;
                     rd_ptr <= 0; 
                end 
            end
            if (column_loop_var == SIZE_OF_PRSC_OUTPUT)
            begin
                 wr_ptr <= 0;
                 rd_ptr <= 0; 
            end
        end
    end
endmodule
