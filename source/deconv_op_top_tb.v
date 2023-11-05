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


module deconv_op_top_tb ();    
    parameter SIZE_OF_FEATURE   = 2;                                                                      
    parameter SIZE_OF_WEIGHT    = 3;                                                                      
    parameter PIX_WIDTH         = 16;                                                                      
    parameter STRIDE            = 1;                                                                      
    parameter N_PIX_IN          = SIZE_OF_FEATURE*SIZE_OF_WEIGHT;                                                     
    parameter STRB_WIDTH        = 2*PIX_WIDTH*N_PIX_IN/4 ;                                                      
    parameter N_PIX_OUT         = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1);     

    reg                                     i_clk                   ;
    reg                                     i_rst_n                 ;
    wire                                     weight_fifo_wr_en       ;

    reg [1:0]                               feature_wr_activate    ;
    wire [PIX_WIDTH-1:0]                     feature_wr_data        ;
    reg                                     feature_wr_strobe      ;   
    reg                                     feature_rd_strobe      ;
    reg                                     feature_rd_activate    ;
    reg [PIX_WIDTH*SIZE_OF_FEATURE-1:0]     feature_rd_data        ;

    reg   [PIX_WIDTH*SIZE_OF_FEATURE-1:0]   op_top_feature_map_col  ;
    reg   [PIX_WIDTH*SIZE_OF_WEIGHT-1:0]    op_top_weight_col       ;
    reg                                     op_top_enable_loadip    ;
    reg                                     op_top_enable_loadw     ;
    
    wire                                    weight_fifo_empty       ;
    wire                                    weight_fifo_full        ;
    wire                                    weight_fifo_pre_full    ;
    wire                                    weight_fifo_export_done ;
    wire                                    weight_fifo_rd_en       ;
    wire [PIX_WIDTH*SIZE_OF_WEIGHT-1:0]     weight_fifo_out         ;
    wire                                    weight_fifo_loop        ;
    wire                                    weight_fifo_core_init   ;
    wire                                    weight_fifo_flush       ;
    wire [PIX_WIDTH-1:0]                    weight_fifo_in          ;

    wire                                    op_top_weight_fifo_rd_en;
    wire                                    op_top_en_prcs_new_chnl ;   //change to the next channel of same kernel
    wire                                    op_top_full_start       ;
    wire  [2*PIX_WIDTH*N_PIX_OUT-1:0]       op_top_cmpl_deconv_col  ;   // output of the buffer
    wire                                    op_top_valid            ;   // indicate that output is valid for next process
    wire                                    op_top_init             ;
    
    wire                                    feature_starved         ;
    wire [1:0]                              feature_wr_ready        ;
    wire [15:0]                             feature_wr_fifo_size    ;
 
    wire                                    feature_rd_ready        ;
    wire [PIX_WIDTH-1:0]                    feature_rd_data_pix     ;
    wire [15:0]                             feature_rd_cnt          ;
    wire                                    feature_inactivate      ;
    
    // control 
    wire                 weight_reader_en   ;
    wire                 weight_reader_valid;
    wire [PIX_WIDTH-1:0] weight_reader_data ;
    wire [31:0]          weight_bram_data   ;
    wire [12:0]          weight_bram_addr   ;
    wire                 weight_bram_en     ;
    wire                 weight_bram_we     ;
    
    wire                 feature_reader_en   ;    
    wire                 feature_reader_valid;
    wire [PIX_WIDTH-1:0] feature_reader_data ;
    wire [31:0]          feature_bram_data   ;
    wire [12:0]          feature_bram_addr   ;
    wire                 feature_bram_en     ;
    wire                 feature_bram_we     ;
    
    initial
    begin
        i_clk = 0;
        repeat(10000000) #1 i_clk = ~i_clk;
    end
    
    initial
    begin
           i_rst_n = 0;
        #2 i_rst_n = 1;
    end

//    initial
//    begin
//        weight_fifo_wr_en = 1'b0;
//        weight_fifo_in    = 8'd0;
//        wait (i_rst_n === 1'b1);
//        @(posedge i_clk);
        
//        // write operation
//        repeat(10)
//        begin
//            weight_fifo_wr_en = 1'b0;
//            wait(weight_fifo_full===1'b0);
//            weight_fifo_wr_en = 1'b1; 
//            while (~weight_fifo_full)
//            begin
//                weight_fifo_in = $urandom_range(0,2**8);
//                @(posedge i_clk);
//            end

//        end
//    end
//    always @(posedge i_clk, negedge i_rst_n)
//    begin
//        if (!i_rst_n)
//        begin
//            weight_reader_en  <= 0;
//        end
//        else
//        begin
//            if (weight_fifo_full==1'b0 && weight_fifo_wr_en)
//            begin
//                weight_reader_en  <= 1'b1;
//            end
//            else
//            begin
//                weight_reader_en <= 1'b0;
//            end
//        end
//    end
    
    assign weight_reader_en  = ~weight_fifo_pre_full ;
    assign weight_fifo_wr_en = weight_reader_valid && ~weight_fifo_full ;
    assign weight_fifo_in = weight_reader_data ;
    
    bram_reader #(
        .ADDRESS_WIDTH  (13),
        .DATA_IN_WIDTH  (32),
        .DATA_OUT_WIDTH (PIX_WIDTH )
    )
    weight_loader(
        .clk_i       (i_clk               ),
        .rst_i       (i_rst_n             ),
        .en_i        (weight_reader_en    ),
        .data_o      (weight_reader_data  ),
        .valid_o     (weight_reader_valid ),
        .data_i      (weight_bram_data    ),
        .bram_addr   (weight_bram_addr    ),
        .bram_en     (weight_bram_en      ),
        .bram_we     (weight_bram_we      )     
    );
    
    blk_mem_gen_1 weight_bram (
      .clka         (i_clk                ),
      .ena          (weight_bram_en       ),
      .wea          (weight_bram_we       ),
      .addra        (weight_bram_addr     ),
      .douta        (weight_bram_data     ) 
    );
   
    bram_reader #(
        .ADDRESS_WIDTH  (13),
        .DATA_IN_WIDTH  (32),
        .DATA_OUT_WIDTH (PIX_WIDTH )
    )
    feature_loader(
        .clk_i       (i_clk                ),
        .rst_i       (i_rst_n              ),
        .en_i        (feature_reader_en    ),
        .data_o      (feature_reader_data  ),
        .valid_o     (feature_reader_valid ),
        .data_i      (feature_bram_data    ),
        .bram_addr   (feature_bram_addr    ),
        .bram_en     (feature_bram_en      ),
        .bram_we     (feature_bram_we      )     
    );
    
    blk_mem_gen_1 feature_bram (
      .clka          (i_clk                ),
      .ena           (feature_bram_en       ),
      .wea           (feature_bram_we       ),
      .addra         (feature_bram_addr     ),
      .douta         (feature_bram_data     ) 
    );
    
    deconv_op_top #(
        .SIZE_OF_FEATURE        (SIZE_OF_FEATURE               ),                                                                      
        .SIZE_OF_WEIGHT         (SIZE_OF_WEIGHT                ),                                                                      
        .PIX_WIDTH              (PIX_WIDTH                     ),                                                                      
        .STRIDE                 (STRIDE                        ),                                                                      
        .N_PIX_IN               (SIZE_OF_FEATURE*SIZE_OF_WEIGHT),                                                     
        .STRB_WIDTH             (2*PIX_WIDTH*N_PIX_IN/4        ),                                                      
        .N_PIX_OUT              (SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1))         
    )
    deconv_op_top_inst_0 (
        .i_clk                  (i_clk                   ),
        .i_rst_n                (i_rst_n                 ),
        .i_weight_col           (op_top_weight_col       ),
        .i_feature_map_col      (op_top_feature_map_col  ),
        .en_prcs_new_chnl       (weight_fifo_flush       ), //change to the next channel of same kernel
        .en_prcs_new_wcoln      (op_top_weight_fifo_rd_en),
        .en_fifo_loop           (weight_fifo_loop        ),
        .i_enable_loadw         (op_top_enable_loadw     ), //load one col weight
        .i_enable_loadip        (op_top_enable_loadip    ), //load one col input
        .o_full_start           (op_top_full_start       ),
        .o_cmpl_deconv_col      (op_top_cmpl_deconv_col  ),   // output of the buffer
        .o_valid                (op_top_valid            ),    // indicate that output is valid for next process
        .o_init                 (op_top_init             )
    );
    
    assign weight_fifo_rd_en = op_top_weight_fifo_rd_en | weight_fifo_core_init;
    weight_fifo #(
         .PIX_WIDTH             (PIX_WIDTH  ),
         .SIZE_OF_WEIGHT        (SIZE_OF_WEIGHT),
         .N_OF_PIXELS           (SIZE_OF_WEIGHT*SIZE_OF_WEIGHT)
    )
    weight_fifo_inst_0 (
        .i_clk                  (i_clk                  ),                                                
        .i_rst_n                (i_rst_n                ),                                                
        .wr_en                  (weight_fifo_wr_en      ),                                                
        .rd_en                  (weight_fifo_rd_en      ),                                                
        .loop_back              (weight_fifo_loop       ),                                                
        .i_flush                (weight_fifo_flush      ),                                                
        .data_in                (weight_fifo_in         ),                                                
        .colw_data_out          (weight_fifo_out        ), //one column weight         
        .s_empty                (weight_fifo_empty      ),                                                
        .s_full                 (weight_fifo_full       ),      
        .s_pre_full             (weight_fifo_pre_full   ),                                          
        .col_export_done        (weight_fifo_export_done),                   //connect with i_enable signa
        .init                   (weight_fifo_core_init  ),
        .request_data	        (request_data           ),                                                     
        .flush_fin		        (flush_fin              ),                                                         
        .loop_fin               (loop_fin               )
    );

    loadip_buffer #(
        .DATA_WIDTH(PIX_WIDTH),
        .ADDR_WIDTH(8)
    )
    loadip_buffer_inst0(
    	.i_clk        (i_clk        ), 
    	.i_rst_n      (i_rst_n      ),
        // write side
        .o_wr_ready   (feature_wr_ready    ),  //done
        .i_wr_activate(feature_wr_activate & {2{feature_reader_valid}}),  //done
        .i_wdata      (feature_reader_data ),  //done
        .i_wstrobe    (feature_wr_strobe   ),  //done
        .wr_fifo_size (feature_wr_fifo_size),  //done
        .o_starved    (feauture_starved    ),  //done
        // read side                            
        .o_rd_ready   (feature_rd_ready    ),  //done
        .i_rd_activate(feature_rd_activate ),  //done
        .o_rdata      (feature_rd_data_pix),  //done
        .i_rstrobe    (feature_rd_strobe   ),  //done
        .o_rd_cnt     (feature_rd_cnt      ),  //done
        .o_inactivate (feature_inactivate  )   //done
    );

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
    /* After done, move logic bram reader*/
    // control 
    // feature_wr_activate  : based on feature_wr_ready
    // feature_wr_strobe    : based on feature_wr_ready & feature_wr_activate
    // feature_wr_data      : based on feature wr_active 
    // feature_wr_fifo_size : fixed
   
    integer wr_count;
    integer rd_count;
    assign feature_reader_en = feature_wr_activate!=0;
    assign feature_wr_data   = feature_reader_data   ;
    always @(posedge i_clk, negedge i_rst_n)
    begin
        feature_wr_strobe <= 1'b0   ;
        if (!i_rst_n)
        begin
            feature_wr_activate <= 2'b00;
            feature_wr_strobe   <= 1'b0 ;
            wr_count            <= 0;
        end
        else 
        begin
            if ( (feature_wr_ready!=2'b00) && (feature_wr_activate==2'b00) )
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
                    if (wr_count < feature_wr_fifo_size)
                    begin
//                        feature_wr_data   <= feature_reader_data;
                        feature_wr_strobe <= 1'b1   ;
                        wr_count          <= wr_count + 1;
                    end
                    else
                    begin
                        feature_wr_activate <= 2'b00;
                        wr_count <= 0;
                    end
                end
            end
        end
    end
    
    /* After done, move logic bram deconv_op_top*/
    // control
    // feature_rd_activate  : based on feature_rd_ready & feature_rd_cnt
    // feature_rd_strobe    : based on feature_rd_ready & feature_rd_activate
    // feature_rd_fifo_size : fixed
    reg save_read_ready;
    always @(posedge i_clk, i_rst_n)
    begin
        feature_rd_strobe <= 1'b0;
        if (!i_rst_n)
        begin
            feature_rd_strobe   <= 1'b0  ;
            feature_rd_activate <= 1'b0  ;
            rd_count            <= 15'd0 ; 
            op_top_enable_loadip <= 1'b0 ;
            op_top_feature_map_col <= 0  ;
            save_read_ready      <= 1'b0 ;
        end
        else
        begin
            if (feature_rd_ready && !feature_rd_activate)
            begin
                save_read_ready     <= 1'b1;
                feature_rd_activate <= 1'b1;
                feature_rd_strobe <= 1'b1;
            end
            else if (feature_rd_activate && save_read_ready)
            begin
                if (rd_count < feature_wr_fifo_size && save_read_ready)
                begin
                    rd_count <= rd_count + 1;
                    op_top_feature_map_col <= {op_top_feature_map_col, feature_rd_data_pix};
                    feature_rd_strobe <= 1'b1;
                end
                else
                begin
                    rd_count <= 0;
                    feature_rd_activate <= 1'b0;
                end
                
                if (rd_count % SIZE_OF_FEATURE == 1 && rd_count>0)
                begin
                    op_top_enable_loadip   <= 1'b1;
                    save_read_ready        <= 1'b0;
                end
            end
            else
            begin
                if (weight_fifo_export_done && feature_rd_cnt >0)
                begin
                    op_top_enable_loadip   <= 1'b1;
                end
                else 
                begin
                    op_top_enable_loadip <= 1'b0;
                    if (weight_fifo_loop)
                    begin
                        save_read_ready <= 1'b1;  
                        feature_rd_strobe <= 1'b1;  
                    end
                end
            end
        end
    end
    
endmodule
