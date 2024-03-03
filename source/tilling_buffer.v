`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2023 07:35:19 AM
// Design Name: 
// Module Name: tilling_buffer
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
module tilling_buffer#(
        parameter SIZE_OF_INPUT  = 128,
        parameter SIZE_OF_BUFFER = 8 
    )(
	    input                               clk_i       ,
  	    input                               rst_i       ,
        input      [3:0]                    rd_en_i     ,
        input      [3:0]                    wr_en_i     ,
  		input      [SIZE_OF_INPUT-1:0]      wr_data_i   ,
        output     [SIZE_OF_INPUT*SIZE_OF_BUFFER-1:0]  rd_data_o   ,
        output     [3:0]                    is_empty    ,
        output     [3:0]                    is_full     
    );


    genvar buffer_index;
    generate
        for(buffer_index=0; buffer_index<4; buffer_index = buffer_index+1)
        begin
            case (buffer_index)
                0,1: 
                begin
                    sipo#(
                        .SIZE_OF_INPUT (SIZE_OF_INPUT/2),
                        .SIZE_OF_BUFFER(SIZE_OF_BUFFER/2)
                    ) buffer_inst (
                        .clk_i          (clk_i                                                              ),
                        .rst_i          (rst_i                                                              ),
                        .rd_en_i        (rd_en_i                                                            ),
                        .wr_en_i        (wr_en_i[buffer_index]                                              ),
                        .data_i      	(wr_data_i[0+:(SIZE_OF_INPUT/2)]                                    ),
                        .data_o      	(rd_data_o[buffer_index*(SIZE_OF_INPUT/2)*(SIZE_OF_BUFFER/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_BUFFER/2)]       ),
                        .is_empty_o     (is_empty[buffer_index]                                             ),
                        .is_full_o   	(is_full[buffer_index]                                              )
                    );
                end
                2,3: 
                begin
                    sipo#(
                        .SIZE_OF_INPUT (SIZE_OF_INPUT/2),
                        .SIZE_OF_BUFFER(SIZE_OF_BUFFER/2)
                    ) buffer_inst (
                        .clk_i          (clk_i                                                              ),
                        .rst_i          (rst_i                                                              ),
                        .rd_en_i        (rd_en_i                                                            ),
                        .wr_en_i        (wr_en_i[buffer_index]                                              ),
                      	.data_i      	(wr_data_i[(SIZE_OF_INPUT/2)+:(SIZE_OF_INPUT/2)]                    ),
                        .data_o      	(rd_data_o[buffer_index*(SIZE_OF_INPUT/2)*(SIZE_OF_BUFFER/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_BUFFER/2)]       ),
                        .is_empty_o     (is_empty[buffer_index]                                             ),
                        .is_full_o   	(is_full[buffer_index]                                              )
                    );
                end
            endcase
        end
    endgenerate
endmodule


