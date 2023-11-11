`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 10:16:00 AM
// Design Name: 
// Module Name: deconv_core
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


module deconv_core #(
        parameter SIZE_OF_GATHER_RESULT = 512,
        parameter BRAM_DATA_WIDTH       = 32 ,                                                                          
        parameter ADDRESS_WIDTH         = 13 ,                                                                          
        parameter SIZE_OF_FEATURE       = 2  ,                                                                          
        parameter SIZE_OF_WEIGHT        = 3  ,                                                                          
        parameter PIX_WIDTH             = 16 ,                                                                          
        parameter STRIDE                = 1  ,                                                                          
        parameter N_PIX_IN              = SIZE_OF_FEATURE*SIZE_OF_WEIGHT,                                            
        parameter STRB_WIDTH            = 2*PIX_WIDTH*N_PIX_IN/4 ,                                                      
        parameter N_PIX_OUT             = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                        (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1) ,
        parameter NON_OVERLAPPED_CONST      = SIZE_OF_FEATURE * STRIDE,
        parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_FEATURE-1) + SIZE_OF_WEIGHT,
        parameter SIZE_OF_PRSC_OUTPUT       = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST)
    )(
        input                            i_clk                                      ,
        input                            i_rst_n                                    ,
        output  [3:0]                    weight_reader_en                           ,
        input   [3:0]                    weight_reader_valid                        ,
        input   [PIX_WIDTH*4-1:0]        weight_reader_data_out                     ,
        
        output  [3:0]                    feature_reader_en                          ,
        input   [3:0]                    feature_reader_valid                       ,
        input   [PIX_WIDTH*4-1:0]        feature_reader_data_out 
    );

    wire                                 feature_writer_en                          ;
    wire                                 feature_writer_valid                       ;
    wire                                 feature_writer_finish                      ;
    wire [SIZE_OF_GATHER_RESULT-1:0]     feature_writer_data_in                     ;
    wire [ADDRESS_WIDTH-1:0]             feature_bram_addr                          ;      
    wire                                 feature_bram_en                            ;
    wire                                 feature_bram_we                            ;
    wire [BRAM_DATA_WIDTH-1:0]           feature_bram_data_out                      ;
    wire [BRAM_DATA_WIDTH-1:0]           feature_bram_data_in                       ;                            
                                
    wire                                 weight_writer_finish                       ;
    wire [ADDRESS_WIDTH-1:0]             weight_bram_addr                           ;      
    wire                                 weight_bram_en                             ;
    wire                                 weight_bram_we                             ;
    wire [BRAM_DATA_WIDTH-1:0]           weight_bram_data_out                       ;
    
    wire [3:0]                           weight_fifo_wr_en                          ;          
    wire [3:0]                           weight_fifo_rd_en                          ;          
    wire [3:0]                           weight_fifo_loop                           ;          
    wire [3:0]                           weight_fifo_flush                          ;           
    wire [PIX_WIDTH-1:0]                 weight_fifo_in           [0:3]             ;           
    wire [PIX_WIDTH*SIZE_OF_WEIGHT-1:0]  weight_fifo_out          [0:3]             ;     
    wire [3:0]                           weight_fifo_empty                          ;
    wire [3:0]                           weight_fifo_full                           ;  
    wire [3:0]                           weight_fifo_pre_full                       ;              
    wire [3:0]                           weight_fifo_export_done                    ;          
    wire [3:0]                           weight_fifo_core_init                      ;             
    wire [3:0]                           weight_fifo_request_data                   ;          
    wire [3:0]                           weight_fifo_flush_fin                      ;         
    wire [3:0]                           weight_fifo_loop_fin                       ;  
           
    wire [3:0]                          deconv_multi_kernel_weight_fifo_rd_en[0:3]  ;
    wire [3:0]                          deconv_multi_kernel_weight_fifo_loop[0:3]   ;
    wire [3:0]                          deconv_multi_kernel_weight_fifo_flush[0:3]  ;
    wire [PIX_WIDTH*SIZE_OF_WEIGHT*4:0] deconv_multi_kernel_weight_fifo_out         ;
    
    wire [PIX_WIDTH*4-1:0]              deconv_multi_kernel_feature_reader_data_out ;
    wire [3:0]                          deconv_multi_kernel_feature_reader_valid    ;
    wire [3:0]                          deconv_multi_kernel_feature_reader_en       ;
    wire                                deconv_multi_kernel_weight_fifo_export_done ;
    wire                                deconv_multi_kernel_weight_fifo_core_init   ;
    wire [N_PIX_OUT*PIX_WIDTH-1:0]      deconv_multi_kernel_col_result [0:3]        ;
    wire [3:0]                          deconv_multi_kernel_valid      [0:3]        ; 
    assign deconv_multi_kernel_feature_reader_data_out  = feature_reader_data_out;
    assign deconv_multi_kernel_feature_reader_valid     = feature_reader_valid;    
    assign feature_reader_en                            = deconv_multi_kernel_feature_reader_en;
    
    
    assign deconv_multi_kernel_weight_fifo_out          ={weight_fifo_out[3],
                                                          weight_fifo_out[2], 
                                                          weight_fifo_out[1],
                                                          weight_fifo_out[0]};
    assign deconv_multi_kernel_weight_fifo_export_done  = weight_fifo_export_done[3] &
                                                          weight_fifo_export_done[2] &
                                                          weight_fifo_export_done[1] &
                                                          weight_fifo_export_done[0] ;
    assign deconv_multi_kernel_weight_fifo_core_init    = weight_fifo_core_init[3] &
                                                          weight_fifo_core_init[2] &
                                                          weight_fifo_core_init[1] &
                                                          weight_fifo_core_init[0] ;
       
    genvar weight_fifo_index;
    generate
        for (weight_fifo_index=0; weight_fifo_index<4; weight_fifo_index=weight_fifo_index+1)
        begin
            weight_fifo #(
                 .PIX_WIDTH             (PIX_WIDTH                  ),
                 .SIZE_OF_WEIGHT        (SIZE_OF_WEIGHT             ),
                 .N_OF_PIXELS           (SIZE_OF_WEIGHT*SIZE_OF_WEIGHT*4)
            )
            weight_fifo_inst_0 (
                .i_clk                  (i_clk                      ),                                                
                .i_rst_n                (i_rst_n                    ),                                                
                .wr_en                  (weight_fifo_wr_en        [weight_fifo_index]),                                                
                .rd_en                  (weight_fifo_rd_en        [weight_fifo_index]),                                                
                .loop_back              (weight_fifo_loop         [weight_fifo_index]),                                                
                .i_flush                (weight_fifo_flush        [weight_fifo_index]),                                                
                .data_in                (weight_fifo_in           [weight_fifo_index]),                                                
                .colw_data_out          (weight_fifo_out          [weight_fifo_index]),         
                .s_empty                (weight_fifo_empty        [weight_fifo_index]),                                                
                .s_full                 (weight_fifo_full         [weight_fifo_index]),      
                .s_pre_full             (weight_fifo_pre_full     [weight_fifo_index]),                                          
                .col_export_done        (weight_fifo_export_done  [weight_fifo_index]),                   
                .init                   (weight_fifo_core_init    [weight_fifo_index]),
                .request_data	        (weight_fifo_request_data [weight_fifo_index]),                                                     
                .flush_fin		        (weight_fifo_flush_fin    [weight_fifo_index]),                                                         
                .loop_fin               (weight_fifo_loop_fin     [weight_fifo_index])
            );
            assign weight_reader_en[weight_fifo_index]  = ~weight_fifo_pre_full[weight_fifo_index];
            assign weight_fifo_in[weight_fifo_index]    = weight_reader_data_out[weight_fifo_index*PIX_WIDTH+:PIX_WIDTH];
            assign weight_fifo_wr_en[weight_fifo_index] = weight_reader_valid[weight_fifo_index] 
                                                        && ~weight_fifo_full[weight_fifo_index];
            assign weight_fifo_flush[weight_fifo_index] = deconv_multi_kernel_weight_fifo_flush[0][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_flush[1][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_flush[2][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_flush[3][weight_fifo_index] ;
            assign weight_fifo_loop[weight_fifo_index]  = deconv_multi_kernel_weight_fifo_loop[0][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_loop[1][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_loop[2][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_loop[3][weight_fifo_index] ;
            assign weight_fifo_rd_en[weight_fifo_index] =(
                                                          deconv_multi_kernel_weight_fifo_rd_en[0][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_rd_en[1][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_rd_en[2][weight_fifo_index] &
                                                          deconv_multi_kernel_weight_fifo_rd_en[3][weight_fifo_index]
                                                          )|
                                                          weight_fifo_core_init[weight_fifo_index]                    ;                                             
        end
    endgenerate
    
    genvar core_index;
    generate
        for (core_index=0; core_index<4; core_index=core_index+1)
        begin
            deconv_multi_kernel_top#(
                .SIZE_OF_GATHER_RESULT      (SIZE_OF_GATHER_RESULT     ),                                                                       
                .BRAM_DATA_WIDTH            (BRAM_DATA_WIDTH           ),                                                                          
                .ADDRESS_WIDTH              (ADDRESS_WIDTH             ),                                                                          
                .SIZE_OF_FEATURE            (SIZE_OF_FEATURE           ),                                                                          
                .SIZE_OF_WEIGHT             (SIZE_OF_WEIGHT            ),                                                                          
                .PIX_WIDTH                  (PIX_WIDTH                 ),                                                                          
                .STRIDE                     (STRIDE                    ),                                                                          
                .N_PIX_IN                   (N_PIX_IN                  ),                                            
                .STRB_WIDTH                 (STRB_WIDTH                ),                                                      
                .N_PIX_OUT                  (N_PIX_OUT                 )
                                            
            )deconv_multi_kernel_top_inst(
                .i_clk                      (i_clk                                            ),
                .i_rst_n                    (i_rst_n                                          ),  
                               
                .feature_reader_data_out    (deconv_multi_kernel_feature_reader_data_out[core_index*PIX_WIDTH+:PIX_WIDTH]),
                .feature_reader_valid       (deconv_multi_kernel_feature_reader_valid[core_index]),
                .feature_reader_en          (deconv_multi_kernel_feature_reader_en[core_index]),  
                // moi multil kernel dung khac nhau  [output]
                .weight_fifo_rd_en          (deconv_multi_kernel_weight_fifo_rd_en[core_index]),                                                
                .weight_fifo_loop           (deconv_multi_kernel_weight_fifo_loop[core_index] ),                                                
                .weight_fifo_flush          (deconv_multi_kernel_weight_fifo_flush[core_index]),                                                                                             
                .weight_fifo_out            (deconv_multi_kernel_weight_fifo_out              ),    
                .weight_fifo_export_done    (deconv_multi_kernel_weight_fifo_export_done      ),                   
                .weight_fifo_core_init      (deconv_multi_kernel_weight_fifo_core_init        ),
                
                .deconv_valid_o             (deconv_multi_kernel_valid[core_index]            ),     
                .deconv_col_result_o        (deconv_multi_kernel_col_result[core_index]       )
            );   
        end
    endgenerate
    
    wire [3:0] core_overlap_valid_out;
    wire [3:0] core_overlap_valid_in;
    wire [3:0] core_overlap_en;
    wire [SIZE_OF_PRSC_OUTPUT*PIX_WIDTH-1:0] core_overlap_result [0:3];
    
    genvar overlap_prcs_index;
    generate
        for (overlap_prcs_index=0; overlap_prcs_index<4; overlap_prcs_index = overlap_prcs_index + 1)
        begin
            core_overlap_prsc#(
                .SIZE_OF_EACH_CORE_INPUT   (SIZE_OF_FEATURE     ),
                .SIZE_OF_EACH_KERNEL       (SIZE_OF_WEIGHT      ),
                .STRIDE                    (STRIDE              ), 
                .PIX_WIDTH                 (PIX_WIDTH           ),     
                .NON_OVERLAPPED_CONST      (NON_OVERLAPPED_CONST),
                .SIZE_OF_PRSC_INPUT        (SIZE_OF_PRSC_INPUT  ),
                .SIZE_OF_PRSC_OUTPUT       (SIZE_OF_PRSC_OUTPUT )
            )core_overlap_prsc_inst(
                .clk_i              (i_clk                                                                                          ),
                .rst_i              (i_rst_n                                                                                        ),
                .en_i               (core_overlap_en[overlap_prcs_index]                                                            ),
                .valid_i            (core_overlap_valid_in[overlap_prcs_index]                                                      ),
                .core_data_0_i      (deconv_multi_kernel_col_result[0][overlap_prcs_index*N_PIX_OUT*PIX_WIDTH+:N_PIX_OUT*PIX_WIDTH] ),
                .core_data_1_i      (deconv_multi_kernel_col_result[1][overlap_prcs_index*N_PIX_OUT*PIX_WIDTH+:N_PIX_OUT*PIX_WIDTH] ),
                .core_data_2_i      (deconv_multi_kernel_col_result[2][overlap_prcs_index*N_PIX_OUT*PIX_WIDTH+:N_PIX_OUT*PIX_WIDTH] ),
                .core_data_3_i      (deconv_multi_kernel_col_result[3][overlap_prcs_index*N_PIX_OUT*PIX_WIDTH+:N_PIX_OUT*PIX_WIDTH] ),
                .valid_o            (core_overlap_valid_out [overlap_prcs_index]),
                .overlapped_column_o(core_overlap_result[overlap_prcs_index])
            );
            assign core_overlap_valid_in[overlap_prcs_index] = & deconv_multi_kernel_valid[overlap_prcs_index];
            assign core_overlap_en[overlap_prcs_index] = & deconv_multi_kernel_valid[overlap_prcs_index];
        end
    endgenerate 
endmodule
