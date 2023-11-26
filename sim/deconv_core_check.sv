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

`define  m_display(message)  $write("[%s]:  %s","Deconv_core_tb", message);
`define  m_fdisplay(file_handle,message) $fwrite(file_handle,"[%10t][%s]:  %s",$time, "Deconv_core_tb", message);

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
    parameter NON_OVERLAPPED_CONST      = (SIZE_OF_FEATURE/2) * STRIDE;
    parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_FEATURE/2-1) + SIZE_OF_WEIGHT;
    parameter SIZE_OF_PRSC_OUTPUT       = 2*SIZE_OF_PRSC_INPUT - (SIZE_OF_PRSC_INPUT-NON_OVERLAPPED_CONST);
    parameter NUM_OF_CHANNEL_EACH_KERNEL = 4;
                                    
    reg i_clk;
    reg i_rst_n;
    
    wire [3:0]                                      weight_reader_en           ;       
    wire [3:0]                                      weight_reader_valid        ;    
    wire [PIX_WIDTH*4-1:0]                          weight_reader_data_out     ; 
    wire [3:0]                                      feature_reader_en          ;      
    wire [3:0]                                      feature_reader_valid       ;   
    wire [PIX_WIDTH*4-1:0]                          feature_reader_data_out    ;
    wire [3:0]                                      feature_writer_en          ;
    wire [3:0]                                      feature_writer_valid       ;   
    wire [(SIZE_OF_PRSC_OUTPUT**2)*2*PIX_WIDTH-1:0] feature_writer_data_in     ; 
    wire [3:0]                                      feature_writer_finish      ;
    wire [3:0]                                      feature_writer_transfer_ready;
    
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
    
    int feature;
    int weight [] = new [4];   
    int deconv [] = new [4];
    int result [] = new [4];    
    int actual_result [] = new [4];
    
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
        .SIZE_OF_GATHER_RESULT      (SIZE_OF_GATHER_RESULT      ),
        .BRAM_DATA_WIDTH            (BRAM_DATA_WIDTH            ),                                                                         
        .ADDRESS_WIDTH              (ADDRESS_WIDTH              ),                                                                         
        .SIZE_OF_FEATURE            (SIZE_OF_FEATURE            ),                                                                         
        .SIZE_OF_WEIGHT             (SIZE_OF_WEIGHT             ),                                                                         
        .PIX_WIDTH                  (PIX_WIDTH                  ),                                                                         
        .STRIDE                     (STRIDE                     ),
        .NUM_OF_CHANNEL_EACH_KERNEL (NUM_OF_CHANNEL_EACH_KERNEL )                                                                
    )deconv_core_inst(
        .i_clk                          (i_clk                          ),
        .i_rst_n                        (i_rst_n                        ),
        .weight_reader_en               (weight_reader_en               ),
        .weight_reader_valid            (weight_reader_valid            ),
        .weight_reader_data_out         (weight_reader_data_out         ),
        .feature_reader_en              (feature_reader_en              ),
        .feature_reader_valid           (feature_reader_valid           ),
        .feature_reader_data_out        (feature_reader_data_out        ),
        .feature_writer_en              (feature_writer_en              ),
        .feature_writer_valid           (feature_writer_valid           ),
        .feature_writer_transfer_ready  (feature_writer_transfer_ready  ),
        .feature_writer_data_in         (feature_writer_data_in         ),
        .feature_writer_finish          (feature_writer_finish          )
    );
        
    task print_weight_channel( 
                                input bit [PIX_WIDTH-1:0] weight_fifo [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1], 
                                input int kernel_index,
                                input int channel_index
                             );
        foreach (weight_fifo[fifo_index])
        begin
            `m_display($sformatf("===== Weight_kernel[%0d] channel[%0d]\n", fifo_index, channel_index))
            `m_fdisplay(weight[fifo_index],$sformatf("===== Channel[%0d]\n", channel_index))
            for (int row=0; row<SIZE_OF_WEIGHT; row++)
            begin
                for (int column=0; column<SIZE_OF_WEIGHT; column++)
                begin
                    $write($sformatf("  %h  ", weight_fifo[fifo_index][row][column]));
                    $fwrite(weight[fifo_index],$sformatf("%h ", weight_fifo[fifo_index][row][column]));
                end 
                $display("");
                $fdisplay(weight[fifo_index],"");
            end
        end
    endtask : print_weight_channel
    
    task print_feature_channel( 
                                input bit [PIX_WIDTH-1:0] feature_input [0:3][0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1], 
                                input int kernel_index
                              );
        foreach (feature_input[channel_index])
        begin
            `m_display($sformatf("===== Feature [%0d] input channel[%0d]\n", kernel_index, channel_index))
            `m_fdisplay(feature,$sformatf("===== Feature [%0d] input channel[%0d]\n", kernel_index, channel_index))
            for (int row=0; row<SIZE_OF_FEATURE; row++)
            begin
                for (int column=0; column<SIZE_OF_FEATURE; column++)
                begin
                    $write($sformatf("  %h  ", feature_input[channel_index][row][column]));
                    $fwrite(feature, $sformatf("%h ", feature_input[channel_index][row][column]));
                end 
                $display("");
                $fdisplay(feature,"");
            end
        end
    endtask : print_feature_channel
    
    task print_result_channel (     
                                    input bit [2*PIX_WIDTH-1:0] result_channel[0:N_PIX_OUT-1][0:N_PIX_OUT-1], 
                                    input int kernel_index, input int channel_index, input int file_handle
                               );
        `m_display($sformatf("===== Deconv output kernel[%0d] channel[%0d] \n", kernel_index, channel_index))
        `m_fdisplay(file_handle, $sformatf("===== Deconv output channel[%0d] \n",channel_index))
        for (int row=0; row<N_PIX_OUT; row++)
        begin
            for (int column=0; column<N_PIX_OUT; column++)
            begin
                $write($sformatf("  %h  ", result_channel[row][column]));
                $fwrite(file_handle,$sformatf("%h ", result_channel[row][column]));
            end 
            $display("");
            $fdisplay(file_handle, "");
        end
    endtask : print_result_channel
    
    // Function: calculate reference deconvolution operation result
    task deconv_operation(
                            input bit [PIX_WIDTH-1:0]   weight_channel  [0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1],
                            input bit [PIX_WIDTH-1:0]   feature_channel [0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1],
                            output bit[2*PIX_WIDTH-1:0] deconv_result   [0:N_PIX_OUT-1][0:N_PIX_OUT-1],
                            input int kernel_index, 
                            inout int channel_index,
                            input int stride=1
                         );
        automatic bit [2*PIX_WIDTH-1:0] deconv_channel [0:N_PIX_OUT-1][0:N_PIX_OUT-1];
        begin
        localparam SIZE_OF_OUTPUT = N_PIX_OUT;
        $displayh("weight=%p",weight_channel);
        $displayh("feature=%p", feature_channel);
        
            
        for (int feature_row=0; feature_row<SIZE_OF_FEATURE; feature_row++)
        begin
            for (int feature_column=0; feature_column<SIZE_OF_FEATURE; feature_column++)
            begin
                for (int weight_row=0; weight_row<SIZE_OF_FEATURE; weight_row++)
                begin
                    for (int weight_column=0; weight_column<SIZE_OF_FEATURE; weight_column++)
                    begin
                        if ({1'b0,deconv_channel[feature_row*stride+weight_row][feature_column*stride+weight_column]} + {1'b0,feature_channel[feature_row][feature_column] * weight_channel[weight_row][weight_column]} < 1<<32)
                        begin
                            deconv_channel[feature_row*stride+weight_row][feature_column*stride+weight_column] = deconv_channel[feature_row*stride+weight_row][feature_column*stride+weight_column] + feature_channel[feature_row][feature_column] * weight_channel[weight_row][weight_column];
                        end
                        else
                        begin
                            deconv_channel[feature_row*stride+weight_row][feature_column*stride+weight_column] = ({1'b0,deconv_channel[feature_row*stride+weight_row][feature_column*stride+weight_column]} + {1'b0,feature_channel[feature_row][feature_column] * weight_channel[weight_row][weight_column]}) >> 1;
                        end
                    end 
                end
            end    
        end
        $displayh("result=%p", deconv_channel);
        deconv_result = deconv_channel;
        print_result_channel(deconv_channel, kernel_index, channel_index, deconv[kernel_index]);
        end
    endtask : deconv_operation
    
    // Function: calculate reference gather data each kernel
    task gather_data_each_kernel (
                                    input bit [2*PIX_WIDTH-1:0]deconv_kernel_result[0:3][0:N_PIX_OUT-1][0:N_PIX_OUT-1],
                                    input int weight_bram_index,
                                    input int kernel_index   
                                 );
        automatic bit [2*PIX_WIDTH-1:0] kernel_result [0:N_PIX_OUT-1][0:N_PIX_OUT-1];
        begin
            foreach (deconv_kernel_result[channel_index,row,column])
            begin
                kernel_result[row][column] = kernel_result[row][column] + deconv_kernel_result[channel_index][row][column];
            end
            print_result_channel(kernel_result, 0, kernel_index, result[weight_bram_index]);
        end
    endtask : gather_data_each_kernel
    
    task assign_data_gather_kernel_value(
                                            inout bit actual_data_gather_result[0:5][0:5], 
                                            input bit [(SIZE_OF_PRSC_OUTPUT/2)**2*(2*PIX_WIDTH)-1:0] sub_result, 
                                            input int index
                                         );
        begin
            for (int row=0; row<3; row ++)
                for (int col=0; col<3; col++)
                    actual_data_gather_result[index/2*3+row][index%2*3+col] = sub_result[row][col];
        end
    endtask: assign_data_gather_kernel_value
    
    bit [PIX_WIDTH-1:0] weight_channel[0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];
    bit [PIX_WIDTH-1:0] weight_fifo[$][0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];
    bit [PIX_WIDTH-1:0] weight_kernel[$][$][0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];

    bit [PIX_WIDTH-1:0] feature_channel[0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    bit [PIX_WIDTH-1:0] feature_fifo[$][0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    bit [PIX_WIDTH-1:0] feature_kernel[$][$][0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    
    bit [2*PIX_WIDTH-1:0] ref_deconv_result_kernel[0:3][0:3][0:NUM_OF_CHANNEL_EACH_KERNEL-1][0:5][0:5];
    bit [2*PIX_WIDTH-1:0] deconv_result[0:5][0:5];
    
    bit [2*PIX_WIDTH-1:0] actual_data_gather_result_kernel[$][0:5][0:5];
    bit [2*PIX_WIDTH-1:0] actual_data_gather_result[0:5][0:5];
    
    int weight_kernel_counter;
    int weight_channel_counter;
    int col_each_weight_channel;
    
    int feature_kernel_counter;
    int feature_channel_counter;
    int col_each_feature_channel;
    
    int input_counter;
    bit done_deconv_operation;
    
    // Collect weight
    always @(posedge i_clk)
    begin
        if (|weight_reader_valid)
        begin
            for (int index=0; index<4; index++)
            begin
                weight_channel[index][col_each_weight_channel%SIZE_OF_WEIGHT][col_each_weight_channel/SIZE_OF_WEIGHT] = weight_reader_data_out[index*PIX_WIDTH+:PIX_WIDTH];
            end
            col_each_weight_channel ++;
            if (col_each_weight_channel == SIZE_OF_WEIGHT**2) 
            begin 
                //print_weight_channel(weight_channel, weight_channel_counter);
                col_each_weight_channel = 0;
                weight_channel_counter ++;
                
                weight_fifo[$+1] = weight_channel;
                if (weight_channel_counter == NUM_OF_CHANNEL_EACH_KERNEL)
                begin
                    weight_kernel[$+1] = {weight_kernel[$+1],weight_fifo};
                    weight_kernel_counter ++;
                    weight_channel_counter = 0;
                    weight_fifo={};
                end
            end 
        end 
    end

    // Collect feature input
    always @(posedge i_clk)
    begin
     if (|feature_reader_valid)
        begin
            feature_channel[0+col_each_feature_channel%(SIZE_OF_FEATURE/2)][0+col_each_feature_channel/(SIZE_OF_FEATURE/2)] = feature_reader_data_out[0*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[0+col_each_feature_channel%(SIZE_OF_FEATURE/2)][2+col_each_feature_channel/(SIZE_OF_FEATURE/2)] = feature_reader_data_out[1*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[2+col_each_feature_channel%(SIZE_OF_FEATURE/2)][0+col_each_feature_channel/(SIZE_OF_FEATURE/2)] = feature_reader_data_out[2*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[2+col_each_feature_channel%(SIZE_OF_FEATURE/2)][2+col_each_feature_channel/(SIZE_OF_FEATURE/2)] = feature_reader_data_out[3*PIX_WIDTH+:PIX_WIDTH];

            col_each_feature_channel ++;
            if (col_each_feature_channel == (SIZE_OF_FEATURE/2)*2) 
            begin 
                feature_channel_counter    ++;
                col_each_feature_channel    = 0;
                feature_fifo[$+1]           = feature_channel;
                
                if (feature_channel_counter >= NUM_OF_CHANNEL_EACH_KERNEL) 
                begin
                    feature_kernel[$+1] = {feature_kernel[$+1],feature_fifo};
                    feature_kernel_counter ++;
                    feature_channel_counter =0;
                    feature_fifo = {};
                end
           end 
        end 
    end 

    int counter = 0;
    int kernel_index = 0;
    int bram_index = 0;
    initial
    begin
        forever
        begin
            @(posedge i_clk);
            for (int core_index=0; core_index<4; core_index++)
            begin
                if (deconv_core_inst.data_gather_valid_out[core_index])
                begin
                    assign_data_gather_kernel_value(actual_data_gather_result,deconv_core_inst.data_gather_data_out[core_index], core_index); 
                end
            end
            print_result_channel(actual_data_gather_result,0 ,kernel_index, actual_result[bram_index]);
            bram_index ++;
            actual_data_gather_result = {};
            if (bram_index==4)
            begin
                kernel_index ++;
                bram_index = 0;
            end
        end
    end
    
    // Calculate reference result
    initial
    begin
        foreach (weight[f_file_idx])
        begin
            weight [f_file_idx]         = $fopen($sformatf("fishbox_weight_%0d.txt",f_file_idx),"w");
            deconv [f_file_idx]         = $fopen($sformatf("fishbox_deconv_%0d.txt",f_file_idx),"w");
            result [f_file_idx]         = $fopen($sformatf("fishbox_ref_result_%0d.txt", f_file_idx),"w");
            actual_result [f_file_idx]  = $fopen($sformatf("fishbox_actual_result_%0d", f_file_idx),"w");
        end
        feature= $fopen($sformatf("fishbox_feature.txt"),"w");
       
        
        wait(weight_kernel_counter===4);
        
        foreach(weight_kernel[kernel_index,channel_index])
        begin
            print_weight_channel(weight_kernel[kernel_index][channel_index], kernel_index, channel_index);   
        end
        
        foreach (feature_kernel[f_kernel_index])
        begin
            print_feature_channel(feature_kernel[f_kernel_index], f_kernel_index);         
            foreach(weight_kernel[kernel_index,channel_index])
            begin 
                // parallel between 4 weight_bram
                /*weight bram 0*/deconv_operation(weight_kernel[kernel_index][channel_index][0], feature_kernel[f_kernel_index][channel_index], ref_deconv_result_kernel[0][kernel_index][channel_index],0,channel_index); 
                $display("kernel_index=%0d, channel_index=%0d",kernel_index, channel_index);
                $displayh("----- deconv_result[0]:%p", ref_deconv_result_kernel[0][kernel_index][channel_index]); 
                $displayh("----- deconv_result[1]:%p", ref_deconv_result_kernel[1][kernel_index][channel_index]); 
                $displayh("----- deconv_result[2]:%p", ref_deconv_result_kernel[2][kernel_index][channel_index]); 
                $displayh("----- deconv_result[3]:%p", ref_deconv_result_kernel[3][kernel_index][channel_index]);
                /*weight_bram_1*/deconv_operation(weight_kernel[kernel_index][channel_index][1], feature_kernel[f_kernel_index][channel_index], ref_deconv_result_kernel[1][kernel_index][channel_index],1,channel_index); 
                $display("kernel_index=%0d, channel_index=%0d",kernel_index, channel_index);
                $displayh("----- deconv_result[0]:%p", ref_deconv_result_kernel[0][kernel_index][channel_index]); 
                $displayh("----- deconv_result[1]:%p", ref_deconv_result_kernel[1][kernel_index][channel_index]); 
                $displayh("----- deconv_result[2]:%p", ref_deconv_result_kernel[2][kernel_index][channel_index]); 
                $displayh("----- deconv_result[3]:%p", ref_deconv_result_kernel[3][kernel_index][channel_index]);
                /*weight_bram_2*/deconv_operation(weight_kernel[kernel_index][channel_index][2], feature_kernel[f_kernel_index][channel_index], ref_deconv_result_kernel[2][kernel_index][channel_index],2,channel_index); 
                $display("kernel_index=%0d, channel_index=%0d",kernel_index, channel_index);
                $displayh("----- deconv_result[0]:%p", ref_deconv_result_kernel[0][kernel_index][channel_index]); 
                $displayh("----- deconv_result[1]:%p", ref_deconv_result_kernel[1][kernel_index][channel_index]); 
                $displayh("----- deconv_result[2]:%p", ref_deconv_result_kernel[2][kernel_index][channel_index]); 
                $displayh("----- deconv_result[3]:%p", ref_deconv_result_kernel[3][kernel_index][channel_index]);
                /*weight_bram_4*/deconv_operation(weight_kernel[kernel_index][channel_index][3], feature_kernel[f_kernel_index][channel_index], ref_deconv_result_kernel[3][kernel_index][channel_index],3,channel_index); 
                $display("kernel_index=%0d, channel_index=%0d",kernel_index, channel_index);
                $displayh("----- deconv_result[0]:%p", ref_deconv_result_kernel[0][kernel_index][channel_index]); 
                $displayh("----- deconv_result[1]:%p", ref_deconv_result_kernel[1][kernel_index][channel_index]); 
                $displayh("----- deconv_result[2]:%p", ref_deconv_result_kernel[2][kernel_index][channel_index]); 
                $displayh("----- deconv_result[3]:%p", ref_deconv_result_kernel[3][kernel_index][channel_index]);
            end
            
            foreach (ref_deconv_result_kernel[weight_bram_index,kernel_index])
            begin
                $display(weight_bram_index, kernel_index);
                gather_data_each_kernel(
                                        ref_deconv_result_kernel[weight_bram_index][kernel_index],
                                        weight_bram_index,
                                        kernel_index
                                       );
            end
        end
        
        $fclose(feature);
        foreach (weight[f_file_idx])
        begin
            $fclose(result[f_file_idx]);
            $fclose(weight[f_file_idx]);
            $fclose(deconv[f_file_idx]);
        end
//        $finish;
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
    blk_mem_gen_0 weight_bram_1 (
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
                .WRITER_DATA_IN_WIDTH   (((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH  ), 
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                  ) 
            ) feature_bram_controller (
                .clk_i                  (i_clk                                             ),
                .rst_i                  (i_rst_n                                           ),    
                .rd_en_i                (feature_reader_en             [feature_bram_index]),    
                .wr_en_i                (feature_writer_en             [feature_bram_index]),    
                .wr_valid_i             (feature_writer_valid          [feature_bram_index]),    
                .wr_ready_i             (feature_writer_transfer_ready [feature_bram_index]),
                .wr_data_i              (feature_writer_data_in        [feature_bram_index*((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH+:((SIZE_OF_PRSC_OUTPUT/2)**2)*2*PIX_WIDTH]),    
                .wr_finish_o            (feature_writer_finish         [feature_bram_index]),    
                .rd_valid_o             (feature_reader_valid          [feature_bram_index]),    
                .rd_data_o              (feature_reader_data_out       [feature_bram_index*PIX_WIDTH+:PIX_WIDTH]),    
                .bram_addr              (feature_bram_addr             [feature_bram_index]),    
                .bram_en                (feature_bram_en               [feature_bram_index]),    
                .bram_we                (feature_bram_we               [feature_bram_index]),    
                .bram_data_out          (feature_bram_data_out         [feature_bram_index]),    
                .bram_data_in           (feature_bram_data_in          [feature_bram_index])    
            );          
        end
    endgenerate
    //====================================================================//
    blk_mem_gen_5 feature_bram_1 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [0]),
        .wea          (feature_bram_we       [0]),
        .addra        (feature_bram_addr     [0]),
        .dina         (feature_bram_data_in  [0]),
        .douta        (feature_bram_data_out [0]) 
    );    
    blk_mem_gen_6 feature_bram_2 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [1]),
        .wea          (feature_bram_we       [1]),
        .addra        (feature_bram_addr     [1]),
        .dina         (feature_bram_data_in  [1]),
        .douta        (feature_bram_data_out [1]) 
    );   
    blk_mem_gen_7 feature_bram_3 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [2]),
        .wea          (feature_bram_we       [2]),
        .addra        (feature_bram_addr     [2]),
        .dina         (feature_bram_data_in  [2]),        
        .douta        (feature_bram_data_out [2]) 
    );    
    blk_mem_gen_8 feature_bram_4 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [3]),
        .wea          (feature_bram_we       [3]),
        .addra        (feature_bram_addr     [3]),
        .dina         (feature_bram_data_in  [3]),        
        .douta        (feature_bram_data_out [3]) 
    ); 
    //====================================================================//

endmodule