`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 12:31:10 PM
// Design Name: 
// Module Name: weight_fifo
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


// Code your design here
module weight_fifo 
#(
    parameter BIT_WIDTH     = 8,
    parameter NO_COL_KERNEL = 5,
    parameter N_OF_PIXELS   = NO_COL_KERNEL * NO_COL_KERNEL //8*5*5 = 120 bits
)
(
    input i_clk                     ,
    input i_rst_n                   ,
    input wr_en                     ,
    input rd_en                     ,
    input loop_back                 ,
    input i_flush                   , 
    input [BIT_WIDTH-1:0] data_in   ,
    output [BIT_WIDTH*NO_COL_KERNEL-1:0] colw_data_out , //one column weight
    output s_empty                  ,
    output s_full                   ,
    output col_export_done          ,                   //connect with i_enable signal of multiply module
    output reg request_data				,
    output reg flush_fin			,
    output reg loop_fin  
);

  	localparam FIFO_DEPTH = $clog2(N_OF_PIXELS);
    // LOCAL VARIABLES//
    reg [BIT_WIDTH-1:0] ram [0:FIFO_DEPTH-1];
    reg [BIT_WIDTH:0] wr_pt, rd_pt          ;
    reg [BIT_WIDTH-1:0] tmp_data_out        ;
    reg col_export_reg                      ;
    reg [2:0] cnt_concat                    ;
    wire re_fifo, we_fifo                   ;
    wire fifo_idle                          ;
    wire threshold                          ;
    wire end_channel                        ;
    integer i;

    assign re_fifo = !s_empty & rd_en;
    assign we_fifo = !s_full & wr_en ;

    assign s_full = {~wr_pt[BIT_WIDTH], wr_pt[BIT_WIDTH-1:0]} == rd_pt;
    assign s_empty = wr_pt == rd_pt;
    assign fifo_idle = !s_full & !s_empty;

    assign threshold = (rd_pt == N_OF_PIXELS); //indicate the last pixel of a weight channel
    assign end_channel = (wr_pt == N_OF_PIXELS);

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_pt <= 0;
            ram[wr_pt[BIT_WIDTH-1:0]] <= 0; 
        end
        else begin
            if(we_fifo) begin
                ram[wr_pt[BIT_WIDTH-1:0]] <= data_in;
                wr_pt <= wr_pt + 1;
            end
          	else begin
              if(i_flush) begin
                wr_pt <= 0;
              end
            end
        end
    end

    //---------------------------------------------------------------//
    //load each pixel of one column until done one column 
    //and write in a register
    //---------------------------------------------------------------//

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            tmp_data_out <= 0;
        end
        else begin
            if(re_fifo) begin
                tmp_data_out <= ram[rd_pt[BIT_WIDTH-1:0]];
            end
            else begin
                if(threshold & loop_back) begin
                    tmp_data_out <= ram[rd_pt[BIT_WIDTH-1:0]];
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            rd_pt <= 0;
        end
        else begin
            if(re_fifo) begin
                rd_pt <= rd_pt + 1;
            end
            else begin
              if((threshold & loop_back) || i_flush) begin
                    rd_pt <= 0;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            loop_fin <= 0;
        end
        else begin
            if(loop_back) begin
                loop_fin <= 1;
            end
        end
    end
  
  	reg [BIT_WIDTH*NO_COL_KERNEL-1:0] col_res_reg;
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            col_res_reg <= 0;
        end
        else begin
            if(re_fifo) begin
              col_res_reg <= {col_res_reg[BIT_WIDTH*(NO_COL_KERNEL-1)-1:0], tmp_data_out};
            end
        end
    end

    assign colw_data_out   = (col_export_done) ? col_res_reg : 0;
    assign col_export_done = col_export_reg; //valid

    //------------------------------------------------------------//
    // when finish one column
    //------------------------------------------------------------//
    always @(posedge i_clk, negedge i_rst_n) begin
      if(!i_rst_n) begin
            cnt_concat <= 0;
            col_export_reg <= 0;
        end
        else begin
          	if(re_fifo) begin 
                if(cnt_concat == NO_COL_KERNEL) begin
                    cnt_concat <= 0;
                    col_export_reg <= 1; 
                end
                else begin
                    cnt_concat <= cnt_concat + 1;
                    col_export_reg <= 0;
                end
            end
            else begin
              if(rd_en && (cnt_concat == NO_COL_KERNEL)) begin
                col_export_reg <= 1;
              end
            end
        end
    end

    //refresh fifo to load new channel  	
    always @(posedge i_clk, negedge i_rst_n) begin
      if(!i_rst_n) begin
            for(i = 0; i < BIT_WIDTH; i = i+1) begin
                ram[i] <= 0;
            end
        end
        else begin
            if(i_flush) begin
                for(i  = 0; i < BIT_WIDTH; i=i+1) begin
                    ram[i] <= 0;
                end
            end
        end
    end

    //------------------------------------------------------//
    //when core requests to flush data in weight fifo
    //deconv core must wait ack from fifo to process next action
    //------------------------------------------------------//
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            flush_fin <= 0;
        end
        else begin
            if(i_flush) begin
                flush_fin <= 1;
            end
            else begin
                flush_fin <= 0;
            end
        end
    end

    //---------------------------------------------------------//
    //after flush_fin request to write data into the memory
    //or if channel is not loaded full, request to write more
    //---------------------------------------------------------//

    always @(*) begin
        if(!end_channel) begin
            request_data = 1;
        end
        else begin
            if(flush_fin) begin
                request_data = 1;
            end
            else begin
                request_data = 0;
            end
        end
    end
  
  	initial
    begin
        $monitor($time, "data_out= %b",colw_data_out);
    end
endmodule
