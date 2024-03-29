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
    parameter PIX_WIDTH       = 8 ,
    parameter REG_WIDTH       = 32,
    parameter SIZE_OF_FEATURE = 8 ,
    parameter SIZE_OF_WEIGHT  = 5 ,
    parameter STRIDE          = 2 ,
    parameter N_PIX_IN        = SIZE_OF_FEATURE*SIZE_OF_WEIGHT, 
    parameter N_PIX_OUT       = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1),
    parameter STRB_WIDTH      = 2*PIX_WIDTH*N_PIX_IN/4
)
(
    input                                  clk                  ,
    input                                  rst_n                ,
    input [31:0]                           i_param_cfg_feature  , 
    input [31:0]                           i_param_cfg_weight   ,
    input                                  en_shift             ,
    input [STRB_WIDTH-1:0]                 data_strobe          ,
    input [2*PIX_WIDTH*N_PIX_IN-1:0]       data_in              ,
    output reg [2*PIX_WIDTH*N_PIX_OUT-1:0] data_out             ,
    output reg                             valid_o              ,
    output                                 accumn_fin
);
    localparam BIT_LEFT = 2*PIX_WIDTH * ((SIZE_OF_WEIGHT-STRIDE) * (SIZE_OF_FEATURE-1));
    reg [2*PIX_WIDTH*N_PIX_IN-1:0]          tmp_data_out        ;
    reg [2*PIX_WIDTH*N_PIX_IN-1:0]          data_accumm         ;
    reg [2*PIX_WIDTH*SIZE_OF_WEIGHT-1:0]    sub_data            ;
    wire [2*PIX_WIDTH*N_PIX_IN-1:0]         data_shift          ;
    reg                                     first_merge_flag    ;
    reg [SIZE_OF_FEATURE:0]                 cnt_accumm          ;
    reg                                     accum_fin_continue  ;
    reg [SIZE_OF_FEATURE:0]                 tmp_cnt_accum       ;

    assign data_shift = tmp_data_out >> (2*PIX_WIDTH*((cnt_accumm-1)*(`WEIGHT_SIZE-`STRIDE)));

//     always @(posedge clk, negedge rst_n) begin
//         if(!rst_n) begin
//             cnt_accumm <= 0;
//             data_out <=0;
//             data_accumm <=0;
//         end
//         else begin
//             if(en_shift) begin
//                 data_accumm <= data_accumm + (tmp_data_out>>(2*PIX_WIDTH*((cnt_accumm-1)*(`WEIGHT_SIZE - `STRIDE))));
//                 // data_accumm <= data_accumm + (tmp_data_out>>(2*PIX_WIDTH*((cnt_accumm-1)*(SIZE_OF_WEIGHT-STRIDE)))) ;
// //                $display("non_shift=%h",tmp_data_out);
// //                $display("shifted  =%h",tmp_data_out>>(2*PIX_WIDTH*((cnt_accumm-1)*(SIZE_OF_WEIGHT-STRIDE))));
// //                $display("result   =%h",data_accumm + (tmp_data_out>>(2*PIX_WIDTH*((cnt_accumm-1)*(SIZE_OF_WEIGHT-STRIDE)))));
//                 cnt_accumm  <= cnt_accumm+1;
//             end
//             if(cnt_accumm == `FEATURE_SIZE + 1) begin
//                 cnt_accumm  <= 0;
//                 data_out    <= data_accumm;
//                 valid_o     <= 1'b1;
//                 data_accumm <= 0;
//             end
//             else
//             begin
//                 valid_o <= 0;
//                 data_out <= 0; 
//             end
//         end
    // end
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            cnt_accumm <= 0;
            data_out <= 0;
            data_accumm <= 0;
        end
        else begin
            if(en_shift) begin
                data_accumm <= data_accumm + data_shift;
                cnt_accumm <= cnt_accumm + 1;
            end
            if(cnt_accumm == `FEATURE_SIZE+1) begin
                cnt_accumm <= 0;
                data_out <= data_accumm;
                valid_o <= 1;
                data_accumm <= 0;
            end
            else begin
                valid_o <= 0;
                data_out <= 0;
            end
        end
    end   

    reg [2*PIX_WIDTH*N_PIX_IN-1:0] data_mask;
    reg [$clog2(N_PIX_IN):0] deconv_eachcol_result_size_strobe;
    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n || cnt_accumm == `FEATURE_SIZE+1)
    //     begin
    //         // data_mask <= {{2*PIX_WIDTH*(N_PIX_IN-SIZE_OF_WEIGHT){1'b0}},{2*PIX_WIDTH*SIZE_OF_WEIGHT{1'b1}}};
    //         for (deconv_eachcol_result_size_strobe=0; deconv_eachcol_result_size_strobe<N_PIX_IN; deconv_eachcol_result_size_strobe=deconv_eachcol_result_size_strobe+1)
    //         begin
    //             if (deconv_eachcol_result_size_strobe<`WEIGHT_SIZE)
    //             begin
    //                 data_mask[2*PIX_WIDTH*deconv_eachcol_result_size_strobe+:2*PIX_WIDTH] <= {(2*PIX_WIDTH){1'b1}};
    //             end
    //         end 
    //         tmp_data_out <= 0;
    //     end
    //     else
    //     begin
    //         if(en_shift) begin
    //             tmp_data_out  <= (data_in & data_mask);
    //             data_mask     <= data_mask << (2*`WEIGHT_SIZE);
    //         end
    //         else begin
    //             tmp_data_out  <= 0;
    //             data_mask     <= data_mask;
    //         end
    //     end
    // end 
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n || (cnt_accumm == `FEATURE_SIZE+1)) begin
            tmp_data_out <= 0;
            data_mask <= {{2*PIX_WIDTH*(N_PIX_IN-SIZE_OF_WEIGHT){1'b0}},{2*PIX_WIDTH*SIZE_OF_WEIGHT{1'b1}}};
        end
        else begin
            if(en_shift) begin
                tmp_data_out <= data_in && data_mask;
                data_mask <= data_mask << (2*PIX_WIDTH*`WEIGHT_SIZE);
            end
            else begin
                tmp_data_out <= 0;
            end
        end
    end
    
    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         accum_fin_continue <= 0;
    //         tmp_cnt_accum <= 0;
    //     end
    //     else begin
    //         if(req_data) begin
    //             accum_fin_continue <= 1;
    //             tmp_cnt_accum <= tmp_cnt_accum + 1;
    //         end 
    //         else begin
    //             if(tmp_cnt_accum != `WEIGHT_SIZE-1 && tmp_cnt_accum >0) begin
    //                 accum_fin_continue <= 1;
    //                 tmp_cnt_accum <= tmp_cnt_accum + 1;
    //             end
    //             else begin
    //                 if(tmp_cnt_accum == `WEIGHT_SIZE-1) begin
    //                     accum_fin_continue <= 0;
    //                     tmp_cnt_accum <= 0;
    //                 end
    //                 else
    //                 begin
    //                     if (!tmp_cnt_accum && !req_data )
    //                     begin
    //                         tmp_cnt_accum <= 0;
    //                     end
    //                 end
    //             end
    //         end
    //     end
    // end

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            tmp_cnt_accum <= 0;
            accum_fin_continue <= 0;
        end
        else begin
            if(req_data) begin
                tmp_cnt_accum <= tmp_cnt_accum + 1;
                accum_fin_continue <= 1;
            end
            else begin
                if(tmp_cnt_accum != `WEIGHT_SIZE -1 && (tmp_cnt_accum > 0)) begin
                    tmp_cnt_accum <= tmp_cnt_accum + 1;
                    accum_fin_continue <= 1;
                end
                else begin
                    if(tmp_cnt_accum == `WEIGHT_SIZE-1) begin
                        tmp_cnt_accum <= 0;
                        accum_fin_continue <= 0;
                    end
                end
            end
        end
    end

    assign req_data = (cnt_accumm == `FEATURE_SIZE-1) ? 1 : 0;
    assign accumn_fin = req_data | accum_fin_continue;
endmodule

