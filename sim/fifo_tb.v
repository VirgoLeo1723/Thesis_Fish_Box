`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2023 02:07:14 PM
// Design Name: 
// Module Name: fifo_tb
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


`timescale 1ns/1ps

`define CLK_HALF_PERIOD 10
`define CLK_PERIOD (2 * `CLK_HALF_PERIOD)

`define SLEEP_HALF_CLK #(`CLK_HALF_PERIOD)
`define SLEEP_FULL_CLK #(`CLK_PERIOD)

//Sleep a number of clock cycles
`define SLEEP_CLK(x)  #(x * `CLK_PERIOD)

`define RD_CLK_HALF_PERIOD 10
`define RD_CLK_PERIOD (2 * `RD_CLK_HALF_PERIOD)



module tb_ppfifo (
);
//local parameters
localparam      DATA_WIDTH  = 32;  //32-bit data
localparam      ADDR_WIDTH  = 4;   //2 ** 4 = 16 positions

//registes/wires
reg   clk       = 0;
reg   rd_clk    = 0;

reg   rst       = 0;


//write side
wire        [1:0]                 write_ready;
wire        [1:0]                 write_activate;
  wire        [15:0]                write_fifo_size;
wire                              write_strobe;
wire        [DATA_WIDTH - 1: 0]   write_data;
wire                              starved;

//read side
wire                              read_strobe;
wire                              read_ready;
wire                              read_activate;
  wire        [15:0]                read_count;
wire        [DATA_WIDTH - 1: 0]   read_data;

wire                              inactive;



//submodules

//Write Side
src_tb #(
  .DATA_WIDTH                       (DATA_WIDTH         )
) source (
  .clk                              (clk                ),
  .rst                              (rst                ),
  .i_enable                         (1'b1               ),

  //Ping Pong FIFO Interface
  .i_wr_rdy                         (write_ready        ),
  .o_wr_act                         (write_activate     ),
  .i_wr_size                        (write_fifo_size    ),
  .o_wr_stb                         (write_strobe       ),
  .o_wr_data                        (write_data         )
);

//PPFIFO
loadip_buffer #(
  .DATA_WIDTH                       (DATA_WIDTH         ),
  .ADDR_WIDTH                    (ADDR_WIDTH         )
) f (

  //universal input
  .i_rst_n                            (rst                ),

  //write side
  .i_clk                      (clk                ),
  .o_wr_ready                       (write_ready        ),
  .i_wr_activate                   (write_activate     ),
  .wr_fifo_size                  (write_fifo_size    ),
  .i_wstrobe                     (write_strobe       ),
  .i_wdata                       (write_data         ),
  .o_starved                          (starved            ),

  //read side
  //.read_clock                       (rd_clk             ),
  .i_rstrobe                      (read_strobe        ),
  .o_rd_ready                       (read_ready         ),
  .i_rd_activate                    (read_activate      ),
  .o_rd_cnt                       (read_count         ),
  .o_rdata                        (read_data          ),

  .o_inactivate                         (inactive           )
);

//Read Side
 sink_tb #(
   .DATA_WIDTH                       (DATA_WIDTH         )
 ) sink (
   .clk                              (rd_clk             ),
   .rst                              (rst                ),

   //Ping Pong FIFO Interface
   .i_rd_rdy                         (read_ready         ),
   .o_rd_act                         (read_activate      ),
   .i_rd_size                        (read_count         ),
   .o_rd_stb                         (read_strobe        ),
   .i_rd_data                        (read_data          )
 );


//asynchronous logic
//synchronous logic

always #`CLK_HALF_PERIOD          clk     = ~clk;
always #`RD_CLK_HALF_PERIOD       rd_clk  = ~rd_clk;

initial begin
  $dumpfile ("design.vcd");
  $dumpvars(0, tb_ppfifo);


  rst                           <= 1;
  `SLEEP_CLK(10);
  rst                           <= 0;
  `SLEEP_CLK(10);
  rst                           <= 1;
end

endmodule
