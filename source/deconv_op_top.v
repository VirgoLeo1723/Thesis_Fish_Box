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
    input                                    i_clk                      ,
    input                                    i_rst_n                    ,
    input   [BIT_WIDTH*WEIGHT_SIZE-1    :0]  i_weight_col               ,
    input   [BIT_WIDTH*FEATURE_SIZE-1   :0]  i_feature_map_col          ,
    
    output                                   en_prcs_new_chnl           , //change to the next channel of same kernel
    output                                   en_prcs_new_wcoln          ,
    output                                   en_fifo_loop               ,

    input                                    i_enable_loadw             , //load one col weight
    input                                    i_enable_loadip            , //load one col input
    output                                   o_full_start               ,
    output  [2*BIT_WIDTH*N_PIX_OUT-1:0]      o_cmpl_deconv_col          ,   // output of the buffer
    output                                   o_valid                    ,// indicate that output is valid for next process
    output                                   o_init                 
);
    wire                                    eachcol_full_start          ;
    wire                                    eachcol_ready               ;
    wire                                    eachcol_en_accumm           ;
    wire                                    eachcol_en_weight_loopback  ;
    wire                                    eachcol_en_prcs_new_chnl    ;
    wire                                    eachcol_en_loadip           ;
    wire                                    eachcol_en_loadw            ;
    wire                                    eachcol_en_strobe           ;
    wire                                    eachcol_init                ;
    wire [8*5-1:0]                          eachcol_weight_in           ;
    wire [8*8-1:0]                          eachcol_feature_in          ;
    wire [31:0]                             eachcol_kernel_column_id    ;
    wire [31:0]                             eachcol_input_column_id     ;
    wire [2*8*40-1:0]                       eachcol_out_feature_map     ;


    wire [2*8*19-1:0]                       shift_reg_out_deconv_feature;
    wire [STRB_WIDTH-1:0]                   shift_reg_strobe            ;
    wire                                    shift_reg_finish            ;

    wire  [2*8*19-1:0]                      overlap_result_valid        ;
    wire                                    overlap_result              ;

    assign eachcol_en_loadip = i_enable_loadip                  ;
    assign eachcol_en_loadw  = i_enable_loadw                   ;
    assign eachcol_weight_in = i_weight_col                     ;
    assign eachcol_feature_in= i_feature_map_col                ;
    assign shift_reg_strobe  = {STRB_WIDTH{eachcol_en_strobe}}  ;
    assign en_fifo_loop      = eachcol_en_weight_loopback       ;
    assign en_prcs_new_chnl  = eachcol_en_prcs_new_chnl         ;
    assign en_prcs_new_wcoln = shift_reg_finish                 ;
    assign o_full_start      = eachcol_full_start               ;
    assign o_valid           = overlap_result_valid             ;
    assign o_cmpl_deconv_col = overlap_result                   ;
    assign o_init            = eachcol_init                     ;

    shift_register 
    #(
        .BIT_WIDTH            (BIT_WIDTH                    ),
        .N_COL_KERNEL         (WEIGHT_SIZE                  ),
        .N_COL_FEATURE        (FEATURE_SIZE                 ),
        .NUM_STRIDE           (STRIDE_SETTING               ),
        .N_PIX_IN             (N_PIX_IN                     ),
        .N_PIX_OUT            (N_PIX_OUT                    ),
        .STRB_WIDTH           (STRB_WIDTH                   )
    ) u_accum_data 
    (
        .clk                  (i_clk                        ),
        .rst_n                (i_rst_n                      ),
        .data_in              (eachcol_out_feature_map      ),
        .en_shift             (eachcol_en_accumm            ),       
        .data_strobe          (shift_reg_strobe             ),   
        .data_out             (shift_reg_out_deconv_feature ),
        .accumn_fin           (shift_reg_finish             )
    );
  
    deconv_eachcol  
    #(
        .BIT_WIDTH            (BIT_WIDTH                    ),
        .NO_COL_KERNEL        (WEIGHT_SIZE                  ),
        .NO_COL_INPUT_FEATURE (FEATURE_SIZE                 )
    )u_deconv_eachcol
    (
        .i_clk                (i_clk                        ),
        .i_rst_n              (i_rst_n                      ),
        .i_weight_col         (eachcol_weight_in            ),
        .i_feature_map_col    (eachcol_feature_in           ),
        .o_feature_map_col    (eachcol_out_feature_map      ),
        .en_accumm            (eachcol_en_accumm            ),
        .kernel_column_id     (eachcol_kernel_column_id     ),
        .input_column_id      (eachcol_input_column_id      ),
        .en_fifo_loop         (eachcol_en_weight_loopback   ),
        .en_prcs_new_chnl     (eachcol_en_prcs_new_chnl     ),
        .i_enable_loadip      (eachcol_en_loadip            ),
        .i_enable_loadw       (eachcol_en_loadw             ),
        .o_ready              (eachcol_ready                ),
        .o_en_strobe          (eachcol_en_strobe            ),
        .o_full_start         (eachcol_full_start           ),
        .o_init               (eachcol_init                 )
    );


    overlap_pcsr 
    #(
        .INPUT_WIDTH          (N_PIX_OUT                    ),
        .BIT_WIDTH            (BIT_WIDTH*2                  ),
        .KERNEL_WIDTH         (WEIGHT_SIZE                  ),
        .STRIDE               (STRIDE_SETTING               )
    )u_overlap_pcsr
    (
        .clk_i                (i_clk                        ),
        .rst_i                (i_rst_n                      ),
        .wr_en_i              (shift_reg_finish             ),
        .buffer_i             (shift_reg_out_deconv_feature ),
        .buffer_o             (overlap_result               ),
        .valid_o              (overlap_result_valid         )
    );

endmodule

