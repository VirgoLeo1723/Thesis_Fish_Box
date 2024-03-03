`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2023 11:20:34 AM
// Design Name: 
// Module Name: deconv_core_top
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
//(* keep_hierarchy = "yes" *)  
module deconv_core_top#(
    parameter SIZE_OF_GATHER_RESULT      = 512,
    parameter DATA_IN_WIDTH              = 512,                                                                          
    parameter BRAM_DATA_WIDTH            = 32 ,                                                                          
    parameter ADDRESS_WIDTH              = 15 ,                                                                          
    parameter SIZE_OF_FEATURE            = 4  ,                                                                          
    parameter SIZE_OF_WEIGHT             = 3  ,                                                                          
    parameter PIX_WIDTH                  = 8 ,                                                                          
    parameter STRIDE                     = 1  ,
    parameter NUM_OF_CHANNEL_EACH_WEIGHT = 4  ,
    parameter NUM_OF_WEIGHT              = 16 
    )(
        // general io
        input                           i_clk                    ,
        input                           i_rst_n                  ,
        
        // configuration space interface
        input  [31:0]                   i_param_cfg_feature      , 
        input  [31:0]                   i_param_cfg_weight       ,
        input  [31:0]                   i_param_cfg_output       ,  
        input  [31:0]                   i_control_signal         ,
        output [31:0]                   o_status_signal          ,

        // Bram interface
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 EN" *)
        input                          weight_bram_en_0, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   weight_bram_data_out_0, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    weight_bram_data_in_0, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 WE" *)
        input [3 : 0]                  weight_bram_we_0, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    weight_bram_addr_0, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 CLK" *)
        input                          weight_bram_clk_0, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 RST" *)
        input                          weight_bram_rst_0, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 EN" *)
        input                          weight_bram_en_1, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   weight_bram_data_out_1, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    weight_bram_data_in_1, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 WE" *)
        input [3 : 0]                  weight_bram_we_1, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    weight_bram_addr_1, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 CLK" *)
        input                          weight_bram_clk_1, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_1 RST" *)
        input                          weight_bram_rst_1, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 EN" *)
        input                          weight_bram_en_2, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   weight_bram_data_out_2, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    weight_bram_data_in_2, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 WE" *)
        input [3 : 0]                  weight_bram_we_2, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    weight_bram_addr_2, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 CLK" *)
        input                          weight_bram_clk_2, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_2 RST" *)
        input                          weight_bram_rst_2, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 EN" *)
        input                          weight_bram_en_3, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   weight_bram_data_out_3, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    weight_bram_data_in_3, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 WE" *)
        input [3 : 0]                  weight_bram_we_3, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    weight_bram_addr_3, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 CLK" *)
        input                          weight_bram_clk_3, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_3 RST" *)
        input                          weight_bram_rst_3, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 EN" *)
        input                          feature_bram_en_0, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   feature_bram_data_out_0, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]   feature_bram_data_in_0, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 WE" *)
        input [3 : 0]                  feature_bram_we_0, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    feature_bram_addr_0, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 CLK" *)
        input                          feature_bram_clk_0, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 RST" *)
        input                          feature_bram_rst_0, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 EN" *)
        input                          feature_bram_en_1, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   feature_bram_data_out_1, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    feature_bram_data_in_1, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 WE" *)
        input [3 : 0]                  feature_bram_we_1, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    feature_bram_addr_1, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 CLK" *)
        input                          feature_bram_clk_1, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 RST" *)
        input                          feature_bram_rst_1, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 EN" *)
        input                          feature_bram_en_2, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   feature_bram_data_out_2, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 DIN" *)
        output [BRAM_DATA_WIDTH-1: 0]    feature_bram_data_in_2, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 WE" *)
        input [3 : 0]                  feature_bram_we_2, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    feature_bram_addr_2, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 CLK" *)
        input                          feature_bram_clk_2, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 RST" *)
        input                          feature_bram_rst_2, // Reset Signal (required)
        
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 EN" *)
        input                          feature_bram_en_3, // Chip Enable Signal (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 DOUT" *)
        output [BRAM_DATA_WIDTH-1 : 0]   feature_bram_data_out_3, // Data Out Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 DIN" *)
        input [BRAM_DATA_WIDTH-1: 0]    feature_bram_data_in_3, // Data In Bus (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 WE" *)
        input [3 : 0]                  feature_bram_we_3, // Byte Enables (optional)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 ADDR" *)
        input [ADDRESS_WIDTH-1 : 0]    feature_bram_addr_3, // Address Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 CLK" *)
        input                          feature_bram_clk_3, // Clock Signal (required)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 RST" *)
        input                          feature_bram_rst_3 // Reset Signal (required)      
    );
    //localparam N_PIX_IN                     = SIZE_OF_FEATURE*SIZE_OF_WEIGHT;                                            
    //localparam STRB_WIDTH                   = 2*PIX_WIDTH*N_PIX_IN/4 ;                                                      
    //localparam N_PIX_OUT                    = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
    //                                          (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1);
    localparam NON_OVERLAPPED_CONST         = (SIZE_OF_FEATURE/2) * STRIDE;
    localparam SIZE_OF_PRSC_INPUT           = STRIDE* (SIZE_OF_FEATURE/2-1) + SIZE_OF_WEIGHT;
    localparam SIZE_OF_PRSC_OUTPUT          = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST);
    
    wire [ADDRESS_WIDTH-1:0]                        feature_bram_addr     [0:3]     ;      
    wire [3:0]                                      feature_bram_en                 ;
    wire [3:0]                                      feature_bram_we                 ;
    wire [BRAM_DATA_WIDTH-1:0]                      feature_bram_data_out [0:3]     ;
    wire [BRAM_DATA_WIDTH-1:0]                      feature_bram_data_in  [0:3]     ;      

    wire [ADDRESS_WIDTH-1:0]                        weight_bram_addr      [0:3]     ;      
    wire [3:0]                                      weight_bram_en                  ;
    wire [3:0]                                      weight_bram_we                  ;
    wire [BRAM_DATA_WIDTH-1:0]                      weight_bram_data_out  [0:3]     ;
    wire [3:0]                                      weight_writer_finish            ;
    wire [BRAM_DATA_WIDTH-1:0]                      weight_bram_data_in   [0:3]     ;
    
    wire [3:0]                                      weight_reader_en                ;       
    wire [3:0]                                      weight_reader_valid             ;    
    wire [PIX_WIDTH*4-1:0]                          weight_reader_data_out          ; 
    wire [3:0]                                      feature_reader_en               ;      
    wire [3:0]                                      feature_reader_valid            ;   
    wire [PIX_WIDTH*4-1:0]                          feature_reader_data_out         ;
    wire [3:0]                                      feature_writer_en               ;
    wire [3:0]                                      feature_writer_valid            ;   
    wire [(SIZE_OF_PRSC_OUTPUT**2)*2*PIX_WIDTH-1:0] feature_writer_data_in          ; 
    wire [3:0]                                      feature_writer_finish           ;
    wire [3:0]                                      feature_writer_transfer_ready   ;
   
    wire                                            deconv_core_enable              ;
    reg                                             deconv_core_finish              ;
    
    assign deconv_core_enable = i_control_signal[0];
    assign o_status_signal[0] = {{31{1'b0}},deconv_core_finish} ;
    
    assign feature_bram_clk_0       = i_clk; 
    assign feature_bram_clk_1       = i_clk; 
    assign feature_bram_clk_2       = i_clk; 
    assign feature_bram_clk_3       = i_clk; 
    assign weight_bram_clk_0        = i_clk; 
    assign weight_bram_clk_1        = i_clk; 
    assign weight_bram_clk_2        = i_clk; 
    assign weight_bram_clk_3        = i_clk;
    assign feature_bram_rst_0       = i_rst_n;
    assign feature_bram_rst_1       = i_rst_n;
    assign feature_bram_rst_2       = i_rst_n;
    assign feature_bram_rst_3       = i_rst_n;
    assign weight_bram_rst_0        = i_rst_n;
    assign weight_bram_rst_1        = i_rst_n;
    assign weight_bram_rst_2        = i_rst_n;
    assign weight_bram_rst_3        = i_rst_n;
     

    assign feature_bram_addr[0]     = feature_bram_addr_0       ;
    assign feature_bram_addr[1]     = feature_bram_addr_1       ;
    assign feature_bram_addr[2]     = feature_bram_addr_2       ;
    assign feature_bram_addr[3]     = feature_bram_addr_3       ;
    assign feature_bram_en[0]       = feature_bram_en_0         ;
    assign feature_bram_en[1]       = feature_bram_en_1         ;
    assign feature_bram_en[2]       = feature_bram_en_2         ;
    assign feature_bram_en[3]       = feature_bram_en_3         ;
    assign feature_bram_we[0]       = feature_bram_we_0         ;
    assign feature_bram_we[1]       = feature_bram_we_1         ;
    assign feature_bram_we[2]       = feature_bram_we_2         ;
    assign feature_bram_we[3]       = feature_bram_we_3         ;
    assign feature_bram_data_out_0  = feature_bram_data_out[0]  ;
    assign feature_bram_data_out_1  = feature_bram_data_out[1]  ;
    assign feature_bram_data_out_2  = feature_bram_data_out[2]  ;
    assign feature_bram_data_out_3  = feature_bram_data_out[3]  ;
    assign feature_bram_data_in[0]  = feature_bram_data_in_0    ;
    assign feature_bram_data_in[1]  = feature_bram_data_in_1    ;
    assign feature_bram_data_in[2]  = feature_bram_data_in_2    ;
    assign feature_bram_data_in[3]  = feature_bram_data_in_3    ;
    
    assign weight_bram_addr[0]      = weight_bram_addr_0        ;
    assign weight_bram_addr[1]      = weight_bram_addr_1        ;
    assign weight_bram_addr[2]      = weight_bram_addr_2        ;
    assign weight_bram_addr[3]      = weight_bram_addr_3        ;
    assign weight_bram_en[0]        = weight_bram_en_0          ;
    assign weight_bram_en[1]        = weight_bram_en_1          ;
    assign weight_bram_en[2]        = weight_bram_en_2          ;
    assign weight_bram_en[3]        = weight_bram_en_3          ;
    assign weight_bram_we[0]        = weight_bram_we_0          ;
    assign weight_bram_we[1]        = weight_bram_we_1          ;
    assign weight_bram_we[2]        = weight_bram_we_2          ;
    assign weight_bram_we[3]        = weight_bram_we_3          ;
    assign weight_bram_data_out_0   = weight_bram_data_out[0]   ;
    assign weight_bram_data_out_1   = weight_bram_data_out[1]   ;
    assign weight_bram_data_out_2   = weight_bram_data_out[2]   ;
    assign weight_bram_data_out_3   = weight_bram_data_out[3]   ;
    assign weight_bram_data_in[0]   = weight_bram_data_in_0     ;
    assign weight_bram_data_in[1]   = weight_bram_data_in_1     ;
    assign weight_bram_data_in[2]   = weight_bram_data_in_2     ;
    assign weight_bram_data_in[3]   = weight_bram_data_in_3     ;      
    
    deconv_core#(
        .SIZE_OF_GATHER_RESULT          (SIZE_OF_GATHER_RESULT          ),
        .BRAM_DATA_WIDTH                (BRAM_DATA_WIDTH                ),                                                                         
        .ADDRESS_WIDTH                  (ADDRESS_WIDTH                  ),                                                                         
        .SIZE_OF_FEATURE                (SIZE_OF_FEATURE                ),                                                                         
        .SIZE_OF_WEIGHT                 (SIZE_OF_WEIGHT                 ),                                                                         
        .PIX_WIDTH                      (PIX_WIDTH                      ),                                                                         
        .STRIDE                         (STRIDE                         ),
        .NUM_OF_CHANNEL_EACH_WEIGHT     (NUM_OF_CHANNEL_EACH_WEIGHT     )                                                                
    )deconv_core_inst(
        .i_clk                          (i_clk                          ),
        .i_rst_n                        (i_rst_n                        ),
        .i_enable                       (deconv_core_enable             ),
        .i_param_cfg_feature            (i_param_cfg_feature            ),
        .i_param_cfg_weight             (i_param_cfg_weight             ),
        .i_param_cfg_output             (i_param_cfg_output             ),
        .weight_reader_en               (weight_reader_en               ),
        .weight_reader_valid            (weight_reader_valid            ),
        .weight_reader_data_out         (weight_reader_data_out         ),
        .feature_reader_en              (feature_reader_en              ),
        .feature_reader_valid           (feature_reader_valid           ),
        .feature_reader_data_out        (feature_reader_data_out        ),
        .feature_writer_en              (feature_writer_en              ),
        .feature_writer_valid           (feature_writer_valid           ),
        .feature_writer_transfer_ready  (feature_writer_transfer_ready  ),
        .feature_writer_data_in         (feature_writer_data_in         ),
        .feature_writer_finish          (feature_writer_finish          )
    );
    
    genvar weight_bram_index;
    generate 
        for (weight_bram_index=0; weight_bram_index<4; weight_bram_index = weight_bram_index+1)
        begin: weight_bram_controller_set
            wire                        ctrl_weight_bram_en         ;
            wire                        ctrl_weight_bram_we         ; 
            wire [ADDRESS_WIDTH-1:0]    ctrl_weight_bram_addr       ;
            wire [BRAM_DATA_WIDTH-1:0]  ctrl_weight_bram_data_in    ;
            wire [BRAM_DATA_WIDTH-1:0]  ctrl_weight_bram_data_out   ; 
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                                  ),
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                                ),
                .WRITER_DATA_IN_WIDTH   (BRAM_DATA_WIDTH                                ),
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                      )  
            ) weight_bram_controller (
                .clk_i                  (i_clk                                          ),
                .rst_i                  (i_rst_n                                        ),
                .rd_en_i                (weight_reader_en[weight_bram_index]            ),
                .wr_en_i                (1'b0                                           ),
                .wr_valid_i             (1'b0                                           ),
                .wr_data_i              (32'b0                                          ),
                .i_param_cfg_output     (i_param_cfg_output                             ),
                .wr_finish_o            (weight_writer_finish[weight_bram_index]        ),
                .rd_valid_o             (weight_reader_valid[weight_bram_index]         ),
                .rd_data_o              (weight_reader_data_out [weight_bram_index*PIX_WIDTH+:PIX_WIDTH]),
                .bram_en                (ctrl_weight_bram_en                            ),
                .bram_we                (ctrl_weight_bram_we                            ),
                .bram_addr              (ctrl_weight_bram_addr                          ),
                .bram_data_in           (ctrl_weight_bram_data_in                       ),
                .bram_data_out          (ctrl_weight_bram_data_out                      )
            );
            blk_mem_gen_1 weight_bram (
                .clka                   (i_clk                                          ), 
                .ena                    (weight_bram_en              [weight_bram_index]), 
                .wea                    (weight_bram_we              [weight_bram_index]), 
                .addra                  (weight_bram_addr            [weight_bram_index]), 
                .dina                   (weight_bram_data_in         [weight_bram_index]), 
                .douta                  (weight_bram_data_out        [weight_bram_index]), 
                .clkb                   (i_clk                                          ),
                .enb                    (ctrl_weight_bram_en                            ), 
                .web                    (ctrl_weight_bram_we                            ), 
                .addrb                  (ctrl_weight_bram_addr                          ), 
                .dinb                   (ctrl_weight_bram_data_in                       ), 
                .doutb                  (ctrl_weight_bram_data_out                      )  
            );
        end
    endgenerate      
      
    genvar feature_bram_index;
    generate
        for (feature_bram_index=0; feature_bram_index < 4; feature_bram_index = feature_bram_index + 1)
        begin:  feature_bram_controller_set
            wire                        ctrl_feature_bram_en         ;
            wire                        ctrl_feature_bram_we         ; 
            wire [ADDRESS_WIDTH-1:0]    ctrl_feature_bram_addr       ;
            wire [BRAM_DATA_WIDTH-1:0]  ctrl_feature_bram_data_in    ;
            wire [BRAM_DATA_WIDTH-1:0]  ctrl_feature_bram_data_out   ; 
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                                      ), 
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                                    ), 
                .WRITER_DATA_IN_WIDTH   (((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH           ), 
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                          ) 
            ) feature_bram_controller (
                .clk_i                  (i_clk                                              ),
                .rst_i                  (i_rst_n                                            ),    
                .rd_en_i                (feature_reader_en             [feature_bram_index] ),    
                .wr_en_i                (feature_writer_en             [feature_bram_index] ),    
                .wr_valid_i             (feature_writer_valid          [feature_bram_index] ),    
                .wr_ready_i             (feature_writer_transfer_ready [feature_bram_index] ),
                .wr_data_i              (feature_writer_data_in        [feature_bram_index*((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH+:((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH]),    
                .i_param_cfg_output     (i_param_cfg_output                                 ),
                .wr_finish_o            (feature_writer_finish         [feature_bram_index] ),    
                .rd_valid_o             (feature_reader_valid          [feature_bram_index] ),    
                .rd_data_o              (feature_reader_data_out       [feature_bram_index*PIX_WIDTH+:PIX_WIDTH]),    
                .bram_en                (ctrl_feature_bram_en                               ),    
                .bram_we                (ctrl_feature_bram_we                               ),    
                .bram_addr              (ctrl_feature_bram_addr                             ),    
                .bram_data_in           (ctrl_feature_bram_data_in                          ),  
                .bram_data_out          (ctrl_feature_bram_data_out                         )    
            );          
            blk_mem_gen_1 feature_bram (
                .clka                   (i_clk                                              ), 
                .ena                    (feature_bram_en              [feature_bram_index]  ), 
                .wea                    (feature_bram_we              [feature_bram_index]  ), 
                .addra                  (feature_bram_addr            [feature_bram_index]  ), 
                .dina                   (feature_bram_data_in         [feature_bram_index]  ), 
                .douta                  (feature_bram_data_out        [feature_bram_index]  ), 
                .clkb                   (i_clk                                              ),
                .enb                    (ctrl_feature_bram_en                               ), 
                .web                    (ctrl_feature_bram_we                               ), 
                .addrb                  (ctrl_feature_bram_addr                             ), 
                .dinb                   (ctrl_feature_bram_data_in                          ), 
                .doutb                  (ctrl_feature_bram_data_out                         )  
            );
        end
    endgenerate 
    
    
    // Collect weight
    integer col_each_weight_channel;
    integer weight_channel_counter ;
    integer weight_kernel_counter;
    always @(posedge i_clk, negedge i_rst_n)
    begin
        if (!i_rst_n)
        begin
            col_each_weight_channel <= 0;
            weight_channel_counter  <= 0;
            weight_kernel_counter   <= 0;
        end
        else
        begin
            if (|weight_reader_valid)
            begin
                col_each_weight_channel <= col_each_weight_channel + 1;
            end 
            
            if (col_each_weight_channel == `WEIGHT_SIZE**2) 
            begin 
                col_each_weight_channel = 0;
                weight_channel_counter <=weight_channel_counter + 1;
                if (weight_channel_counter == `NUMBER_OF_WEIGHT)
                begin
                    weight_kernel_counter  <= weight_kernel_counter + 1;
                    weight_channel_counter <= 0;
                end
            end
            if (weight_kernel_counter == `NUMBER_OF_WEIGHT)
            begin
                col_each_weight_channel <= 0;
                weight_channel_counter  <= 0;
                weight_kernel_counter   <= 0;
                deconv_core_finish                <= 1'b1;
            end
            else
            begin
                deconv_core_finish                <= 1'b0;
            end
        end
    end   
endmodule

