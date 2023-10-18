`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2023 12:19:33 PM
// Design Name: 
// Module Name: shift_register
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


module shift_register 
#(
    parameter BIT_WIDTH     = 8,
    parameter N_COL_FEATURE = 8,
    parameter N_COL_KERNEL  = 5,
    parameter NUM_STRIDE    = 2,
    parameter N_PIX_IN      = N_COL_FEATURE*N_COL_KERNEL, 
    parameter N_PIX_OUT     = N_COL_FEATURE*N_COL_KERNEL - (N_COL_KERNEL-NUM_STRIDE)*(N_COL_FEATURE-1),
    parameter STRB_WIDTH     = 2*BIT_WIDTH*N_PIX_IN/4
)
(
    input clk,
    input rst_n,
    input en_shift,
    input [STRB_WIDTH-1:0] data_strobe,
    input [2*BIT_WIDTH*N_PIX_IN-1:0] data_in,
    output reg [2*BIT_WIDTH*N_PIX_OUT-1:0] data_out,
    output accumn_fin
);
    localparam BIT_LEFT = 2*BIT_WIDTH*N_PIX_OUT - 2*BIT_WIDTH*N_COL_KERNEL;

    reg [2*BIT_WIDTH*N_PIX_IN-1:0] tmp_data_out;
    reg [2*BIT_WIDTH*N_PIX_IN-1:0] data_accumm;
    reg [2*BIT_WIDTH*N_COL_KERNEL-1:0] sub_data;


    integer byte_id; //index
    
    reg first_merge_flag;
    integer cnt_accumm;
    reg     accum_fin_continue;
    integer tmp_cnt_accum;
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            cnt_accumm <= 0;
            data_out <=0;
            data_accumm <=0;
        end
        else begin
            if(en_shift) begin
//                if (cnt_accumm<=1)
//                begin
//                    data_accumm <= data_accumm + tmp_data_out;
//                end 
//                else
//                begin
//                    data_accumm <= data_accumm + tmp_data_out>>(cnt_accumm-1)*(2*BIT_WIDTH*(N_COL_KERNEL-NUM_STRIDE)) ;
//                end
                data_accumm <= data_accumm + (tmp_data_out>>(2*BIT_WIDTH*((cnt_accumm-1)*(N_COL_KERNEL-NUM_STRIDE)))) ;
                $display("non_shift=%h",tmp_data_out);
                $display("shifted  =%h",tmp_data_out>>(2*BIT_WIDTH*((cnt_accumm-1)*(N_COL_KERNEL-NUM_STRIDE))));
                $display("result   =%h",data_accumm + (tmp_data_out>>(2*BIT_WIDTH*((cnt_accumm-1)*(N_COL_KERNEL-NUM_STRIDE)))));
                cnt_accumm  <= cnt_accumm+1;
            end
            if(cnt_accumm == N_COL_FEATURE+1) begin
                cnt_accumm  <= 0;
                data_out    <= data_accumm;
                data_accumm <= 0;
            end
        end
    end
    
    reg [2*BIT_WIDTH*N_PIX_IN-1:0] data_mask;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n || cnt_accumm == N_COL_FEATURE+1)
        begin
            data_mask <= {{2*BIT_WIDTH*(N_PIX_IN-N_COL_KERNEL){1'b0}},{2*BIT_WIDTH*N_COL_KERNEL{1'b1}}};
            tmp_data_out <= 0;
        end
        else
        begin
            if(en_shift) begin
                tmp_data_out  <= (data_in & data_mask);
                data_mask     <= data_mask << (2*BIT_WIDTH*N_COL_KERNEL);
            end
            else begin
                tmp_data_out  <= 0;
                data_mask     <= data_mask;
            end
        end
    end 
//    always @(posedge clk, negedge rst_n) begin
//        if(!rst_n ) begin
//            sub_data     <= 0;
//            tmp_data_out <= 0;
//            byte_id      <= 0;
//            data_accumm   <= 0;
//            data_out      <=0;
//        end
//        else begin
//            if(en_shift || byte_id!=0) begin
//                if (byte_id<=N_COL_FEATURE)
//                begin
//                    byte_id     <= byte_id+1;
//                    sub_data    <= data_in[(byte_id*2*BIT_WIDTH*N_COL_KERNEL)+:(2*BIT_WIDTH*N_COL_KERNEL)];
//                    if (byte_id<N_COL_FEATURE)
//                    tmp_data_out <= {data_in[(byte_id*2*BIT_WIDTH*N_COL_KERNEL)+:(2*BIT_WIDTH*N_COL_KERNEL)], {BIT_LEFT{1'b0}}} >> {byte_id}*2*BIT_WIDTH*NUM_STRIDE;
//                    data_accumm  <= data_accumm + tmp_data_out;
//                end
//                else
//                begin
//                    byte_id <= 0;
//                    data_accumm <= 0;
//                    data_out <= data_accumm;   
//                end
//            end 
//        end
//    end
    

//    always @(posedge clk, negedge rst_n) begin
//        if(!rst_n) begin
//            cnt_accumm  <= 3;
//        end
//        else begin
//            if(cnt_accumm == N_COL_FEATURE-1)
//            begin
//                cnt_accumm <= 0;
//            end
//            else
//            begin
//                if(en_shift && ~accum_fin_continue) 
//                begin
//                    begin
//                        cnt_accumm <= cnt_accumm + 1;
//                    end
//                end
//            end
//        end
//    end
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            accum_fin_continue <= 0;
            tmp_cnt_accum <= 0;
        end
        else begin
            if(req_data) begin
                accum_fin_continue <= 1;
                tmp_cnt_accum <= tmp_cnt_accum + 1;
            end 
            else begin
                if(tmp_cnt_accum != N_COL_KERNEL-1 && tmp_cnt_accum >0) begin
                    accum_fin_continue <= 1;
                    tmp_cnt_accum <= tmp_cnt_accum + 1;
                end
                else begin
                    if(tmp_cnt_accum == N_COL_KERNEL-1) begin
                        accum_fin_continue <= 0;
                        tmp_cnt_accum <= 0;
                    end
                    else
                    begin
                        if (!tmp_cnt_accum && !req_data )
                        begin
                            tmp_cnt_accum <= 0;
                        end
                    end
                end
            end
        end
    end
    assign req_data = (cnt_accumm == N_COL_FEATURE-1) ? 1 : 0;
    assign accumn_fin = req_data | accum_fin_continue;
endmodule
