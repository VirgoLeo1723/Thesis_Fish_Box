`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 10:17:35 AM
// Design Name: 
// Module Name: deconv_eachcol
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
module deconv_eachcol
#(
    parameter PIX_WIDTH             = 8,
    parameter SIZE_OF_WEIGHT        = 5,
    parameter SIZE_OF_FEATURE       = 8,
    parameter REG_WIDTH             = 32 
)(
    input                                                       i_clk               ,
    input                                                       i_rst_n             ,
    input   [REG_WIDTH-1:0]                                     i_param_cfg_feature ,
    input   [REG_WIDTH-1:0]                                     i_param_cfg_weight  ,
    input   [PIX_WIDTH*SIZE_OF_WEIGHT-1  :0]                    i_weight_col        ,
    input   [PIX_WIDTH*SIZE_OF_FEATURE-1 :0]                    i_feature_map_col   ,
    input   [SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1:0]                i_enable_core       ,
    output  [2*PIX_WIDTH*SIZE_OF_WEIGHT*SIZE_OF_FEATURE-1:0]    o_feature_map_col   ,
    output                                                      en_accumm           ,  
    output  [REG_WIDTH-1:0]                                     kernel_column_id    , //weight col id
    output  [REG_WIDTH-1:0]                                     input_column_id     , //input col id
    output                                                      en_fifo_loop        , //loop back weight to compute new input column
    output                                                      en_prcs_new_chnl    , //change to the next channel of same kernel
    input                                                       i_enable_loadw      , //load one col weight
    input                                                       i_enable_loadip     , //load one col input
    output                                                      o_ready             ,
    output                                                      o_en_strobe         ,
    output  o_full_start                                                                                
);
    genvar i;
    reg [31:0] ip_col_index;
    reg loop_back;
    reg reg_pre_en;
    reg reg_en_strobe;
    wire [SIZE_OF_FEATURE-1:0] ready;
    wire [SIZE_OF_FEATURE-1:0] full_start;
    wire last_ip_col ;
    wire [SIZE_OF_FEATURE-1:0] w_kernel_column_id[0:SIZE_OF_FEATURE-1];

    assign last_ip_col = (ip_col_index == `FEATURE_SIZE) ? 1 : 0;
    
    assign o_ready = & ready;
    assign o_full_start = & full_start;
    assign kernel_column_id = w_kernel_column_id[0];
    generate
    for(i = 0; i < SIZE_OF_FEATURE; i = i + 1) begin
        multi_mul #(
            .BIT_WIDTH(PIX_WIDTH),
            .NO_COL_KERNEL(SIZE_OF_WEIGHT)
        )
        u_multi_mul (
                                .i_clk                  (i_clk                                                                          ),
                                .i_rst_n                (i_rst_n                                                                        ),
                                .i_weight_col           (i_weight_col                                                                   ),
                                .i_enable_core          (i_enable_core                                                                  ),
                                .i_param_cfg_feature    (i_param_cfg_feature                                                            ),
                                .i_param_cfg_weight     (i_param_cfg_weight[i*SIZE_OF_WEIGHT+:SIZE_OF_WEIGHT]                           ),
                                .i_pix_feature_map      (i_feature_map_col[i*PIX_WIDTH   +: PIX_WIDTH]                                  ),
                                .o_feature_map_col      (o_feature_map_col[2*i*PIX_WIDTH*SIZE_OF_WEIGHT +: 2*PIX_WIDTH*SIZE_OF_WEIGHT]  ),
                                .o_kercol_cnt           (w_kernel_column_id[i]                                                          ),
                                .i_enable_colw          (i_enable_loadw                                                                 ),
                                .i_enable_colip         (i_enable_loadip                                                                ),
                                .o_ready                (ready[i]                                                                       ),
                                .o_start                (full_start[i]                                                                  )                                                             
                                );
    end
    endgenerate


    //------------------------------------------------------------------//
    //the mechanism: each input col process each weight col iteratively
    //after process ip col done, change to next ip col and loop back weight channel again
    //the loop back is operating until one input channel is filtered
    //ip_col_index is tracking the order of input column
    //-----------------------------------------------------------------//
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            //new_colw_flag <= 0;
            ip_col_index <= 0;
            loop_back    <= 0;
        end
        else begin
            if(kernel_column_id == `WEIGHT_SIZE) begin
                //new_colw_flag <= 0               ;
                ip_col_index <= ip_col_index + 1 ;
                loop_back    <= 1                ; //loop back the first column of same weight channel
            end
            else begin
                if(last_ip_col) begin
                    ip_col_index <= 0;
                    loop_back <= 0;
                end
                else begin
                    //new_colw_flag <= 1;
                    ip_col_index  <= ip_col_index;
                    loop_back     <= 0;
                end
            end
        end
    end 

    //---------------------------------------------------------------------------//
    //module edge_detector to detect positove edge of signal o_ready
    //en_accumm when successfully export feature data in 1D
    //this data is not completed due to not accumulating by stride
    //a module to process - shift register module
    //after shift register finish, export complete feature map column to overlap processor
    //--------------------------------------------------------------------------//

    edge_detector u_detect_export_data (    
                                        .i_clk (i_clk),
                                        .i_rst_n (i_rst_n),
                                        .sig_in (~o_ready),
                                        .sig_out (w_en_accumm)
                                    );
    
    //integer valid_counter=0;
    reg                     detect_en_accum;
    reg [SIZE_OF_FEATURE:0] valid_counter;
    // always @(posedge i_clk, negedge i_rst_n) begin
    //     if(!i_rst_n) begin
    //         reg_pre_en <= 0;
    //         valid_counter <= 0;
    //     end
    //     else begin
    //         if(w_en_accumm) 
    //         begin
    //             reg_pre_en <= 1'b1;
    //         end
    //         if (reg_pre_en)
    //         begin
    //             valid_counter <= valid_counter + 1;
    //         end
    //         if (valid_counter == `FEATURE_SIZE) 
    //         begin
    //             reg_pre_en <= 1'b0;
    //             valid_counter <= 0;
    //         end
    //     end
    // end
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            detect_en_accum <= 0;
        end
        else begin
            if(w_en_accumm) begin
                detect_en_accum <= 1;
            end
            if(detect_en_accum) begin
                detect_en_accum <= ~detect_en_accum;
            end
        end
    end
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_pre_en <= 0;
            valid_counter <= 0;
        end
        else begin
            if(detect_en_accum) begin
                reg_pre_en <= 1;
            end
            else begin
                if(reg_pre_en) begin
                    valid_counter <= valid_counter + 1;
                    if(valid_counter == `FEATURE_SIZE) begin
                        valid_counter <= 0;
                        reg_pre_en <= 0;
                    end
                end
            end
        end
    end
    //need a strobe to keep track loading out data by 2 bytes
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_en_strobe <= 0;
        end
        else begin
            // if(w_en_accumm) begin
            if(detect_en_accum) begin
                reg_en_strobe <= 1;
            end
        end
    end
    
    //assignment
    assign o_en_strobe       = reg_en_strobe;
    assign en_accumm         = reg_pre_en   ;
    assign input_column_id   = ip_col_index ;
    assign en_fifo_loop      = loop_back    ;
    assign en_prcs_new_chnl  = last_ip_col  ; //load new input & weight
endmodule

