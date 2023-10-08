`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/16/2023 05:01:06 PM
// Design Name: 
// Module Name: fish_box_core
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


module fish_box_core #(
    BEGIN_READ_BIT     = 0,
    DONE_OPERATION_BIT = 0,
    PIXEL_WIDTH        = 32
)(
    input               i_clk           ,
    input               i_rst           ,
    // input for parameter 
    input       [31:0]  i_kernel_width  ,
    input       [31:0]  i_kernel_height ,
    input       [31:0]  i_kernel_channel,
    // i/o for control and status
    input       [31:0]  i_control_signal,
    output reg  [31:0]  o_status_signal ,
    output reg  [31:0]  o_test_sum      ,
    output reg  [31:0]  dbg_bram_data   ,
    output reg  [31:0]  dbg_bram_addr   ,
    output reg          dbg_bram_en     ,
    output reg          dbg_bram_rd_valid,
    output reg  [31:0]  dbg_bram_rd_data,

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 EN" *)
    output                           bram_en_0, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 DOUT" *)
    input [31 : 0]                   bram_dout_0, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 DIN" *)
    output [31 : 0]                  bram_din_0, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 WE" *)
    output [3 : 0]                   bram_we_0, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 ADDR" *)
    output [31 : 0] bram_addr_0, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 CLK" *)
    output                           bram_clk_0, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_0 RST" *)
    output                           bram_rst_0, // Reset Signal (required)
    
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 EN" *)
    output                           bram_en_1, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 DOUT" *)
    input [31 : 0]                 bram_dout_1, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 DIN" *)
    output [31 : 0]                  bram_din_1, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 WE" *)
    output [3 : 0]                   bram_we_1, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 ADDR" *)
    output [31 : 0] bram_addr_1, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 CLK" *)
    output                           bram_clk_1, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_1 RST" *)
    output                           bram_rst_1, // Reset Signal (required)
    
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 EN" *)
    output                           bram_en_2, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 DOUT" *)
    input [31 : 0]                 bram_dout_2, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 DIN" *)
    output [31 : 0]                  bram_din_2, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 WE" *)
    output [3 : 0]                   bram_we_2, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 ADDR" *)
    output [31 : 0]                  bram_addr_2, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 CLK" *)
    output                           bram_clk_2, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_2 RST" *)
    output                           bram_rst_2, // Reset Signal (required)
    
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 EN" *)
    output                           bram_en_3, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 DOUT" *)
    input [31 : 0]                 bram_dout_3, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 DIN" *)
    output [31 : 0]                  bram_din_3, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 WE" *)
    output [3 : 0]                   bram_we_3, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 ADDR" *)
    output [31 : 0]                  bram_addr_3, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 CLK" *)
    output                           bram_clk_3, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DATA_BRAM_PORT_3 RST" *)
    output                           bram_rst_3, // Reset Signal (required)
    
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 EN" *)
    output                           bram_en_4, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 DOUT" *)
    input [31 : 0]                 bram_dout_4, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 DIN" *)
    output [31 : 0]                  bram_din_4, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 WE" *)
    output [3 : 0]                   bram_we_4, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 ADDR" *)
    output [31 : 0]                  bram_addr_4, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 CLK" *)
    output                           bram_clk_4, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 WEIGHT_BRAM_PORT_0 RST" *)
    output                           bram_rst_4 // Reset Signal (required)
    );

    wire [3:0]  bram_data_valid;    
    wire [7:0]  data_out[4:0];
    
    // LOCAL parameter
    integer KERNEL_WIDTH  ;
    integer KERNEL_HEIGHT ;
    integer KERNEL_CHANNEL;
    
    assign bram_clk_0 = i_clk;
    assign bram_clk_1 = i_clk;
    assign bram_clk_2 = i_clk;
    assign bram_clk_3 = i_clk;
    
    bram_reader #(.DATA_OUT_WIDTH(16))data_reader_0 (
        .clk_i     (i_clk),
        .rst_i     (i_rst),
        .en_i      (i_control_signal[BEGIN_READ_BIT]),
        .data_i    (bram_dout_0),
        .data_o    (data_out[0]),
        .valid_o   (bram_data_valid[0]),
        .bram_addr (bram_addr_0),
        .bram_en   (bram_en_0),
        .bram_we   (bram_we_0)     
    ); 
    bram_reader #(.DATA_OUT_WIDTH(16))data_reader_1 (
        .clk_i     (i_clk),
        .rst_i     (i_rst),
        .en_i      (i_control_signal[BEGIN_READ_BIT]),
        .data_i    (bram_dout_1),
        .data_o    (data_out[1]),
        .valid_o   (bram_data_valid[1]),
        .bram_addr (bram_addr_1),
        .bram_en   (bram_en_1),
        .bram_we   (bram_we_1)       
    ); 
    bram_reader #(.DATA_OUT_WIDTH(16))data_reader_2 (
        .clk_i     (i_clk),
        .rst_i     (i_rst),
        .en_i      (i_control_signal[BEGIN_READ_BIT]),
        .data_i    (bram_dout_2),
        .data_o    (data_out[2]),
        .valid_o   (bram_data_valid[2]),
        .bram_addr (bram_addr_2),
        .bram_en   (bram_en_2),
        .bram_we   (bram_we_2)       
    ); 
    bram_reader #(.DATA_OUT_WIDTH(16)) data_reader_3 (
        .clk_i     (i_clk),
        .rst_i     (i_rst),
        .en_i      (i_control_signal[BEGIN_READ_BIT]),
        .data_i    (bram_dout_3),
        .data_o    (data_out[3]),
        .valid_o   (bram_data_valid[3]),
        .bram_addr (bram_addr_3),
        .bram_en   (bram_en_3),
        .bram_we   (bram_we_3)       
    );   
    bram_reader weight_reader_0 (
        .clk_i     (i_clk),
        .rst_i     (i_rst),
        .en_i      (i_control_signal[BEGIN_READ_BIT]),
        .data_i    (bram_dout_4),
        .data_o    (data_out[4]),
        .valid_o   (bram_data_valid[4]),
        .bram_addr (bram_addr_4),
        .bram_en   (bram_en_4),  
        .bram_we   (bram_we_4)   
    ); 
    
    integer valid_count =0;
    integer test_sum = 0;
    
    always @(posedge i_clk, negedge i_rst)
    begin
        if (!i_rst)
        begin
            valid_count <= 0;
            o_status_signal[0] <= 1'b0;
        end
        else
        begin
            if (i_control_signal[0]==1'b1)
            begin
                o_status_signal[0] <= bram_data_valid[0];
                o_test_sum <= bram_dout_0;
            end
            else
            begin
                o_status_signal[0] <= 0;
                o_test_sum <= 0;
            end
        end
    end
    
    // save parameter configuration
    always @(posedge i_clk, negedge i_rst)
    begin
        if (!i_rst)
        begin
            KERNEL_WIDTH    <= 0;
            KERNEL_HEIGHT   <= 0;
            KERNEL_CHANNEL  <= 0;
        end
        else   
        begin
            KERNEL_WIDTH    <= i_kernel_width;
            KERNEL_HEIGHT   <= i_kernel_height;
            KERNEL_CHANNEL  <= i_kernel_channel;
            dbg_bram_data   <= bram_dout_0;
            dbg_bram_addr   <= bram_addr_0;
            dbg_bram_en     <= bram_en_0  ;
            dbg_bram_rd_valid <= bram_data_valid;
            dbg_bram_rd_data  <= data_out[0];
        end
    end
   
endmodule
