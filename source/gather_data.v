`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 06:13:40 PM
// Design Name: 
// Module Name: gather_data
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


module data_gather #(
    parameter DATA_WIDTH            = 32,
    parameter NO_OF_KERNEL          = 16,
    parameter N_CHANNEL_EACH_KERNEL = 32,
    parameter NO_TURN_WIDTH         = $clog2(NO_OF_KERNEL)
)
(
    input                           i_clk                   ,
    input                           i_rst_n                 ,
    input                           i_valid_coming          ,
    input                           i_feature_writer_finish ,
    input  [6:0]                    i_channel_per_kernel    ,
    input  [DATA_WIDTH-1:0]         i_tilling_machine_out   ,
    output [DATA_WIDTH/4-1  :0]     o_gather_out            ,
    output                          o_gather_valid
);

genvar i;
integer k;

wire                            last_channel_flag       ;
wire [6:0]                      cur_check               ;
wire [DATA_WIDTH-1        :0]   tmp_o_gather_out   ;
reg  [DATA_WIDTH-1        :0]   o_kernel_data           ;
wire [DATA_WIDTH/4-1      :0]   o_chan_0                ;
wire [DATA_WIDTH/4-1      :0]   o_chan_1                ;
wire [DATA_WIDTH/4-1      :0]   o_chan_2                ;
wire [DATA_WIDTH/4-1      :0]   o_chan_3                ;

reg  [NO_TURN_WIDTH-1   :0]     cnt                     ;
reg  [6:0]                      start_addr              ;
reg  [6:0]                      addr_request            ;
reg                             refresh_mem             ;
reg                             data_valid              ;
reg                             wr_en_sram              ;
reg                             data_available_flag     ;
reg                             sram_en                 ;
reg                             first_trans             ;
 
assign last_channel_flag = ( cur_check == N_CHANNEL_EACH_KERNEL) ? 1 : 0;
assign o_gather_valid = data_valid;

//number of turns loading kernel from software to hardware for processing data
//being careful
    reg init =1'b1;
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            cnt         <= 0;
            start_addr  <= 0;
            refresh_mem <= 0;
        end
        else begin
            if(last_channel_flag) begin
                cnt         <= cnt + 1;
                start_addr  <= cnt << 2 ;
                refresh_mem <= 1;
                init <= 1'b0;
            end
            else begin
                refresh_mem <= 0;
            end
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_en_sram          <= 0;
            data_available_flag <= 0;
        end
        else begin
            wr_en_sram <= refresh_mem;
            if(wr_en_sram) begin
                data_available_flag <= 1;
            end
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            sram_en <= 0;
        end
        else begin
            if(refresh_mem) begin
                sram_en <= 1;
            end
            if(last_channel_flag) begin
                sram_en <= 0;
            end
        end
    end
    
    generate
        for(i = 0 ; i < 4; i = i + 1) begin
            accumulator#(
                .DATA_WIDTH         (DATA_WIDTH/4             ),             
                .N_CHANNEL          (N_CHANNEL_EACH_KERNEL    )               
            ) u_block_accum (   
                .i_clk              (i_clk                    ),
                .i_rst_n            (i_rst_n                  ),
                .data_in            (i_tilling_machine_out[i*DATA_WIDTH/4+:DATA_WIDTH/4]),
                .stop_accum         (last_channel_flag      ),
                .rec_accum          (i_valid_coming           ),
                .current_no_channel (cur_check              ),
                .data_out           (tmp_o_gather_out[i*DATA_WIDTH/4+:DATA_WIDTH/4])
            );
        end
    endgenerate
    
    always @(posedge i_clk, negedge i_rst_n) 
    begin
        if(!i_rst_n) begin
            o_kernel_data <= 0;
        end
        else begin
            for(k = 0; k < 4; k = k + 1) 
            begin
                o_kernel_data[k*DATA_WIDTH/4 +: DATA_WIDTH/4] <= tmp_o_gather_out[k*DATA_WIDTH/4+:DATA_WIDTH/4];
            end
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            data_valid <= 0;
        end
        else begin
            if((i_feature_writer_finish|first_trans) & (data_available_flag)) begin
                data_valid <= 1;
            end
            else begin
                data_valid <= 0;
            end
        end
    end
    
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            first_trans <= 1;
            addr_request <= 0;  
        end
        else begin
            if(first_trans  & data_available_flag) begin
                addr_request <= addr_request + 1;
                first_trans <= 0;
            end
            else begin
                if(i_feature_writer_finish & data_available_flag) begin
                    addr_request <= addr_request + 1;
                end 
            end
        end
    end
    
    assign {o_chan_0, o_chan_1, o_chan_2, o_chan_3} = o_kernel_data;

    sp_sram  #(
           .WIDTH (DATA_WIDTH/4),
           .DEPTH (32)
    )sp_sram_inst(
        .i_clk      (i_clk),
        .ena        (sram_en),
        .wea        (wr_en_sram),
        .rea        (i_feature_writer_finish|first_trans),
        .addr_i     (start_addr),
        .addr_o     (addr_request),
        .dina_0     (o_chan_0),
        .dina_1     (o_chan_1),
        .dina_2     (o_chan_2),
        .dina_3     (o_chan_3),
        .douta      (o_gather_out)
    );

endmodule