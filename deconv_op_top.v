`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 12:18:13 PM
// Design Name: 
// Module Name: deconv_op_top
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


module deconv_op_top 
#(
    parameter WEIGHT_SIZE     = 5,
    parameter BIT_WIDTH       = 8,
    parameter FEATURE_SIZE    = 8,
    parameter STRIDE_SETTING  = 2,
    parameter N_PIX_IN = FEATURE_SIZE*WEIGHT_SIZE, 
    parameter N_PIX_OUT = FEATURE_SIZE*WEIGHT_SIZE - (WEIGHT_SIZE-STRIDE_SETTING)*(FEATURE_SIZE-1),
    parameter STRB_WIDTH = 2*BIT_WIDTH*N_PIX_IN/4
)(
    input                                    i_clk             ,
    input                                    i_rst_n           ,
    input   [BIT_WIDTH*WEIGHT_SIZE-1    :0]  i_weight_col      ,
    input   [BIT_WIDTH*FEATURE_SIZE-1   :0]  i_feature_map_col ,
    output                                   en_prcs_new_chnl  , //change to the next channel of same kernel
    output                                   en_prcs_new_wcoln ,
    output                                   en_fifo_loop      ,

    input                                    i_enable_loadw    , //load one col weight
    input                                    i_enable_loadip   , //load one col input
    output                                   o_full_start      ,
    output  [2*BIT_WIDTH*N_PIX_OUT-1:0]      o_cmpl_deconv_col  ,   // output of the buffer
    output                                   o_valid               // indicate that output is valid for next process
);
    wire s_empty_fifo;
    wire s_full_fifo;
    wire [STRB_WIDTH-1:0] data_strb;
    assign data_strb = {STRB_WIDTH{o_en_strobe}};


    shift_register 
    #(
        .BIT_WIDTH      (BIT_WIDTH          ),
        .N_COL_KERNEL   (WEIGHT_SIZE        ),
        .N_COL_FEATURE  (FEATURE_SIZE       ),
        .NUM_STRIDE     (STRIDE_SETTING     ),
        .N_PIX_IN       (N_PIX_IN           ),
        .N_PIX_OUT      (N_PIX_OUT          ),
        .STRB_WIDTH     (STRB_WIDTH         )
    ) u_accum_data 
    (
        .clk            (i_clk              ),
        .rst_n          (i_rst_n            ),
        .data_in        (o_feature_map      ),
        .en_shift       (en_accumm          ),       
        .data_strobe    (data_strb          ),   
        .data_out       (o_deconv_feature   ),
        .accumn_fin     (en_prcs_new_wcoln  )
    );
  
    deconv_eachcol  
    #(
        .BIT_WIDTH            (BIT_WIDTH            ),
        .NO_COL_KERNEL        (WEIGHT_SIZE          ),
        .NO_COL_INPUT_FEATURE (FEATURE_SIZE         )
    )u_deconv_eachcol
    (
        .i_clk                (i_clk                ),
        .i_rst_n              (i_rst_n              ),
        .i_weight_col         (i_weight_col         ),
        .i_feature_map_col    (i_feature_map_col    ),
        .o_feature_map_col    (o_feature_map        ),
        .en_accumm            (en_accumm            ),
        .kernel_column_id     (kernel_column_id     ),
        .input_column_id      (input_column_id      ),
        .en_fifo_loop         (en_fifo_loop         ),
        .en_prcs_new_chnl     (en_prcs_new_chnl     ),
        .i_enable_loadip      (ipfeature_load_done  ),
        .i_enable_loadw       (col_export_done      ),
        .o_ready              (o_ready              ),
        .o_en_strobe          (o_en_strobe          ),
        .o_full_start         (o_full_start         )
    );

    // weight_fifo u_weight_fifo 
    // #(
    //     .BIT_WIDTH     (BIT_WIDTH  ),
    //     .NO_COL_KERNEL (WEIGHT_SIZE),
    //     .DEPTH_SIZE    (WEIGHT_SIZE*WEIGHT_SIZE)
    // )
    // (
    //     .i_clk           (i_clk             )  ,
    //     .i_rst_n         (i_rst_n           )  ,
    //     .wr_en_fifo      (o_weight_bram_load)  ,
    //     .rd_en_fifo      (en_prcs_new_wcoln | !o_full_start)  ,
    //     .loop_back       (en_fifo_loop      )  ,
    //     .i_flush         (en_prcs_new_chnl  )  , 
    //     .data_in         (o_weight_bram_dat )  ,     //each iteration load one channel only
    //     .colw_data_out   (colw_data_out     )  ,     //one column weight
    //     .s_empty         (s_empty_fifo      )  ,     //empty when flush, then load new channel of same kernel
    //     .s_full          (s_full_fifo       )  ,     //no use
    //     .col_export_done (col_export_done   )  ,     //connect with i_enable signal of multiply module
    // );
    
    overlap_pcsr 
    #(
        .INPUT_WIDTH          (N_PIX_OUT        ),
        .BIT_WIDTH            (BIT_WIDTH        ),
        .KERNEL_WIDTH         (WEIGHT_SIZE      ),
        .STRIDE               (STRIDE_SETTING   )
    )u_overlap_pcsr
    (
        .clk_i                (i_clk            ),
        .rst_i                (i_rst_n          ),
        .wr_en_i              (en_prcs_new_wcoln),
        .buffer_i             (o_deconv_feature ),
        .buffer_o             (o_cmpl_deconv_col),
        .valid_o              (o_valid          )
    );
    
endmodule
