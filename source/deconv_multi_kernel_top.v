`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 10:31:07 AM
// Design Name: 
// Module Name: deconv_multi_kernel_top
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


module deconv_multi_kernel_top#(
        parameter SIZE_OF_GATHER_RESULT         = 512,
        parameter BRAM_DATA_WIDTH               = 32 ,                                                                          
        parameter ADDRESS_WIDTH                 = 13 ,                                                                          
        parameter SIZE_OF_FEATURE               = 2  ,                                                                          
        parameter SIZE_OF_WEIGHT                = 3  ,                                                                          
        parameter PIX_WIDTH                     = 16 ,                                                                          
        parameter STRIDE                        = 1  ,                                                                          
        parameter N_PIX_IN                      = SIZE_OF_FEATURE*SIZE_OF_WEIGHT,                                            
        parameter STRB_WIDTH                    = 2*PIX_WIDTH*N_PIX_IN/4 ,                                                      
        parameter N_PIX_OUT                     = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                                  (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1),
        parameter NUM_OF_CHANNEL_EACH_KERNEL    = 4
    )(
        input                                       i_clk                   ,
        input                                       i_rst_n                 , 
        output [3:0]                                deconv_valid_o          ,
        output [N_PIX_OUT*2*PIX_WIDTH*4-1:0]        deconv_col_result_o         ,
        // communicate direct with feature bram reader 
        input [PIX_WIDTH-1:0]                       feature_reader_data_out ,
        input                                       feature_reader_valid    ,
        output reg                                  feature_reader_en       , 
        // communicate with weight fifo, then weight fifo communicate with weight bram reader
        output  [3:0]                               weight_fifo_rd_en         ,                                                
        output  [3:0]                               weight_fifo_loop          ,                                                
        output  [3:0]                               weight_fifo_flush         ,                                                                                             
        input   [PIX_WIDTH*SIZE_OF_WEIGHT*4-1:0]    weight_fifo_out           ,                                           
        input                                       weight_fifo_export_done   ,                   
        input                                       weight_fifo_core_init     
    );
    
//    wire                                    weight_fifo_wr_en           ;
    reg [1:0]                               feature_wr_activate         ;
    reg                                     feature_wr_strobe           ;   
    reg                                     feature_rd_strobe           ;
    reg                                     feature_rd_activate         ;
    
    reg   [PIX_WIDTH*SIZE_OF_FEATURE-1:0]   op_top_feature_map_col      ;
    reg   [PIX_WIDTH*SIZE_OF_WEIGHT*4-1:0]  op_top_weight_col           ;
    reg                                     op_top_enable_loadip        ;
    reg                                     op_top_enable_loadw         ;
    
    wire [3:0]                              op_top_weight_fifo_rd_en    ;
    wire                                    op_top_en_prcs_new_chnl     ;   
    wire [3:0]                              op_top_full_start           ;   
    wire [2*PIX_WIDTH*N_PIX_OUT*4-1:0]      op_top_cmpl_deconv_col      ;   
    wire [3:0]                              op_top_valid                ;   
    wire [3:0]                              op_top_init                 ;
    wire [3:0]                              op_top_weight_fifo_flush    ;
    wire [3:0]                              op_top_weight_fifo_loop     ;

    wire                                    feature_starved             ;
    wire [1:0]                              feature_wr_ready            ;
    wire [15:0]                             feature_wr_fifo_size        ;
    reg  [PIX_WIDTH-1:0]                    feature_wr_data             ;

    wire                                    feature_rd_ready            ;
    wire [PIX_WIDTH-1:0]                    feature_rd_data_pix         ;
    wire [15:0]                             feature_rd_cnt              ;
    wire                                    feature_inactivate          ;
        reg post_feature_reader_en;

    //result
    assign deconv_col_result_o      =  op_top_cmpl_deconv_col;
    assign deconv_valid_o           =  op_top_valid;
    // control
    assign weight_fifo_flush        = op_top_weight_fifo_flush;
    assign weight_fifo_loop         = op_top_weight_fifo_loop ;
    assign weight_fifo_rd_en[3:0]   = op_top_weight_fifo_rd_en  
                                    | {4{weight_fifo_core_init}}            ;
    
    loadip_buffer #(
        .DATA_WIDTH(PIX_WIDTH),
        .ADDR_WIDTH(8)
    )
    loadip_buffer_inst0(
    	.i_clk        (i_clk        ), 
    	.i_rst_n      (i_rst_n      ),
        // write side
        .o_wr_ready   (feature_wr_ready         ),  
        .i_wr_activate(feature_wr_activate
                      ),   
        .i_wdata      (feature_wr_data          ), 
        .i_wstrobe    (feature_wr_strobe | (post_feature_reader_en & ~feature_reader_en)), 
        .wr_fifo_size (feature_wr_fifo_size     ), 
        .o_starved    (feauture_starved         ), 
        // read side                               
        .o_rd_ready   (feature_rd_ready         ), 
        .i_rd_activate(feature_rd_activate      ), 
        .o_rdata      (feature_rd_data_pix      ),  
        .i_rstrobe    (feature_rd_strobe        ), 
        .o_rd_cnt     (feature_rd_cnt           ), 
        .o_inactivate (feature_inactivate       )  
    );

    genvar sub_core_index;
    generate 
        for (sub_core_index=0; sub_core_index<4; sub_core_index = sub_core_index+1)
        begin
            deconv_op_top #(
                .SIZE_OF_FEATURE        (SIZE_OF_FEATURE                                        ),                                                                      
                .SIZE_OF_WEIGHT         (SIZE_OF_WEIGHT                                         ),                                                                      
                .PIX_WIDTH              (PIX_WIDTH                                              ),                                                                      
                .STRIDE                 (STRIDE                                                 )         
            )
            deconv_op_top_inst (
                .i_clk                  (i_clk                                                  ),
                .i_rst_n                (i_rst_n                                                ),
                .i_enable_loadw         (op_top_enable_loadw                                    ), 
                .i_enable_loadip        (op_top_enable_loadip                                   ), 
                .i_weight_col           (op_top_weight_col[sub_core_index*
                                        (SIZE_OF_WEIGHT*PIX_WIDTH)+:SIZE_OF_WEIGHT*PIX_WIDTH]   ),
                .i_feature_map_col      (op_top_feature_map_col                                 ),
                .en_prcs_new_chnl       (op_top_weight_fifo_flush[sub_core_index]               ), 
                .en_prcs_new_wcoln      (op_top_weight_fifo_rd_en[sub_core_index]               ),
                .en_fifo_loop           (op_top_weight_fifo_loop[sub_core_index]                ),
                .o_full_start           (op_top_full_start[sub_core_index]                      ),
                .o_cmpl_deconv_col      (op_top_cmpl_deconv_col[sub_core_index*(2*PIX_WIDTH*N_PIX_OUT)+:(2*PIX_WIDTH*N_PIX_OUT)]                 ), 
                .o_valid                (op_top_valid[sub_core_index]                           ), 
                .o_init                 (op_top_init[sub_core_index]                            )
            );
        end

    endgenerate
    
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            op_top_enable_loadw  <= 1'b0;
            op_top_weight_col <= 0;
        end
        else
        begin
            if (weight_fifo_export_done && ~op_top_enable_loadw)
            begin
                op_top_enable_loadw <= 1'b1;
                op_top_weight_col   <= weight_fifo_out;
            end
            if (op_top_enable_loadw && op_top_enable_loadip)
            begin
                op_top_enable_loadw <= 1'b0;
                op_top_weight_col   <= 0;
            end
        end
    end    
         
    integer wr_count;
    integer rd_count;
    integer no_col_weight;
    integer no_col_feature;
    reg init = 1'b1;
    
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            feature_reader_en <= 1'b0;
            feature_wr_data   <= 0;
            post_feature_reader_en <= 1'b0;
        end
        else 
        begin
            post_feature_reader_en <= feature_reader_en;
            feature_wr_data     <= feature_reader_data_out;

            if (feature_wr_activate!= 2'b00 && (wr_count < (SIZE_OF_FEATURE)**2*NUM_OF_CHANNEL_EACH_KERNEL-2)) 
            begin 
                feature_reader_en <= 1'b1;
            end
            else feature_reader_en <= 1'b0;
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n)
    begin
        feature_wr_strobe <= 1'b0;
        if (!i_rst_n)
        begin
            feature_wr_activate <= 2'b00;
            feature_wr_strobe   <= 1'b0 ;
            wr_count            <= 0;
        end
        else 
        begin
            if ( (feature_wr_ready !=2'b00) && (feature_wr_activate==2'b00) && (no_col_feature==0)  )
            begin
                if (feature_wr_ready[0]) 
                begin
                    feature_wr_activate[0] <= 1'b1;
                end
                else
                begin
                    feature_wr_activate[1] <= 1'b1;
                end                
            end
            else
            begin
                if (feature_wr_activate != 2'b00)
                begin

                    if ((wr_count < (SIZE_OF_FEATURE)**2*NUM_OF_CHANNEL_EACH_KERNEL)&& (feature_reader_valid))
                    begin
                        feature_wr_strobe <= 1'b1   ;
                        wr_count          <= wr_count + 1;        
                    end
                    else
                    begin
                        if (feature_wr_activate[0] && feature_wr_strobe) 
                        begin 
                            feature_wr_activate[0] <= 1'b0;
                            if (feature_wr_ready!=2'b00) 
                            begin
                                feature_wr_activate[1] <= 1'b1;
                            end
                        end
                        else if (feature_wr_activate[1] && feature_wr_strobe) 
                        begin
                            feature_wr_activate[1] <= 1'b0;
                            if (feature_wr_ready!=2'b00) 
                            begin 
                                feature_wr_activate[0] <= 1'b1;
                            end
                        end
                        wr_count <= 0;
                        
                    end
                end
            end
        end
    end
        
    reg save_read_ready;
    always @(posedge i_clk , negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            no_col_weight   <= 0;
            no_col_feature  <= 0    ;
        end
        else
        begin
            if (op_top_enable_loadip && op_top_enable_loadw)
            begin
                 if (no_col_weight < SIZE_OF_WEIGHT-1)
                 begin
                    no_col_weight <= no_col_weight + 1;
                 end
                 else
                 begin
                     no_col_weight      <= 0;                    
                     if (no_col_feature < (SIZE_OF_FEATURE**2*NUM_OF_CHANNEL_EACH_KERNEL)/2)
                        no_col_feature     <= no_col_feature + 1;
                 end
            end
            if (no_col_feature == (SIZE_OF_FEATURE**2*NUM_OF_CHANNEL_EACH_KERNEL)/2)
                                    no_col_feature     <= 0;

        end
    end
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            feature_rd_strobe       <= 1'b0 ;
            feature_rd_activate     <= 1'b0 ;
            rd_count                <= 15'd0; 
            op_top_feature_map_col  <= 0    ;
            save_read_ready         <= 1'b0 ;
        end
        else
        begin
            if (feature_rd_ready && !feature_rd_activate && no_col_weight==0)
            begin
                save_read_ready     <= 1'b1;
                feature_rd_activate <= 1'b1;
                feature_rd_strobe   <= 1'b1;
            end
            else if (feature_rd_activate && save_read_ready)
            begin
                if (((rd_count < SIZE_OF_FEATURE-1 & ~init )||(rd_count < SIZE_OF_FEATURE & init)) && save_read_ready && feature_rd_strobe)
                begin
                    op_top_feature_map_col <= {feature_rd_data_pix, op_top_feature_map_col[PIX_WIDTH+:(PIX_WIDTH*(SIZE_OF_FEATURE-1))]};
                    rd_count <= rd_count + 1;
                end
                else
                begin
                    if (init) init <= 1'b0; 
                    op_top_feature_map_col <= {feature_rd_data_pix, op_top_feature_map_col[PIX_WIDTH+:(PIX_WIDTH*(SIZE_OF_FEATURE-1))]};
                
//                    op_top_feature_map_col  <= {op_top_feature_map_col, feature_rd_data_pix};
                    rd_count                <= 0;
                    feature_rd_strobe       <= 1'b0;
                    save_read_ready         <= 1'b0;
                end
            end
            else
            begin
                if (weight_fifo_loop && feature_rd_activate)
                begin
                    save_read_ready <= 1'b1;  
                    feature_rd_strobe <= 1'b1;  
                end
            end
            if (no_col_feature == (SIZE_OF_FEATURE**2*NUM_OF_CHANNEL_EACH_KERNEL)/2)
            begin
                feature_rd_activate     <= 1'b0 ;
                init <= 1'b1;
            end
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            op_top_enable_loadip <= 1'b0;
        end 
        else
        begin
            if (((rd_count == SIZE_OF_FEATURE-1 & ~init)||(rd_count == SIZE_OF_FEATURE & init)) || (weight_fifo_export_done && no_col_weight >0) )
//            if ( (rd_count == SIZE_OF_FEATURE) || (weight_fifo_export_done && no_col_weight >0))
            begin
                op_top_enable_loadip <= 1'b1;   
            end
            if (op_top_enable_loadw && op_top_enable_loadip)
            begin
                op_top_enable_loadip <= 1'b0;
            end
        end
    end
endmodule