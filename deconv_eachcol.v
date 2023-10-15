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


module deconv_eachcol
#(
    parameter BIT_WIDTH            = 8,
    parameter NO_COL_KERNEL        = 5,
    parameter NO_COL_INPUT_FEATURE = 8
)(
    input                                                         i_clk             ,
    input                                                         i_rst_n           ,
    input   [BIT_WIDTH*NO_COL_KERNEL-1                       :0]  i_weight_col      ,
    input   [BIT_WIDTH*NO_COL_INPUT_FEATURE-1                :0]  i_feature_map_col ,
    output  [2*BIT_WIDTH*NO_COL_KERNEL*NO_COL_INPUT_FEATURE-1:0]  o_feature_map_col ,
    output  en_accumm                                                               ,  
    output  [2:0] kernel_column_id                                                  , //weight col id
    output  [3:0] input_column_id                                                   , //input col id
    output  en_fifo_loop                                                            , //loop back weight to compute new input column
    output  en_prcs_new_chnl                                                        , //change to the next channel of same kernel
    input   i_enable_loadw                                                          , //load one col weight
    input   i_enable_loadip                                                         , //load one col input
    output  o_ready                                                                 ,
    output  o_en_strobe                                                             ,
    output  o_full_start                                                            ,
    output  o_init                      
);
    genvar i;

    reg [3:0] ip_col_index;
    wire last_ip_col = (ip_col_index == NO_COL_INPUT_FEATURE ) ? 1 : 0;

    reg loop_back;
    reg reg_pre_en;
    reg reg_en_strobe;
    generate
    for(i = 0; i < NO_COL_INPUT_FEATURE; i = i + 1) begin
        multi_mul u_multi_mul (
                                .i_clk                  (i_clk)                                       ,
                                .i_rst_n                (i_rst_n)                                     ,
                                .i_weight_col           (i_weight_col)                                ,
                                .i_pix_feature_map      (i_feature_map_col[i*BIT_WIDTH   +: BIT_WIDTH])   ,
                                .o_feature_map_col      (o_feature_map_col[2*i*BIT_WIDTH*NO_COL_KERNEL +: 2*BIT_WIDTH*NO_COL_KERNEL]) ,
                                .o_kercol_cnt           (kernel_column_id)                           ,
                                .i_enable_colw          (i_enable_loadw)                              ,
                                .i_enable_colip         (i_enable_loadip)                             ,
                                .o_ready                (o_ready)                                     ,
                                .o_start                (o_full_start) , 
                                .o_init                 (o_init)                                   
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
            if(kernel_column_id == NO_COL_KERNEL) begin
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

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_pre_en <= 0;
        end
        else begin
            if(w_en_accumm) 
            begin
                reg_pre_en <= 1'b1;
            end
        end
    end

    //need a strobe to keep track loading out data by 2 bytes
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            reg_en_strobe <= 0;
        end
        else begin
            if(w_en_accumm) begin
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
