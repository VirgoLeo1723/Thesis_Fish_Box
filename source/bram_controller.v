`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 08:21:59 PM
// Design Name: 
// Module Name: bram_controller
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 03:46:09 PM
// Design Name: 
// Module Name: bram_reader
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
module bram_controller #(
        parameter ADDRESS_WIDTH         = 13,
        parameter BRAM_DATA_WIDTH       = 32,
        parameter WRITER_DATA_IN_WIDTH  = 512,
        parameter READER_DATA_OUT_WIDTH = 8
    )(
        input                               clk_i        ,
        input                               rst_i        ,
        input                               rd_en_i      ,
        output                              rd_valid_o   ,
        output [READER_DATA_OUT_WIDTH-1:0]  rd_data_o    ,
       
        input                               wr_en_i      ,
        input                               wr_valid_i   ,
        input [WRITER_DATA_IN_WIDTH-1:0]    wr_data_i    ,
        output                              wr_finish_o  ,

    
        output [ADDRESS_WIDTH-1:0]          bram_addr    ,
        output                              bram_en      ,
        output                              bram_we      ,
        input  [BRAM_DATA_WIDTH-1:0]        bram_data_out,
        output [BRAM_DATA_WIDTH-1:0]        bram_data_in 
    );
    
    wire [ADDRESS_WIDTH-1:0]            rdr_bram_rd_addr;
    wire [BRAM_DATA_WIDTH-1:0]          rdr_bram_rd_data;
    wire [READER_DATA_OUT_WIDTH-1:0]    rdr_data_out;
    wire                                rdr_bram_en     ;
    wire                                rdr_bram_we     ;

    wire [ADDRESS_WIDTH-1:0]    wrt_bram_wr_addr;
    wire [BRAM_DATA_WIDTH-1:0]  wrt_bram_wr_data;
    wire                        wrt_bram_en     ;
    wire                        wrt_bram_we     ;
    
    assign rdr_bram_rd_data = bram_data_out;
    assign bram_addr        = rd_en_i ? rdr_bram_rd_addr : wr_en_i ? wrt_bram_wr_addr : {ADDRESS_WIDTH{1'b0}};
    assign bran_data_in     = wrt_bram_wr_data;
    assign bram_en          = (rdr_bram_en & rd_en_i) | (wrt_bram_en & wr_en_i);
    assign bram_we          = (rdr_bram_we & rd_en_i) | (wrt_bram_we & wr_en_i); 

    assign rd_data_o        = rdr_data_out    ;
    assign rd_valid_o       = rdr_valid       ;
    assign wrt_data_in      = wr_data_i       ;
    assign wrt_valid        = wr_valid_i      ;
    assign wr_finish_o      = wrt_finish      ;

    bram_reader #(
        .ADDRESS_WIDTH  (ADDRESS_WIDTH          ),
        .DATA_IN_WIDTH  (BRAM_DATA_WIDTH        ),
        .DATA_OUT_WIDTH (READER_DATA_OUT_WIDTH  )
    )bram_reader_inst(
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .en_i           (rd_en_i                ),
        .data_o         (rdr_data_out           ),
        .valid_o        (rdr_valid              ),
        .data_i         (rdr_bram_rd_data       ),
        .bram_addr      (rdr_bram_rd_addr       ),
        .bram_en        (rdr_bram_en            ),
        .bram_we        (rdr_bram_we            )
    );
    
    bram_writer #(
        .ADDRESS_WIDTH  (ADDRESS_WIDTH          ),
        .DATA_IN_WIDTH  (WRITER_DATA_IN_WIDTH   ),
        .DATA_OUT_WIDTH (BRAM_DATA_WIDTH        )
    )bram_writer_inst(
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .en_i           (wr_en_i                ),
        .valid_i        (wrt_valid              ),
        .data_i         (wrt_data_in            ),
        .data_o         (wrt_bram_wr_data       ),
        .finish_o       (wrt_finish             ),
        .bram_addr      (wrt_bram_wr_addr       ),
        .bram_en        (wrt_bram_en            ),
        .bram_we        (wrt_bram_we            )
    );
endmodule

