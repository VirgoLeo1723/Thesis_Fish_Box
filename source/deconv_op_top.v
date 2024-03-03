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
    parameter SIZE_OF_WEIGHT     = 5,
    parameter SIZE_OF_FEATURE    = 2,
    parameter PIX_WIDTH          = 8,
    parameter REG_WIDTH          = 32,
    parameter STRIDE             = 2,
    parameter N_PIX_IN           = SIZE_OF_FEATURE*SIZE_OF_WEIGHT, 
    parameter N_PIX_OUT          = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1),
    parameter STRB_WIDTH         = 2*PIX_WIDTH*N_PIX_IN/4
)(
    input                                       i_clk                      ,
    input                                       i_rst_n                    ,
    input   [PIX_WIDTH*SIZE_OF_WEIGHT-1    :0]  i_weight_col               ,
    input   [PIX_WIDTH*SIZE_OF_FEATURE-1   :0]  i_feature_map_col          ,
    input   [REG_WIDTH-1:0]                     i_param_cfg_feature        ,
    input   [REG_WIDTH-1:0]                     i_param_cfg_weight         ,
    input   [REG_WIDTH-1:0]                     i_param_cfg_output         ,
    output                                      en_prcs_new_chnl           , //change to the next channel of same kernel
    output                                      en_prcs_new_wcoln          ,
    output                                      en_fifo_loop               ,

    input                                       i_enable_loadw             , //load one col weight
    input                                       i_enable_loadip            , //load one col input
    output                                      o_full_start               ,
    output  [2*PIX_WIDTH*N_PIX_OUT-1:0]         o_cmpl_deconv_col          , // output of the buffer
    output                                      o_valid                                     
);
    wire                                                    eachcol_full_start          ;
    wire                                                    eachcol_ready               ;
    wire                                                    eachcol_en_accumm           ;
    wire                                                    eachcol_en_weight_loopback  ;
    wire                                                    eachcol_en_prcs_new_chnl    ;
    wire                                                    eachcol_en_loadip           ;
    wire                                                    eachcol_en_loadw            ;
    wire                                                    eachcol_en_strobe           ;
    wire                                                    eachcol_init                ;
    wire [PIX_WIDTH*SIZE_OF_WEIGHT-1:0]                     eachcol_weight_in           ;
    wire [PIX_WIDTH*SIZE_OF_FEATURE-1:0]                    eachcol_feature_in          ;
    wire [31:0]                                             eachcol_kernel_column_id    ;
    wire [31:0]                                             eachcol_input_column_id     ;
    wire [2*PIX_WIDTH*SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1:0]   eachcol_out_feature_map     ;
    wire [SIZE_OF_FEATURE-1:0]                              eachcol_en_col_ip_reg_bank  ;
    wire [SIZE_OF_WEIGHT-1:0]                               eachcol_en_col_wght_reg_bank;
    wire [SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1:0]               eachcol_en_core             ;


    wire [2*PIX_WIDTH*N_PIX_OUT-1:0]            shift_reg_out_deconv_feature;
    wire [STRB_WIDTH-1:0]                       shift_reg_strobe            ;
    wire                                        shift_reg_finish            ;
    wire                                        shift_reg_out_valid         ;

    wire                                        overlap_result_valid        ;
    wire  [2*PIX_WIDTH*N_PIX_OUT-1:0]           overlap_result              ;

    reg   [SIZE_OF_FEATURE-1:0]                 reg_eachcol_ip_col          ;
    reg   [SIZE_OF_WEIGHT-1:0]                  reg_eachcol_wght_col        ;
    reg   [SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1:0]  reg_eachcol_en_core_all     ;

    assign eachcol_en_loadip            = i_enable_loadip                   ;
    assign eachcol_en_loadw             = i_enable_loadw                    ;
    assign eachcol_weight_in            = i_weight_col                      ;
    assign eachcol_feature_in           = i_feature_map_col                 ;
    assign eachcol_en_col_ip_reg_bank   = reg_eachcol_ip_col                ;
    assign eachcol_en_col_wght_reg_bank = reg_eachcol_wght_col              ;
    assign eachcol_en_core              = reg_eachcol_en_core_all           ;

    assign shift_reg_strobe  = {STRB_WIDTH{eachcol_en_strobe}}  ;
    assign en_fifo_loop      = eachcol_en_weight_loopback       ;
    assign en_prcs_new_chnl  = eachcol_en_prcs_new_chnl         ;

    assign en_prcs_new_wcoln = shift_reg_finish                 ;
    assign o_full_start      = eachcol_full_start               ;
    assign o_valid           = overlap_result_valid             ;
    assign o_cmpl_deconv_col = overlap_result                   ;

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_eachcol_ip_col   <= 0;
            reg_eachcol_wght_col <= 0;
        end
        else begin
            reg_eachcol_ip_col   <= 2<<`FEATURE_SIZE -1;
            reg_eachcol_wght_col <= 2<<`WEIGHT_SIZE  -1;
        end
    end  

    reg [SIZE_OF_FEATURE-1:0] col_idx; 
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_eachcol_en_core_all <= 0;
        end
        else begin
            for(col_idx = 0; col_idx < SIZE_OF_WEIGHT; col_idx = col_idx+1) begin
                if(eachcol_en_col_ip_reg_bank[col_idx] == 1) begin
                    reg_eachcol_en_core_all <= {reg_eachcol_en_core_all[SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1: SIZE_OF_WEIGHT], 
                                                eachcol_en_col_wght_reg_bank};
                end
            end
        end
    end    

    shift_register #(
        .PIX_WIDTH            (PIX_WIDTH                    ),
        .SIZE_OF_WEIGHT       (SIZE_OF_WEIGHT               ),
        .SIZE_OF_FEATURE      (SIZE_OF_FEATURE              ),
        .STRIDE               (STRIDE                       ),
        .N_PIX_IN             (N_PIX_IN                     ),
        .N_PIX_OUT            (N_PIX_OUT                    ),
        .STRB_WIDTH           (STRB_WIDTH                   )
    ) u_accum_data (
        .clk                  (i_clk                        ),
        .rst_n                (i_rst_n                      ),
        .data_in              (eachcol_out_feature_map      ),
        .en_shift             (eachcol_en_accumm            ),       
        .data_strobe          (shift_reg_strobe             ),   
        .data_out             (shift_reg_out_deconv_feature ),
        .i_param_cfg_feature  (i_param_cfg_feature          ),
        .i_param_cfg_weight   (i_param_cfg_weight           ),
        .valid_o              (shift_reg_out_valid          ),
        .accumn_fin           (shift_reg_finish             )
    );
  
    deconv_eachcol  #(
        .PIX_WIDTH            (PIX_WIDTH                    ),
        .SIZE_OF_WEIGHT       (SIZE_OF_WEIGHT               ),
        .SIZE_OF_FEATURE      (SIZE_OF_FEATURE              )
    )u_deconv_eachcol(
        .i_clk                (i_clk                        ),
        .i_rst_n              (i_rst_n                      ),
        .i_weight_col         (eachcol_weight_in            ),
        .i_feature_map_col    (eachcol_feature_in           ),
        .i_enable_loadip      (eachcol_en_loadip            ),
        .i_enable_loadw       (eachcol_en_loadw             ),
        .i_param_cfg_feature  (i_param_cfg_feature          ),
        .i_param_cfg_weight   (i_param_cfg_weight           ),
        .i_enable_core        (eachcol_en_core              ),
        .en_accumm            (eachcol_en_accumm            ),
        .kernel_column_id     (eachcol_kernel_column_id     ),
        .input_column_id      (eachcol_input_column_id      ),
        .en_fifo_loop         (eachcol_en_weight_loopback   ),
        .en_prcs_new_chnl     (eachcol_en_prcs_new_chnl     ),
        .o_feature_map_col    (eachcol_out_feature_map      ),
        .o_ready              (eachcol_ready                ),
        .o_en_strobe          (eachcol_en_strobe            ),
        .o_full_start         (eachcol_full_start           )
    );


    overlap_prcs #(
        .SIZE_OF_INPUT        (N_PIX_OUT                    ),
        .SIZE_OF_WEIGHT       (SIZE_OF_WEIGHT               ),
        .PIX_WIDTH            (PIX_WIDTH*2                  ),
        .STRIDE               (STRIDE                       )
    )u_overlap_prcs (
        .clk_i                (i_clk                        ),
        .rst_i                (i_rst_n                      ),
        .valid_i              (shift_reg_out_valid          ),
        .wr_en_i              (shift_reg_out_valid          ),
        .buffer_i             (shift_reg_out_deconv_feature ),
        .i_param_cfg_feature  (i_param_cfg_feature          ),
        .i_param_cfg_weight   (i_param_cfg_weight           ),
        .i_param_cfg_output   (i_param_cfg_output           ),
        .buffer_o             (overlap_result               ),
        .valid_o              (overlap_result_valid         )
    );

endmodule


