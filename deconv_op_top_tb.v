`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 12:25:19 PM
// Design Name: 
// Module Name: deconv_op_top_tb
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


module deconv_op_top_tb( );
    parameter WEIGHT_SIZE       = 5;                                                                      
    parameter BIT_WIDTH         = 8;                                                                      
    parameter FEATURE_SIZE      = 8;                                                                      
    parameter STRIDE_SETTING    = 2;                                                                      
    parameter N_PIX_IN          = FEATURE_SIZE*WEIGHT_SIZE;                                                     
    parameter N_PIX_OUT         = FEATURE_SIZE*WEIGHT_SIZE - (WEIGHT_SIZE-STRIDE_SETTING)*(FEATURE_SIZE-1);     
    parameter STRB_WIDTH        = 2*BIT_WIDTH*N_PIX_IN/4 ;                                                      

    reg                                 i_clk                   ;
    reg                                 i_rst_n                 ;
    reg [BIT_WIDTH-1:0]                 weight_fifo_in          ;
    reg                                 weight_fifo_wr_en       ;

    reg   [BIT_WIDTH*FEATURE_SIZE-1:0]  op_top_feature_map_col  ;
    reg                                 op_top_enable_loadip    ;
    
    wire                                weight_fifo_empty       ;
    wire                                weight_fifo_full        ;
    wire                                weight_fifo_export_done ;
    wire                                weight_fifo_rd_en       ;
    wire [BIT_WIDTH*WEIGHT_SIZE-1:0]    weight_fifo_out         ;
    wire                                weight_fifo_loop        ;
    wire                                weight_fifo_core_init   ;

    wire                                op_top_weight_fifo_rd_en;
    wire                                op_top_en_prcs_new_chnl ;   //change to the next channel of same kernel
    wire                                op_top_full_start       ;
    wire  [2*BIT_WIDTH*N_PIX_OUT-1:0]   op_top_cmpl_deconv_col  ;   // output of the buffer
    wire                                op_top_valid            ;   // indicate that output is valid for next process
    wire                                op_top_init             ;
    initial
    begin
        i_clk = 0;
        repeat(10000) #1 i_clk = ~i_clk;
    end
    
    initial
    begin
           i_rst_n = 0;
        #2 i_rst_n = 1;
    end

    initial
    begin
        weight_fifo_wr_en = 1'b0;
        weight_fifo_in    = 8'd0;
        wait (i_rst_n === 1'b1);
        @(posedge i_clk);
        
        // write operation
        repeat(10)
        begin
            weight_fifo_wr_en = 1'b0;
            wait(weight_fifo_full===1'b0);
            weight_fifo_wr_en = 1'b1; 
            while (~weight_fifo_full)
            begin
                weight_fifo_in = $urandom_range(0,2**8);
                @(posedge i_clk);
            end

        end
    end
    
    reg   [BIT_WIDTH*FEATURE_SIZE-1:0]  ip_feature_input;
    initial
    begin
        repeat(10)
        begin
            op_top_enable_loadip   = 1'b0;
            wait (weight_fifo_flush === 1'b0);
            op_top_enable_loadip   = 1'b1;
            ip_feature_input       = {$random,$random};
            while (~weight_fifo_flush)
            begin
                op_top_enable_loadip   = 1'b0;
                wait (weight_fifo_export_done===1'b1); 
                op_top_feature_map_col = ip_feature_input;
                op_top_enable_loadip   = 1'b1;
                @(posedge i_clk);
            end
        end
    end
    
    deconv_op_top deconv_op_top_inst_0
    (
        .i_clk                  (i_clk                   ),
        .i_rst_n                (i_rst_n                 ),
        .i_weight_col           (weight_fifo_out         ),
        .i_feature_map_col      (op_top_feature_map_col  ),
        .en_prcs_new_chnl       (weight_fifo_flush       ), //change to the next channel of same kernel
        .en_prcs_new_wcoln      (op_top_weight_fifo_rd_en),
        .en_fifo_loop           (weight_fifo_loop        ),
        .i_enable_loadw         (weight_fifo_export_done ), //load one col weight
        .i_enable_loadip        (op_top_enable_loadip    ), //load one col input
        .o_full_start           (op_top_full_start       ),
        .o_cmpl_deconv_col      (op_top_cmpl_deconv_col  ),   // output of the buffer
        .o_valid                (op_top_valid            ),    // indicate that output is valid for next process
        .o_init                 (op_top_init             )
    );
    
    assign weight_fifo_rd_en = op_top_weight_fifo_rd_en | weight_fifo_core_init;
    weight_fifo #(
         .BIT_WIDTH         (BIT_WIDTH  ),
         .NO_COL_KERNEL     (WEIGHT_SIZE),
         .DEPTH_SIZE        (WEIGHT_SIZE*WEIGHT_SIZE)
    )
    weight_fifo_inst_0 (
        .i_clk              (i_clk                  ),                                                
        .i_rst_n            (i_rst_n                ),                                                
        .wr_en              (weight_fifo_wr_en      ),                                                
        .rd_en              (weight_fifo_rd_en      ),                                                
        .loop_back          (weight_fifo_loop       ),                                                
        .i_flush            (weight_fifo_flush      ),                                                
        .data_in            (weight_fifo_in         ),                                                
        .colw_data_out      (weight_fifo_out        ), //one column weight         
        .s_empty            (weight_fifo_empty      ),                                                
        .s_full             (weight_fifo_full       ),                                                
        .col_export_done    (weight_fifo_export_done),                   //connect with i_enable signa
        .init               (weight_fifo_core_init  ),
        .request_data	    (request_data           ),                                                     
        .flush_fin		    (flush_fin              ),                                                         
        .loop_fin           (loop_fin               )
    );
    

endmodule
