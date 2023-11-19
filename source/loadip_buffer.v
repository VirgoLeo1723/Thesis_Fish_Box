module loadip_buffer //pingpong buf
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 8
)(
    input i_clk, 
    input i_rst_n,

    //write side
    output reg [1:0]            o_wr_ready, //done
    input  [1:0]                i_wr_activate, //done
    input  [DATA_WIDTH-1:0]     i_wdata, //done
    input                       i_wstrobe, //done
    output [15:0]               wr_fifo_size, //done
    output                      o_starved, //done

    //read side
    output reg                     o_rd_ready, //done
    input                       i_rd_activate, //done
    output [DATA_WIDTH-1:0]     o_rdata, //done
    input                       i_rstrobe, //done
    output reg [15:0]           o_rd_cnt, //done

    output                      o_inactivate //done
);

    localparam FIFO_DEPTH  =  (1 << ADDR_WIDTH);

    //------------------------------------------------------//
    //write side
    wire                        ppfifo_ready    ; //done
    wire [ADDR_WIDTH:0]         wr_addr_in      ; //done
    reg  [ADDR_WIDTH-1:0]       wr_base_addr    ; //done
    reg                         wr_sel_ff       ; //done
    reg                         wr_en           ; //done
    reg [1:0]                   wr_read_ready   ; //tell read side FF ready to read out
    reg [1:0]                   wr_read_done    ; //tell write side that read side is done
    reg [15:0]                  wr_cnt   [1:0]  ; //done

    reg                         wr_rst          ; //done
    reg [3:0]                   wr_rst_timeout  ; //done

    //------------------------------------------------------//
    //read side
   
    wire [ADDR_WIDTH:0]         rd_addr_out     ; //done
    reg  [ADDR_WIDTH-1:0]       rd_base_addr    ; //done
    reg                         rd_sel_ff       ; //done
    reg [15:0]                  rd_size [1:0]   ; //done
    reg [1:0]                   rd_ready        ; //done
    reg [1:0]                   rd_wait         ; //done
    reg [1:0]                   r_rd_act        ; //done
    reg [1:0]                   r_pre_activate  ; //done
    reg                         r_pre_read_wait ; //done
    reg [1:0]                   r_next_ff       ; //done

    reg                         rd_rst          ; //done
    reg [3:0]                   rd_rst_timeout  ; //done

    reg [DATA_WIDTH-1:0]        r_rdata         ; //done
    wire [DATA_WIDTH-1:0]       w_rdata         ; //done
    reg                         r_pre_strobe    ;

    assign wr_addr_in = {wr_sel_ff, wr_base_addr};
    assign rd_addr_out = {rd_sel_ff, rd_base_addr};

    assign ppfifo_ready = ~wr_rst & ~rd_rst;
    assign o_inactivate = (wr_cnt[0] == 0) && (wr_cnt[1] == 0) 
                          && (o_wr_ready == 2'b11) && i_wstrobe;

    assign wr_fifo_size = FIFO_DEPTH;

    assign o_starved = !o_rd_ready && !i_rd_activate;

    assign o_rdata = (r_pre_strobe) ? w_rdata : r_rdata;
   
  	
    blk_mem #(
        .BIT_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH+1)
    ) u_fifo (
        .clk        (i_clk),
        .rst_n      (i_rst_n),
        .wr_en      (wr_en),
        .addr_in    (wr_addr_in),
        .addr_out   (rd_addr_out),
        .wr_data    (i_wdata),
        .rd_data    (w_rdata)
    );

    always @(*) begin
      if(i_wr_activate > 0 & i_wstrobe) begin
            wr_en = 1;
        end
        else begin
            wr_en = 0;
        end
    end

    always @(*) begin
        case(i_wr_activate) 
            2'b00: begin
                wr_sel_ff = 0;
            end
            2'b01: begin
                wr_sel_ff = 0;
            end
            2'b10: begin
                wr_sel_ff = 1;
            end
            2'b11: begin
                wr_sel_ff = 0;
            end 
        endcase
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_rst          <= 1;
            wr_rst_timeout  <= 0;
        end
        else begin
            if(wr_rst && (wr_rst_timeout < 4'h5)) begin
                wr_rst_timeout <= wr_rst_timeout + 1;
            end
            else begin
                if(wr_rst_timeout == 4'h5) begin
                    wr_rst <= 0;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            rd_rst          <= 1;
            rd_rst_timeout  <= 0;
        end
        else begin
            if(rd_rst && (rd_rst_timeout < 4'h5)) begin
                rd_rst_timeout <= rd_rst_timeout + 1;
            end
            else begin
                if(rd_rst_timeout == 4'h5) begin
                    rd_rst <= 0;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_wr_ready <= 0;
        end
        else begin
            if(ppfifo_ready) begin
                if(i_wr_activate[0] && i_wstrobe) begin
                    o_wr_ready[0] <= 0;
                end
                if(i_wr_activate[1] && i_wstrobe) begin
                    o_wr_ready[1] <= 0;
                end
                if(!i_wr_activate[0] && (wr_cnt[0] == 0) && wr_read_done[0]) begin
                    o_wr_ready[0] <= 1;
                end
                if(!i_wr_activate[1] && (wr_cnt[1] == 0) && wr_read_done[1]) begin
                    o_wr_ready[1] <= 1;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_base_addr <= 0;
        end
        else begin
            if(i_wr_activate > 0 && i_wstrobe) begin
                wr_base_addr <= wr_base_addr + 1;
            end
            else begin
                if(!i_wstrobe) begin
                    wr_base_addr <= 0;
                end
            end
        end
    end 

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_cnt[0] <= 0;
            wr_cnt[1] <= 0;
        end
        else begin
            if(i_wr_activate > 0 && i_wstrobe) begin
                if(i_wr_activate[0]) begin
                    wr_cnt[0] <= wr_cnt[0] + 1;
                end
                else begin
                    if(i_wr_activate[1]) begin
                        wr_cnt[1] <= wr_cnt[1] + 1;
                    end
                end
            end
            if(!wr_read_done[0]) begin
                wr_cnt[0] <= 0;
            end
            else begin
                if(!wr_read_done[1]) begin
                  wr_cnt[1] <= 0;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            wr_read_ready <= 0;
        end
        else begin
            if(!i_wr_activate) begin
                if(wr_cnt[0] > 0) begin
                    wr_read_ready[0] <= 1;
                end
                else begin
                    if(wr_cnt[1] > 0) begin
                        wr_read_ready[1] <= 1;
                    end
                end    
            end
            if(!wr_read_done[0]) begin
                wr_read_ready[0] <= 0;
            end
            else begin
                if(!wr_read_done[1]) begin
                    wr_read_ready[1] <= 0;
                end
            end
        end
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            rd_ready <= 0;
            rd_sel_ff <= 0;
            o_rd_cnt <= 0;
            o_rd_ready <= 0;
            rd_base_addr <= 0;
            rd_wait <= 2'b11;
            r_rd_act <= 0;
            r_pre_activate <= 0;
            r_pre_read_wait <= 0;
            r_next_ff <= 0;
            wr_read_done <= 2'b11;
        end
        else begin
            r_pre_strobe <= i_rstrobe;
            if(!i_rd_activate && !r_pre_activate) begin
                if(!r_rd_act) begin
                    o_rd_cnt <= 0;
                    rd_base_addr <= 0;
                    r_pre_read_wait <= 0;
                    case(rd_ready)
                        2'b01: begin
                            rd_sel_ff <= 0;
                            r_pre_activate[0] <= 1;
                            r_pre_activate[1] <= 0;
                            r_next_ff <= 1;
                            o_rd_cnt <= rd_size[0];
                        end
                        2'b10: begin
                            rd_sel_ff <= 1;
                            r_pre_activate[0] <= 0;
                            r_pre_activate[1] <= 1;
                            r_next_ff <= 0;
                            o_rd_cnt <= rd_size[1];
                        end
                        2'b11: begin
                            rd_sel_ff <= r_next_ff;
                            r_pre_activate[r_next_ff] <= 1;
                            r_pre_activate[~r_next_ff] <= 0;
                            r_next_ff <= ~r_next_ff;
                            o_rd_cnt <= rd_size[r_next_ff];
                        end
                        default: begin 
                            rd_sel_ff <= 0;
                            r_pre_activate <= 0;
                            r_next_ff <= r_next_ff;
                        end
                    endcase
                end
                else begin
                    if(r_rd_act[rd_sel_ff] && !rd_ready[rd_sel_ff]) begin
                        r_rd_act[rd_sel_ff] <= 0;
                        wr_read_done[rd_sel_ff] <= 1;
                    end
                end
            end
            else begin
                if(r_pre_activate > 0 && r_pre_read_wait) begin
                    o_rd_ready <= 1;
                end
                if(r_rd_act > 0) begin
                    o_rd_ready <= 0;
//                  $display($time);
                    rd_ready[rd_sel_ff] <= 0;
                end
                else begin
                    if(r_pre_read_wait) begin
                        r_rdata <= w_rdata;
                        rd_base_addr <= rd_base_addr;
                        {r_rd_act, r_pre_activate} <= {r_pre_activate, 2'b0};
                    end
                    else begin
                      if(!r_pre_read_wait) begin
                        r_pre_read_wait <= 1;
                      end
                    end
                end
                if(i_rstrobe && (rd_base_addr < (rd_size[rd_sel_ff] + 1))) begin
                    r_rdata <= w_rdata;
                    rd_base_addr <= rd_base_addr + 1;
                end
                else begin
                    if(!i_rstrobe && r_pre_strobe) begin
                        r_rdata <= w_rdata;
                    end
                end
            end
          if(!wr_read_ready[0] && !rd_ready[0] && !r_rd_act[0]) begin
                rd_wait[0] <= 1; 
            end
          if(!wr_read_ready[1] && !rd_ready[1] && !r_rd_act[1]) begin
                rd_wait[1] <= 1;
            end
            if(wr_read_ready > 0) begin
                if(rd_wait[0] && wr_read_ready[0]) begin
                    if(wr_cnt[0] > 0) begin
                      if(r_rd_act == 0 && !wr_read_ready[1]) begin
                            r_next_ff <= 0;
                        end
                    end
                    //else begin
                        rd_size[0] <= wr_cnt[0];
                        rd_ready[0] <= 1;
                        rd_wait[0] <= 0;
                        wr_read_done[0] <= 0;
                    //end
                end
                if(rd_wait[1] && wr_read_ready[1]) begin
                    if(wr_cnt[1] > 0) begin
                        if(r_rd_act == 0 && !wr_read_ready[0]) begin
                            r_next_ff <= 1;
                        end
                    end
                    //else begin
                        rd_size[1] <= wr_cnt[1];
                        rd_ready[1] <= 1;
                        rd_wait[1] <= 0;
                        wr_read_done[1] <= 0;
                    //end
                end
            end
        end
    end
endmodule 