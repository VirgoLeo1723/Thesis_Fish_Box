`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2023 10:20:02 AM
// Design Name: 
// Module Name: multiply
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


module multiply 
# (
    parameter BIT_WIDTH = 8
)(
    input                        i_clk         ,
    input                        i_rst_n       ,
    input   [BIT_WIDTH-1  :0]    i_pix_weight  ,
    input   [BIT_WIDTH-1  :0]    i_pix_feature ,
    output  [2*BIT_WIDTH-1:0]    o_pix_feature ,
    input                        i_enable_colw ,
    input                        i_enable_colip,
    output                       o_ready       ,
    output                       o_start
);

localparam PIPELINE_STAGE = 1;
reg start_reg;
reg [BIT_WIDTH-1:0] pix_w;
reg [BIT_WIDTH-1:0] pix_f;

//check pipe stage to have product value P = A * B
reg [1:0] cnt;
wire pre_valid;
reg reg_ready;

assign pre_valid = (cnt == PIPELINE_STAGE) ? 1 : 0;
assign o_start   = start_reg;
assign o_ready   = reg_ready; // to acknowledge the product value for other process

mult_gen_0 mul1 (
  .CLK(i_clk        ),    // input wire CLK
  .A  (pix_w        ),    // input wire [7 : 0] A
  .B  (pix_f        ),    // input wire [7 : 0] B
  .P  (o_pix_feature)     // output wire [15 : 0] P
);
//--------------------------------------------------------//
//create ffs to latch new data into pix_w and pix_f
//--------------------------------------------------------//

always @(posedge i_clk, negedge i_rst_n) begin
  if(!i_rst_n) begin
    pix_w  <= {BIT_WIDTH{1'b0}};
    pix_f  <= {BIT_WIDTH{1'b0}};
  end
  else begin
    if(i_enable_colw & i_enable_colip) begin
      pix_w  <= i_pix_weight ;
      pix_f  <= i_pix_feature;
    end
  end
end

//after enable, o_ready will hold 0 until
// clk              __|``|__|``|__|``|__|``|__|``|__|
// i_enable_colw    __|`````|________________________
// i_enable_colip   __|`````|________________________
// i_pix_weight     __(-----)------------------------
// i_pix_feature    __(-----)------------------------
// pix_w            ________(-----)------------------
// pix_f            ________(-----)------------------
// o_pix_feature    ______________(-----)------------
// o_ready          ````````\___________/```````````
// en_prcs_new_wcol ______________/`````\____________

always @(posedge i_clk, negedge i_rst_n) begin
  if(!i_rst_n) begin
    reg_ready <= 1;
  end
  else begin
    if(i_enable_colw & i_enable_colip) begin
      reg_ready <= 0;
    end
    else begin
      if(pre_valid) begin
        reg_ready <= 0;
      end
      else begin
        reg_ready <= 1;
      end
    end
  end
end
always @(posedge i_clk, negedge i_rst_n) begin
  if(!i_rst_n) begin
    cnt <= 0;
  end
  else begin
    if(i_enable_colip & i_enable_colw) begin
      cnt <= cnt + 1;
    end
    else begin
      if(cnt == PIPELINE_STAGE) begin
        cnt <= 0;
      end
    end
  end
end



//-----------------------------------------------------------//
//inform to other process that the computation processor started//
//----------------------------------------------------------//

always @(posedge i_clk, negedge i_rst_n) begin
  if(!i_rst_n) begin
    start_reg <= 0;
  end
  else begin
    if(i_enable_colw & i_enable_colip) begin
      start_reg <= 1;
    end
    else begin
      start_reg <= 0;
    end
  end
end

endmodule
