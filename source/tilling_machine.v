`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 04:53:48 AM
// Design Name: 
// Module Name: tilling_machine
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
module tilling_machine  #(
                        	parameter SIZE_OF_EACH_CORE_INPUT   = 2,
                          	parameter SIZE_OF_EACH_KERNEL       = 3,
                          	parameter STRIDE                    = 1,
                          	parameter PIX_WIDTH                 = 16,
                          	parameter NUM_OF_KERNEL             = 16,
                          	parameter NON_OVERLAPPED_CONST      = SIZE_OF_EACH_CORE_INPUT * STRIDE,
                            parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_EACH_CORE_INPUT-1) + SIZE_OF_EACH_KERNEL,
                            parameter SIZE_OF_PRSC_OUTPUT       = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST)
                        )(
                            input                                                               clk_i                   ,
                            input                                                               rst_i                   ,
                            input  [31:0]                                                       i_param_cfg_output      ,
                            input  [31:0]                                                       i_param_cfg_weight      ,
                            input  [31:0]                                                       i_param_cfg_feature     ,
                            input                                                               valid_data_core_i       ,         
                            input  [SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH  -1:0]                      overlapped_column_core_i,
                            output [SIZE_OF_PRSC_OUTPUT*SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH   -1:0] tilling_machine_o       ,
                            output reg                                    tilling_machine_valid_o
                        );
  	wire [SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH-1:0]                    tilling_buffer_wr_data;
  	wire [SIZE_OF_PRSC_OUTPUT*SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH-1:0]    tilling_buffer_rd_data;
  	wire [3:0]                                  tilling_buffer_is_empty;
    wire [3:0]                                  tilling_buffer_is_full ;
    wire  [3:0]                                 tilling_buffer_wr_en;
  	wire [3:0]                                  tilling_buffer_en;
     
 	integer       wr_ptr;

    assign tilling_buffer_wr_data  = overlapped_column_core_i;  
    assign tilling_buffer_en       = & tilling_buffer_is_full  ;
    assign tilling_machine_o       = tilling_buffer_rd_data ;
    
    tilling_buffer #(
        .SIZE_OF_INPUT(SIZE_OF_PRSC_OUTPUT*2*PIX_WIDTH),
        .SIZE_OF_BUFFER (SIZE_OF_PRSC_OUTPUT)
    )tilling_buffer_inst (
        .clk_i	         (clk_i                   ), 
        .rst_i           (rst_i                   ),
        .wr_data_i       (tilling_buffer_wr_data  ), 
        .rd_data_o       (tilling_buffer_rd_data  ),
        .wr_en_i         (tilling_buffer_wr_en    ),
        .rd_en_i         (tilling_buffer_en       ),
        .is_empty        (tilling_buffer_is_empty ),
        .is_full         (tilling_buffer_is_full  )   
    );
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            tilling_machine_valid_o <= 1'b0;
        end    
        else
        begin
            if (& tilling_buffer_is_full)
            begin
                tilling_machine_valid_o <= 1'b1;
            end
            else
            begin
                tilling_machine_valid_o <= 1'b0;
            end
        end
    end
    
    // assign tilling_buffer_wr_en = (wr_ptr<SIZE_OF_PRSC_OUTPUT/2) & (tilling_buffer_is_full!=4'd15) & valid_data_core_i ? 4'b0101 : 
                                //   (wr_ptr < SIZE_OF_PRSC_OUTPUT) & (tilling_buffer_is_full!=4'd15) & valid_data_core_i ? 4'b1010 : 4'd0;
    
    assign tilling_buffer_wr_en = (wr_ptr<`OVERLAP_PROCESSOR_OUTPUT_SIZE/2) & (tilling_buffer_is_full!=4'd15) & valid_data_core_i ? 4'b0101 : 
                                  (wr_ptr<`OVERLAP_PROCESSOR_OUTPUT_SIZE ) & (tilling_buffer_is_full!=4'd15) & valid_data_core_i ? 4'b1010 : 4'd0;
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
//            tilling_buffer_wr_en  <= 4'd0;
            wr_ptr                <= 0;
        end
        else
        begin
            if (valid_data_core_i)
            begin
                if ( (wr_ptr<SIZE_OF_PRSC_OUTPUT/2) && (tilling_buffer_is_full!=4'd15) )
                begin
                    wr_ptr               <= wr_ptr + 1;
//                    tilling_buffer_wr_en <= 4'b0101;
                end
                else if ((wr_ptr < SIZE_OF_PRSC_OUTPUT) && (!tilling_buffer_is_full!=4'd15))
                begin
                    wr_ptr               <= wr_ptr + 1;
//                    tilling_buffer_wr_en <= 4'b1010;
                end
                else
                begin
                    wr_ptr               <= 0;
                end
            end
            else
            begin
                if (wr_ptr == SIZE_OF_PRSC_OUTPUT) 
                    wr_ptr <= 0;
                else
                    wr_ptr                  <= wr_ptr;
//                tilling_buffer_wr_en    <= 4'd0;
            end
        end
    end
 
endmodule
