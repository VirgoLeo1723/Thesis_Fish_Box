`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 09:41:10 AM
// Design Name: 
// Module Name: multi_mul
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


module multi_mul 
#(
    parameter BIT_WIDTH = 8,
    parameter NO_COL_KERNEL = 5,
    parameter NO_COL_INPUT_FEATURE = 8,
    parameter REG_WIDTH = 32
)(
    input                                    i_clk              ,
    input                                    i_rst_n            ,
    input   [BIT_WIDTH*NO_COL_KERNEL-1  :0]  i_weight_col       ,
    input   [BIT_WIDTH-1                :0]  i_pix_feature_map  ,
    input   [REG_WIDTH-1                :0]  i_param_cfg_feature,
    input   [REG_WIDTH-1                :0]  i_param_cfg_weight , 
    input   [NO_COL_KERNEL -1           :0]  i_enable_core       , 
    output  [2*BIT_WIDTH*NO_COL_KERNEL-1:0]  o_feature_map_col  ,
    output  [2:0]                            o_kercol_cnt       ,
    input                                    i_enable_colw      ,
    input                                    i_enable_colip     ,
    output                                   o_ready            ,
    output                                   o_start          
);
    //this module is responsible to compute 
    //the single input feature pixel with the whole weight column
    //i_pix_feature_map is one single pixel
    //o_feature_map_col is the temporary separate output feature 

    genvar i;
    reg [2:0] cnt;
    wire [NO_COL_KERNEL-1:0] ready;
    wire [NO_COL_KERNEL-1:0] start;
    
    assign o_ready = &ready;
    assign o_start = &start;
    
    generate
    for (i = 0; i < NO_COL_KERNEL ; i = i + 1) begin: MULTIPLIER
        multiply #(
                        .BIT_WIDTH(BIT_WIDTH)
        )
        u_multiply (
                        .i_clk           (i_clk                                             ),
                        .i_rst_n         (i_rst_n                                           ),
                        .i_pix_weight    (i_weight_col[i*BIT_WIDTH +: BIT_WIDTH]            ),
                        .i_pix_feature   (i_pix_feature_map                                 ),
                        .i_enable_colw   (i_enable_colw                                     ), //when weight fifo concat column done
                        .i_enable_colip  (i_enable_colip                                    ),
                        .i_enable_core   (i_enable_core[i]                                  ),
                        .o_pix_feature   (o_feature_map_col[2*i*BIT_WIDTH +: 2*BIT_WIDTH]   ),
                        .o_ready         (ready[i]                                          ),
                        .o_start         (start[i]                                          )
                        );
    end
    endgenerate
    //------------------------------------------------------------//
    //to count when process one column weight done
    //count until new input channel load in the return pointer -> 0
    //count until the last weight col --> loop back again --> ptr = 0
    //------------------------------------------------------------//
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if(!i_rst_n)
        begin
            cnt <= 0;
        end
        else begin
            if(i_enable_colw & i_enable_colip) begin
                cnt <= cnt + 1;
            end
            else begin
                if(i_enable_colip || (cnt == NO_COL_KERNEL)) begin
                    cnt <= 0;
                end
            end
        end
    end
    
    //kernel id
    assign o_kercol_cnt = cnt;
endmodule
