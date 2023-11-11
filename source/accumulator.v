module accumulator #
(
    parameter DATA_WIDTH = 32,
    parameter N_CHANNEL = 8,
    parameter CNT_WIDTH = $clog(N_CHANNEL)
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input stop_accum, rec_accum,
    output [DATA_WIDTH-1:0] data_out,
    output [CNT_WIDTH-1:0] current_no_channel
);
    
    reg [DATA_WIDTH-1:0] tmp_dat;
    reg [DATA_WIDTH-1:0] reg_data_o;
    reg [CNT_WIDTH-1:0] cnt_accum;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            tmp_dat <= 0;
            cnt_accum <= 0;
        end
        else begin
            if(!stop_accum && rec_accum) begin  
                tmp_dat <= tmp_dat + data_in;
                cnt_accum <= cnt_accum + 1;
            end
            if(stop_accum) begin
                cnt_accum <= 0;
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            reg_data_o <= 0;
        end
        else begin
            if(stop_accum) begin
                reg_data_o <= tmp_dat;
                tmp_dat <= 0;
            end
        end
    end

    assign data_out = reg_data_o;
    assign current_no_channel = cnt_accum;
endmodule