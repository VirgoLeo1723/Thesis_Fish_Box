`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2023 07:33:51 AM
// Design Name: 
// Module Name: sipo
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


module sipo #(
        SIZE_OF_INPUT = 64,
        SIZE_OF_BUFFER = 8
    )( 
        input                               clk_i, 
        input                               rst_i,
        input                               rd_en_i, 
        input                               wr_en_i, 
        input       [SIZE_OF_INPUT-1:0]     data_i, 
        output reg  [SIZE_OF_INPUT*SIZE_OF_BUFFER-1:0]     data_o, 
        output                              is_empty_o, 
        output                              is_full_o
    ); 
    reg [SIZE_OF_INPUT*SIZE_OF_BUFFER-1:0] internal_memory; 
    reg [3:0]  rd_ptr; 
    reg [3:0]  wr_ptr;
    
    assign is_empty_o = (wr_ptr==0); 
    assign is_full_o  = (wr_ptr==SIZE_OF_BUFFER); 

    always @ (posedge clk_i, negedge rst_i) 
    begin 
        if (!rst_i) 
        begin 
            wr_ptr          <= 0;
            internal_memory <= 0;
            data_o          <= 0;
        end 
        else
        begin 
            if ( wr_en_i )
            begin
                if (wr_ptr < SIZE_OF_BUFFER) wr_ptr <= wr_ptr + 1;
                internal_memory <= {data_i, internal_memory[SIZE_OF_INPUT+:SIZE_OF_INPUT*(SIZE_OF_BUFFER-1)]};
            end
            else if (rd_en_i)
            begin
                data_o <= internal_memory;
                wr_ptr <= 0;
            end
        end 
    end
    
endmodule
