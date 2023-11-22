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


module bram_writer #(
        parameter ADDRESS_WIDTH  = 13,
        parameter DATA_IN_WIDTH  = 512,
        parameter DATA_OUT_WIDTH = 32 
    )(
        input                               clk_i       ,      
        input                               rst_i       ,      
        input                               en_i        ,      
        input                               valid_i      ,      
        input      [DATA_IN_WIDTH-1:0 ]     data_i      ,      
        output reg [DATA_OUT_WIDTH-1:0]     data_o      ,
        output reg                          finish_o    ,      
        output reg [ADDRESS_WIDTH-1:0 ]     bram_addr   ,      
        output                              bram_en     ,      
        output                              bram_we       
    );

    localparam RESULT_BASED_ADDRESS = 5;
    assign bram_en = en_i;
    assign bram_we = 1'b1;

    reg [DATA_IN_WIDTH-1:0] result_data;
    reg                     save_enable;
    integer counter;

    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            bram_addr   <= RESULT_BASED_ADDRESS;
            data_o      <= {DATA_OUT_WIDTH{1'b0}};
            result_data <= {DATA_IN_WIDTH{1'b0}};
            finish_o    <= 1'b0;
            save_enable <= 1'b0;
        end
        else
        begin
//            if (en_i)
                        finish_o                <= 1'b0;

            begin
                if (valid_i)
                begin
                    save_enable <= en_i;
                    result_data <= data_i;
                    counter     <= DATA_IN_WIDTH/DATA_OUT_WIDTH;
                    data_o      <= {DATA_OUT_WIDTH{1'b0}};
                    finish_o    <= 1'b0;
                end   
                else
                begin
                    if (counter >= 0 && save_enable)
                    begin
                        bram_addr               <= bram_addr + 1; 
                        counter                 <= counter - 1;
                        {result_data, data_o}   <= {{DATA_OUT_WIDTH{1'b0}},result_data};
                    end
                    else
                    begin if (save_enable)
                        finish_o    <= 1'b1;
                        save_enable <= 1'b0;
                    end
                end
            end
//            else
//            begin
//                bram_addr   <= RESULT_BASED_ADDRESS;
//                data_o      <= {DATA_OUT_WIDTH{1'b0}};
//                result_data <= {DATA_IN_WIDTH{1'b0}};
//            end
        end
    end
endmodule