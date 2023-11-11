`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 10:08:56 PM
// Design Name: 
// Module Name: deconv_multi_kernel_tb
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


module deconv_multi_kernel_tb(

    );
    parameter SIZE_OF_GATHER_RESULT = 512;
    parameter DATA_IN_WIDTH     = 512;                                                                          
    parameter BRAM_DATA_WIDTH   = 32 ;                                                                          
    parameter ADDRESS_WIDTH     = 13 ;                                                                          
    parameter SIZE_OF_FEATURE   = 2  ;                                                                          
    parameter SIZE_OF_WEIGHT    = 3  ;                                                                          
    parameter PIX_WIDTH         = 16 ;                                                                          
    parameter STRIDE            = 1  ;                                                                          
    parameter N_PIX_IN          = SIZE_OF_FEATURE*SIZE_OF_WEIGHT;                                            
    parameter STRB_WIDTH        = 2*PIX_WIDTH*N_PIX_IN/4 ;                                                      
    parameter N_PIX_OUT         = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1)  ;
                                
    wire                                 feature_reader_en      ;
    wire                                 feature_reader_valid   ;
    wire [PIX_WIDTH-1:0]                 feature_reader_data_out;
    wire                                 feature_writer_en      ;
    wire                                 feature_writer_valid   ;
    wire                                 feature_writer_finish  ;
    wire [SIZE_OF_GATHER_RESULT-1:0]     feature_writer_data_in ;
    wire [ADDRESS_WIDTH-1:0]             feature_bram_addr      ;      
    wire                                 feature_bram_en        ;
    wire                                 feature_bram_we        ;
    wire [BRAM_DATA_WIDTH-1:0]           feature_bram_data_out  ;
    wire [BRAM_DATA_WIDTH-1:0]           feature_bram_data_in   ;                            
                                
    wire                                 weight_reader_en       ;
    wire                                 weight_reader_valid    ;
    wire [PIX_WIDTH-1:0]                 weight_reader_data_out ;
    wire                                 weight_writer_finish   ;

    
    reg i_clk;
    reg i_rst_n;
    
    initial
    begin
        i_clk = 1'b0;
        forever #1 i_clk = ~i_clk;
    end
    
    initial 
    begin
        i_rst_n = 1'b0;
        #2  i_rst_n = 1'b1;
    end
    
    blk_mem_gen_1 weight_bram (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       ),
        .wea          (weight_bram_we       ),
        .addra        (weight_bram_addr     ),
        .douta        (weight_bram_data_out ) 
    );
       
    blk_mem_gen_1 feature_bram (
      .clka          (i_clk                 ),
      .ena           (feature_bram_en       ),
      .wea           (feature_bram_we       ),
      .addra         (feature_bram_addr     ),
      .dina          (feature_bram_data_in  ), 
      .douta         (feature_bram_data_out ) 
    );
           
    deconv_multi_kernel #(
        .DATA_IN_WIDTH          (DATA_IN_WIDTH                             ),
        .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                           ),
        .ADDRESS_WIDTH          (ADDRESS_WIDTH                             ),
        .SIZE_OF_FEATURE        (SIZE_OF_FEATURE                           ),                                                                  
        .SIZE_OF_WEIGHT         (SIZE_OF_WEIGHT                            ),                                                                      
        .PIX_WIDTH              (PIX_WIDTH                                 ),                                                                      
        .STRIDE                 (STRIDE                                    ),                                                                     
        .N_PIX_IN               (SIZE_OF_FEATURE*SIZE_OF_WEIGHT            ),                                                     
        .STRB_WIDTH             (2*PIX_WIDTH*N_PIX_IN/4                    ),                                               
        .N_PIX_OUT              (SIZE_OF_FEATURE*SIZE_OF_WEIGHT -
                                (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1)) 
    )deconv_multi_kernel_0  (
        .i_clk                  (i_clk                                     ),
        .i_rst_n                (i_rst_n                                   ),
        .weight_reader_data_out (weight_reader_data_out                    ),
        .weight_reader_valid    (weight_reader_valid                       ),
        .weight_reader_en       (weight_reader_en                          ),        
        .feature_reader_data_out(feature_reader_data_out                   ),
        .feature_reader_valid   (feature_reader_valid                      ),
        .feature_reader_en      (feature_reader_en                         )   
    );    

    bram_controller #(
        .ADDRESS_WIDTH          (ADDRESS_WIDTH           ),
        .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH         ),
        .WRITER_DATA_IN_WIDTH   (BRAM_DATA_WIDTH         ),
        .READER_DATA_OUT_WIDTH  (PIX_WIDTH               )  
    ) weight_bram_controller (
        .clk_i                  (i_clk                  ),
        .rst_i                  (i_rst_n                ),
        .rd_en_i                (weight_reader_en       ),
        .wr_en_i                (1'b0                   ),
        .wr_valid_i             (1'b0                   ),
        .wr_data_i              ({DATA_IN_WIDTH{1'b0}}  ),
        .wr_finish_o            (weight_writer_finish   ),
        .rd_valid_o             (weight_reader_valid    ),
        .rd_data_o              (weight_reader_data_out ),
        .bram_addr              (weight_bram_addr       ),
        .bram_en                (weight_bram_en         ),
        .bram_we                (weight_bram_we         ),
        .bram_data_out          (weight_bram_data_out   ),
        .bram_data_in           (weight_bram_data_in    )
    );
    
    bram_controller #(
        .ADDRESS_WIDTH          (ADDRESS_WIDTH          ), 
        .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH        ), 
        .WRITER_DATA_IN_WIDTH   (DATA_IN_WIDTH          ), 
        .READER_DATA_OUT_WIDTH  (PIX_WIDTH              ) 
    ) feature_bram_controller (
        .clk_i                  (i_clk                  ),
        .rst_i                  (i_rst_n                ),    
        .rd_en_i                (feature_reader_en      ),    
        .wr_en_i                (1'b0                   ),    
        .wr_valid_i             (feature_writer_valid   ),    
        .wr_data_i              (feature_writer_data_in ),    
        .wr_finish_o            (feature_writer_finish  ),    
        .rd_valid_o             (feature_reader_valid   ),    
        .rd_data_o              (feature_reader_data_out),    
        .bram_addr              (feature_bram_addr      ),    
        .bram_en                (feature_bram_en        ),    
        .bram_we                (feature_bram_we        ),    
        .bram_data_out          (feature_bram_data_out  ),    
        .bram_data_in           (feature_bram_data_in   )    
    );
endmodule
