`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 08:27:31 PM
// Design Name: 
// Module Name: bram_writer
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

`include "gan_common_define.vh"

module bram_writer #(
        parameter ADDRESS_WIDTH  = 13,
        parameter REG_WIDTH      = 32,
        parameter DATA_IN_WIDTH  = 512,
        parameter DATA_OUT_WIDTH = 32 
    )(
        input                               clk_i               ,      
        input                               rst_i               ,
        input                               en_i                ,
        input                               waiting_i           ,      
        input                               valid_i             , 
        input                               ready_i             ,     
        input      [DATA_IN_WIDTH-1:0 ]     data_i              ,     
        input      [REG_WIDTH-1:0     ]     i_param_cfg_feature ,
        input      [REG_WIDTH-1:0     ]     i_param_cfg_weight  , 
        input      [31:0]                   i_param_cfg_output  ,      
        output reg [DATA_OUT_WIDTH-1:0]     data_o              ,
        output reg                          finish_o            ,      
        output reg [ADDRESS_WIDTH-1:0 ]     bram_addr           ,      
        output                              bram_en             ,      
        output                              bram_we     
    );

    reg [DATA_IN_WIDTH-1:0] result_data;
    reg                     save_enable;
    integer each_data_counter;
    integer each_transfer_counter;
    
    assign bram_en = each_data_counter>0 & each_data_counter< `DATA_TILLING_RESULT_SIZE /DATA_OUT_WIDTH;
    assign bram_we = 1'b1;
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            bram_addr               <= `RESULT_BASED_ADDRESS -1 ;
            result_data             <= {DATA_IN_WIDTH{1'b0}};
            data_o                  <= {DATA_OUT_WIDTH{1'b0}};
            finish_o                <= 1'b0;
            save_enable             <= 1'b0;
            each_data_counter       <= 0;
            each_transfer_counter   <= 0;
        end
        else
        begin
            finish_o                <= 1'b0;
            if (!waiting_i && ready_i && each_transfer_counter == 0 && each_data_counter == 0)
            begin
                finish_o              <= 1'b1;
                each_transfer_counter <= 4;   
                save_enable           <= 1'b1;  
            end
            else
            begin
                if (valid_i && each_transfer_counter > 0)
                begin
                    each_transfer_counter   <= each_transfer_counter - 1    ;
                    each_data_counter       <= `DATA_TILLING_RESULT_SIZE/DATA_OUT_WIDTH ;
                    result_data             <= data_i;
                    save_enable <= 1'b0;
                end
                else if (each_data_counter > 0)
                begin
                    each_data_counter       <= each_data_counter - 1        ;
                    bram_addr               <= bram_addr + 1                ; 
                    {result_data, data_o}   <= {{DATA_OUT_WIDTH{1'b0}},result_data};
                end
                else if (!waiting_i&&!save_enable && ready_i)
                begin 
                    finish_o                <= 1'b1; 
                    save_enable             <= 1'b1;
                end
            end
        end
    end
endmodule
