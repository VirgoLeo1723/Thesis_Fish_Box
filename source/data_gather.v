module data_gather #(
    parameter DATA_WIDTH = 32,
    parameter NO_OF_KERNEL = 16,
    parameter NO_TURN_WIDTH = $clog2(NO_OF_KERNEL/4)
)
(
    input clk,
    input rst_n,
    input valid_coming,
    input bram_rd_fin,
    input  [6:0] channel_per_kernel,
    input  [DATA_WIDTH-1      :0] data_i [3:0],
    output [DATA_WIDTH-1      :0] data_o,
    output o_gather_valid
);

genvar i;
integer k;
wire last_channel_flag = (cur_check == channel_per_kernel) ? 1 : 0;
wire [6:0] cur_check;
reg  [DATA_WIDTH-1      :0] tmp_data_o [3:0];
reg  [4*DATA_WIDTH-1    :0] o_kernel_data;
wire [DATA_WIDTH-1      :0] o_chan_0;
wire [DATA_WIDTH-1      :0] o_chan_1;
wire [DATA_WIDTH-1      :0] o_chan_2;
wire [DATA_WIDTH-1      :0] o_chan_3;
reg  [NO_TURN_WIDTH-1   :0] cnt;
reg  [2**NO_TURN_WIDTH-1:0] start_addr;
reg  [2**NO_TURN_WIDTH-1:0] addr_request,
assign start_addr = cnt;
assign o_gather_valid = data_valid;

//number of turns loading kernel from software to hardware for processing data
//being careful

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
        start_addr <= 0;
        refresh_mem <= 0;
    end
    else begin
        if(last_channel_flag) begin
            cnt <= cnt + 1;
            start_addr <= cnt << 2 ;
            refresh_mem <= 1;
        end
        else begin
            refresh_mem <= ~refresh_mem;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        wr_en_sram <= 0;
        data_available_flag <= 0;
    end
    else begin
        wr_en_sram <= refresh_mem;
        if(wr_en_sram) begin
            data_available_flag <= 1;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
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
        accumulator u_block_accum (
            .clk                (clk),
            .rst_n              (rst_n),
            .data_in            (data[i]),
            .stop_accum         (last_channel_flag),
            .rec_accum          (valid_coming),
            .current_no_channel (cur_check),
            .data_out           (tmp_data_o[i])
        );
    end
endgenerate

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        o_kernel_data <= 0;
    end
    else begin
        for(k = 0; k < 4, k = k + 1) begin
            o_kernel_data[k*DATA_WIDTH +: DATA_WIDTH] <= tmp_data_o[k];
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_valid <= 0;
    end
    else begin
        if(bram_rd_fin) begin
            data_valid <= 1;
        end
        else begin
            data_valid <= 0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        first_trans <= 1;
    end
    else begin
        if(first_trans & bram_rd_fin & data_available_flag) begin
            addr_request <= 0;
            first_trans <= 0;
        end
        else begin
            if(bram_rd_fin & data_available_flag) begin
                addr_request <= addr_request + 1;
            end 
        end
    end
end

assign {o_chan_0, o_chan_1, o_chan_2, o_chan_3} = o_kernel_data;

sp_sram u_sram (
    .clk        (clk),
    .rst_n      (rst_n),
    .ena        (sram_en),
    .wea        (wr_en_sram),
    .rea        (bram_rd_fin),
    .addr_i     (start_addr),
    .addr_o     (addr_request),
    .dina_0     (o_chan_0),
    .dina_1     (o_chan_1),
    .dina_2     (o_chan_2),
    .dina_3     (o_chan_3),
    .douta      (data_o)
);

endmodule