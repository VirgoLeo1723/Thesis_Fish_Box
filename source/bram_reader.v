`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 03:46:09 PM
// Design Name: 
// Module Name: bram_reader
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
module bram_reader #(
    ADDRESS_WIDTH  = 13,
    DATA_IN_WIDTH  = 32,
    DATA_OUT_WIDTH = 8
)(
    input                               clk_i       ,
    input                               rst_i       ,
    input                               en_i        ,
    input       [DATA_IN_WIDTH-1:0]     data_i      ,
    output reg  [DATA_OUT_WIDTH-1:0]    data_o      ,
    output reg                          valid_o     ,
    output reg  [ADDRESS_WIDTH-1:0]     bram_addr   ,
    output reg                          bram_en     ,
    output      [3:0]                   bram_we          
);
    // Code your design here
    reg [31:0]  bram_data ;
    reg [3:0]   masking_counter;
    
    assign bram_we = 4'd0;
    
 	always @(posedge clk_i, negedge rst_i)
  	begin
		if (!rst_i)
      	begin
            bram_en         <= 1'b0;
            bram_data       <= {DATA_IN_WIDTH{1'b0}};
            bram_addr       <= {DATA_OUT_WIDTH{1'b0}};
            data_o          <= {DATA_OUT_WIDTH{1'b0}};
            masking_counter <= 4'd0;
        end
        else
        begin
            if (en_i)
            begin
                bram_en     <= 1'b1;
                if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-1)
                begin
                    bram_data           <= data_i;
                    masking_counter     <= 4'd0;
                    valid_o             <= 1'b1;
                end
                else
                begin
                    if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-2) 
                    begin
                        bram_addr       <= bram_addr + 1;
                    end
                    else
                    begin
                        bram_addr       <= bram_addr;
                    end
                    {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};
                    masking_counter     <= masking_counter  + 1;
                    valid_o             <= 1'b0;
                end
            end
            else 
            begin
           	    bram_en     <= 1'b0;
           	    bram_addr   <= bram_addr;
           	    bram_data   <= bram_data;
            end
        end
    end
endmodule 
