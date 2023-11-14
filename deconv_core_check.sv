`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 01:16:48 PM
// Design Name: 
// Module Name: deconv_core_tb
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

`define  m_display(message)  $display("[%10t][%s]:  %s",$time, "Deconv_core_tb", message);
module deconv_core_check(

    );
    parameter SIZE_OF_GATHER_RESULT = 512;
    parameter DATA_IN_WIDTH         = 512;                                                                          
    parameter BRAM_DATA_WIDTH       = 32 ;                                                                          
    parameter ADDRESS_WIDTH         = 13 ;                                                                          
    parameter SIZE_OF_FEATURE       = 4  ;                                                                          
    parameter SIZE_OF_WEIGHT        = 3  ;                                                                          
    parameter PIX_WIDTH             = 16 ;                                                                          
    parameter STRIDE                = 1  ;                                                                          
    parameter N_PIX_IN              = SIZE_OF_FEATURE*SIZE_OF_WEIGHT;                                            
    parameter STRB_WIDTH            = 2*PIX_WIDTH*N_PIX_IN/4 ;                                                      
    parameter N_PIX_OUT             = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                    (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1);
                                    
    parameter NUM_OF_CHANNEL_EACH_KERNEL = 1;
                                    
    reg i_clk;
    reg i_rst_n;
    
    wire [3:0]                                  weight_reader_en           ;       
    wire [3:0]                                  weight_reader_valid        ;    
    wire [PIX_WIDTH*4-1:0]                      weight_reader_data_out     ; 
    wire [3:0]                                  feature_reader_en          ;      
    wire [3:0]                                  feature_reader_valid       ;   
    wire [PIX_WIDTH*4-1:0]                      feature_reader_data_out    ;
    wire [3:0]                                  feature_writer_valid       ;   
    wire [3:0]                                  feature_writer_data_in     ; 
    wire [3:0]                                  feature_writer_finish      ;
    
    wire [ADDRESS_WIDTH-1:0]                    feature_bram_addr     [0:3];      
    wire [3:0]                                  feature_bram_en            ;
    wire [3:0]                                  feature_bram_we            ;
    wire [BRAM_DATA_WIDTH-1:0]                  feature_bram_data_out [0:3];
    wire [BRAM_DATA_WIDTH-1:0]                  feature_bram_data_in  [0:3];      
    
    wire [ADDRESS_WIDTH-1:0]                    weight_bram_addr      [0:3];      
    wire [3:0]                                  weight_bram_en             ;
    wire [3:0]                                  weight_bram_we             ;
    wire [BRAM_DATA_WIDTH-1:0]                  weight_bram_data_out  [0:3];
    wire [3:0]                                  weight_writer_finish       ;
    wire [SIZE_OF_GATHER_RESULT*PIX_WIDTH-1:0]  weight_bram_data_in        ;
    initial
    begin
        i_clk = 1'b0;
        forever #1 i_clk = ~i_clk; 
    end
    
    initial
    begin
        i_rst_n = 1'b0;
        #2 i_rst_n = 1'b1;
    end
    
    deconv_core#(
        .SIZE_OF_GATHER_RESULT  (SIZE_OF_GATHER_RESULT  ),
        .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH        ),                                                                         
        .ADDRESS_WIDTH          (ADDRESS_WIDTH          ),                                                                         
        .SIZE_OF_FEATURE        (SIZE_OF_FEATURE        ),                                                                         
        .SIZE_OF_WEIGHT         (SIZE_OF_WEIGHT         ),                                                                         
        .PIX_WIDTH              (PIX_WIDTH              ),                                                                         
        .STRIDE                 (STRIDE                 )                                                                       
    )deconv_core_inst(
        .i_clk                  (i_clk                  ),
        .i_rst_n                (i_rst_n                ),
        .weight_reader_en       (weight_reader_en       ),
        .weight_reader_valid    (weight_reader_valid    ),
        .weight_reader_data_out (weight_reader_data_out ),
        .feature_reader_en      (feature_reader_en      ),
        .feature_reader_valid   (feature_reader_valid   ),
        .feature_reader_data_out(feature_reader_data_out),
        .feature_writer_en      (feature_writer_en      ),
        .feature_writer_valid   (feature_writer_valid   ),
        .feature_writer_data_in (feature_writer_data_in ),
        .feature_writer_finish  (feature_writer_finish  )
    );
    
    task print_weight_channel( input bit [PIX_WIDTH-1:0] weight_fifo [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1], input int channel_index);
        foreach (weight_fifo[fifo_index])
        begin
            `m_display($sformatf("===== weight_kernel[%0d] channel[%0d] \n", fifo_index, channel_index))
            `m_display($sformatf("%p", weight_fifo[fifo_index]));
//            foreach (weight_fifo[fifo_index,row])
            begin
//                foreach (weight_fifo[fifo_index,row])
//                begin
//                    $write($sformatf("   %p   ",weight_fifo[fifo_index][row]));
//                end
//                $display("row_end \n");
            end
//            `m_display("\n")
            end    
    endtask : print_weight_channel
    
    bit [PIX_WIDTH-1:0] weight_fifo [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];
    bit [PIX_WIDTH-1:0] feature_fifo[0:3][0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    int channel_counter;
    int col_each_weight_channel;
    always @(posedge i_clk)
    begin
        if (weight_reader_valid)
        begin
//            $display("[%10t][%s]: weight_reader_out=%h",$time, "Deconv_core_tb",weight_reader_data_out);
            for (int index=0; index<4; index++)
            begin
                weight_fifo[index][col_each_weight_channel/SIZE_OF_WEIGHT][col_each_weight_channel%SIZE_OF_WEIGHT] = weight_reader_data_out[index*PIX_WIDTH+:PIX_WIDTH];
//                `m_display($sformatf("weight_fifo[%0d][%0d][%0d].add(%0d)",index,col_each_weight_channel/SIZE_OF_WEIGHT,col_each_weight_channel%SIZE_OF_WEIGHT,weight_reader_data_out[index*PIX_WIDTH+:PIX_WIDTH]))
            end
            col_each_weight_channel ++;
            if (col_each_weight_channel == SIZE_OF_WEIGHT**2) 
            begin 
//                `m_display($sformatf("Weight_fifo: %p", weight_fifo));
                print_weight_channel(weight_fifo, channel_counter);
                col_each_weight_channel = 0;
                channel_counter ++;
                if (channel_counter == NUM_OF_CHANNEL_EACH_KERNEL) 
                begin
                    `m_display("----- Waiting for the next value of tilling machine ")
                    fork
                        begin
                            wait(|deconv_core_inst.tilling_machine_valid);
//                            `m_display($sformatf("Result of [%0p]x[%0p]=[%0p]",weight_fifo,feature_fifo,deconv_core_inst.tilling_machine_out))
                        end
                    join_none
                end
            end 
        end 
    end
    
    
    genvar weight_bram_index;
    generate 
        for (weight_bram_index=0; weight_bram_index<4; weight_bram_index = weight_bram_index+1)
        begin
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                             ),
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                           ),
                .WRITER_DATA_IN_WIDTH   (BRAM_DATA_WIDTH                           ),
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                 )  
            ) weight_bram_controller (
                .clk_i                  (i_clk                                     ),
                .rst_i                  (i_rst_n                                   ),
                .rd_en_i                (weight_reader_en[weight_bram_index]       ),
                .wr_en_i                (1'b0                                      ),
                .wr_valid_i             (1'b0                                      ),
                .wr_data_i              ({DATA_IN_WIDTH{1'b0}}                     ),
                .wr_finish_o            (weight_writer_finish[weight_bram_index]   ),
                .rd_valid_o             (weight_reader_valid[weight_bram_index]    ),
                .rd_data_o              (weight_reader_data_out [weight_bram_index*PIX_WIDTH+:PIX_WIDTH]),
                .bram_addr              (weight_bram_addr       [weight_bram_index]),
                .bram_en                (weight_bram_en         [weight_bram_index]),
                .bram_we                (weight_bram_we         [weight_bram_index]),
                .bram_data_out          (weight_bram_data_out   [weight_bram_index]),
                .bram_data_in           (weight_bram_data_in    [weight_bram_index])
            );
        end
    endgenerate
    //====================================================================//
    blk_mem_gen_1 weight_bram_1 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [0]),
        .wea          (weight_bram_we       [0]),
        .addra        (weight_bram_addr     [0]),
        .douta        (weight_bram_data_out [0]) 
    );    
    blk_mem_gen_2 weight_bram_2 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [1]),
        .wea          (weight_bram_we       [1]),
        .addra        (weight_bram_addr     [1]),
        .douta        (weight_bram_data_out [1]) 
    );   
    blk_mem_gen_3 weight_bram_3 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [2]),
        .wea          (weight_bram_we       [2]),
        .addra        (weight_bram_addr     [2]),
        .douta        (weight_bram_data_out [2]) 
    );    
    blk_mem_gen_4 weight_bram_4 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [3]),
        .wea          (weight_bram_we       [3]),
        .addra        (weight_bram_addr     [3]),
        .douta        (weight_bram_data_out [3]) 
    ); 
    //====================================================================//

    genvar feature_bram_index;
    generate
        for (feature_bram_index=0; feature_bram_index < 4; feature_bram_index = feature_bram_index + 1)
        begin
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                              ), 
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                            ), 
                .WRITER_DATA_IN_WIDTH   (DATA_IN_WIDTH                              ), 
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                  ) 
            ) feature_bram_controller (
                .clk_i                  (i_clk                                      ),
                .rst_i                  (i_rst_n                                    ),    
                .rd_en_i                (feature_reader_en      [feature_bram_index]),    
                .wr_en_i                (1'b0                                       ),    
                .wr_valid_i             (feature_writer_valid   [feature_bram_index]),    
                .wr_data_i              (feature_writer_data_in [feature_bram_index]),    
                .wr_finish_o            (feature_writer_finish  [feature_bram_index]),    
                .rd_valid_o             (feature_reader_valid   [feature_bram_index]),    
                .rd_data_o              (feature_reader_data_out[feature_bram_index*PIX_WIDTH+:PIX_WIDTH]),    
                .bram_addr              (feature_bram_addr      [feature_bram_index]),    
                .bram_en                (feature_bram_en        [feature_bram_index]),    
                .bram_we                (feature_bram_we        [feature_bram_index]),    
                .bram_data_out          (feature_bram_data_out  [feature_bram_index]),    
                .bram_data_in           (feature_bram_data_in   [feature_bram_index])    
            );          
        end
    endgenerate
    //====================================================================//
    blk_mem_gen_5 feature_bram_1 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [0]),
        .wea          (feature_bram_we       [0]),
        .addra        (feature_bram_addr     [0]),
        .douta        (feature_bram_data_out [0]) 
    );    
    blk_mem_gen_6 feature_bram_2 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [1]),
        .wea          (feature_bram_we       [1]),
        .addra        (feature_bram_addr     [1]),
        .douta        (feature_bram_data_out [1]) 
    );   
    blk_mem_gen_7 feature_bram_3 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [2]),
        .wea          (feature_bram_we       [2]),
        .addra        (feature_bram_addr     [2]),
        .douta        (feature_bram_data_out [2]) 
    );    
    blk_mem_gen_8 feature_bram_4 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [3]),
        .wea          (feature_bram_we       [3]),
        .addra        (feature_bram_addr     [3]),
        .douta        (feature_bram_data_out [3]) 
    ); 
    //====================================================================//

endmodule
