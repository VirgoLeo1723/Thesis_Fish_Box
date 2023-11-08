`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2023 04:53:48 AM
// Design Name: 
// Module Name: tilling_machine
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

module sipo #(
        SIZE_OF_INPUT = 64,
        SIZE_OF_BUFFER = 8
    )( 
        input                               clk_i, 
        input                               rst_i,
        input                               rd_en_i, 
        input                               wr_en_i, 
        input       [SIZE_OF_INPUT-1:0]     data_i, 
        output reg  [SIZE_OF_INPUT*SIZE_OF_BUFFER-1:0]     data_o, 
        output                              is_empty_o, 
        output                              is_full_o
    ); 
    reg [SIZE_OF_INPUT*SIZE_OF_BUFFER-1:0] internal_memory; 
    reg [3:0]  rd_ptr; 
    reg [3:0]  wr_ptr;
    
    assign is_empty_o = (wr_ptr==0); 
    assign is_full_o  = (wr_ptr==SIZE_OF_BUFFER); 

    always @ (posedge clk_i, negedge rst_i) 
    begin 
        if (!rst_i) 
        begin 
            wr_ptr          <= 0;
            internal_memory <= 0;
            data_o          <= 0;
        end 
        else
        begin 
            if ( wr_en_i && ~is_full_o )
            begin
                if (wr_ptr < SIZE_OF_BUFFER) wr_ptr <= wr_ptr + 1;
                else wr_ptr <= 0;
                internal_memory[wr_ptr*SIZE_OF_INPUT+:SIZE_OF_INPUT] <= data_i;
            end
            else if (rd_en_i)
            begin
                data_o <= internal_memory;
                wr_ptr <= 0;
            end
        end 
    end
    
endmodule

module demultiplexer  #(
        parameter SIZE_OF_INPUT = 64,
        parameter NO_OF_INPUT   = 4
    )(
        input                                 clk_i   ,
        input                                 rst_i   ,
        input [1:0]                           select_i,
        input [SIZE_OF_INPUT*NO_OF_INPUT-1:0] data_i  ,
        output[SIZE_OF_INPUT-1:0]        data_o  
    
    );
    reg [1:0] actual_select;
//    always @(posedge clk_i, negedge rst_i)
//    begin
//        if (!rst_i)
//        begin
//            data_o <= 0;
//        end
//        else 
//        begin
//            data_o <= data_i[select_i*SIZE_OF_INPUT+:SIZE_OF_INPUT];
//        end
//    end
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i) actual_select <= 0;
        else actual_select <= select_i;
    end
    assign data_o =  data_i[actual_select*SIZE_OF_INPUT+:SIZE_OF_INPUT];
endmodule

module tilling_buffer#(
        parameter SIZE_OF_INPUT  = 128,
        parameter SIZE_OF_BUFFER = 8 
    )(
	    input                               clk_i       ,
  	    input                               rst_i       ,
        input                               rd_en_i     ,
        input      [3:0]                    wr_en_i     ,
  		input      [SIZE_OF_INPUT-1:0]      wr_data_i   ,
        output     [(SIZE_OF_INPUT/2)*SIZE_OF_BUFFER*4-1:0]  rd_data_o   ,
        output     [3:0]                    is_empty    ,
        output     [3:0]                    is_full     
    );

    wire [3:0] buffer_is_full;

    genvar buffer_index;
    generate
        for(buffer_index=0; buffer_index<4; buffer_index = buffer_index+1)
        begin
            case (buffer_index)
                0,1: 
                begin
                    sipo#(
                        .SIZE_OF_INPUT (SIZE_OF_INPUT/2),
                        .SIZE_OF_BUFFER(SIZE_OF_BUFFER)
                    ) buffer_inst (
                        .clk_i          (clk_i                                                              ),
                        .rst_i          (rst_i                                                              ),
                        .rd_en_i        (rd_en_i                                                            ),
                        .wr_en_i        (wr_en_i[buffer_index]                                              ),
                        .data_i      	(wr_data_i[0+:(SIZE_OF_INPUT/2)]                                    ),
                        .data_o      	(rd_data_o[buffer_index*(SIZE_OF_INPUT/2)*SIZE_OF_BUFFER+:(SIZE_OF_INPUT/2)*SIZE_OF_BUFFER]       ),
                        .is_empty_o     (is_empty[buffer_index]                                             ),
                        .is_full_o   	(is_full[buffer_index]                                              )
                    );
                end
                2,3: 
                begin
                    sipo#(
                        .SIZE_OF_INPUT (SIZE_OF_INPUT/2),
                        .SIZE_OF_BUFFER(SIZE_OF_BUFFER)
                    ) buffer_inst (
                        .clk_i          (clk_i                                                              ),
                        .rst_i          (rst_i                                                              ),
                        .rd_en_i        (rd_en_i                                                            ),
                        .wr_en_i        (wr_en_i[buffer_index]                                              ),
                      	.data_i      	(wr_data_i[(SIZE_OF_INPUT/2)+:(SIZE_OF_INPUT/2)]                    ),
                        .data_o      	(rd_data_o[buffer_index*(SIZE_OF_INPUT/2)*SIZE_OF_BUFFER+:(SIZE_OF_INPUT/2)*SIZE_OF_BUFFER]       ),
                        .is_empty_o     (is_empty[buffer_index]                                             ),
                        .is_full_o   	(is_full[buffer_index]                                              )
                    );
                end
            endcase
        end
    endgenerate
endmodule

module tilling_machine  #(
                        	parameter SIZE_OF_INPUT   = 128,
                          	parameter SIZE_OF_FEATURE = 16
                        )(
                            input                                       clk_i                   ,
                            input                                       rst_i                   ,         
  							input  [SIZE_OF_INPUT*4-1:0]                overlapped_column_core_i,
                            input  [3:0]			                    valid_data_core_i       ,
                            output [SIZE_OF_INPUT*SIZE_OF_FEATURE-1:0]  tilling_machine_o       ,
                            output reg                                  tilling_machine_valid_o
                        );
  	wire [SIZE_OF_INPUT-1:0]        tilling_buffer_wr_data[0:3];
  	wire [(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)*4-1:0]  tilling_buffer_rd_data[0:3];
  	wire [3:0]                      tilling_buffer_is_empty[0:3];
    wire [3:0]                      tilling_buffer_is_full [0:3];
    
    reg [3:0]                       tilling_buffer_wr_en[0:3];
  	wire [3:0] tilling_buffer_en;
     
 	integer   wr_ptr[3:0];
  	integer   rd_ptr[3:0];
    reg [1:0] loop_var;

    genvar tilling_buffer_index;
    generate
        for (tilling_buffer_index=0; tilling_buffer_index<4; tilling_buffer_index=tilling_buffer_index+1)
        begin
          	assign tilling_buffer_wr_data[tilling_buffer_index] = overlapped_column_core_i[tilling_buffer_index*SIZE_OF_INPUT+:SIZE_OF_INPUT];  
            assign tilling_buffer_en[tilling_buffer_index] = (loop_var == tilling_buffer_index) & (tilling_buffer_is_full[tilling_buffer_index]==4'd15);
          	
            tilling_buffer #(
                .SIZE_OF_INPUT(SIZE_OF_INPUT),
                .SIZE_OF_BUFFER (SIZE_OF_FEATURE/2)
            )tilling_buffer_inst (
                .clk_i	         (clk_i                                        ), 
                .rst_i           (rst_i                                        ),
              	.wr_data_i       (tilling_buffer_wr_data[tilling_buffer_index] ), 
                .rd_data_o       (tilling_buffer_rd_data[tilling_buffer_index] ),
                .wr_en_i         (tilling_buffer_wr_en[tilling_buffer_index]   ),
                .rd_en_i         (tilling_buffer_en[tilling_buffer_index]      ),
                .is_empty        (tilling_buffer_is_empty[tilling_buffer_index]),
                .is_full         (tilling_buffer_is_full[tilling_buffer_index] )   
            );
            always @(posedge clk_i, negedge rst_i)
  	        begin
      	        if (!rst_i)
                begin
                    tilling_buffer_wr_en[tilling_buffer_index]  <= 4'd0;
                    wr_ptr[tilling_buffer_index]                <= 0;
                end
      	        else
       	        begin
          	        if (valid_data_core_i[tilling_buffer_index])
                    begin
              	        if ( (wr_ptr[tilling_buffer_index]<SIZE_OF_FEATURE/2) && (tilling_buffer_is_full[tilling_buffer_index]!=4'd15) )
                        begin
              	            wr_ptr[tilling_buffer_index]               <= wr_ptr[tilling_buffer_index] + 1;
                  	        tilling_buffer_wr_en[tilling_buffer_index] <= 4'b0101;
                        end
                      	else if ((wr_ptr[tilling_buffer_index] < SIZE_OF_FEATURE) && (tilling_buffer_is_full[tilling_buffer_index]!=4'd15))
                        begin
              	            wr_ptr[tilling_buffer_index]               <= wr_ptr[tilling_buffer_index] + 1;
                  	        tilling_buffer_wr_en[tilling_buffer_index] <= 4'b1010;
                        end
                        else
                        begin
                            wr_ptr[tilling_buffer_index]               <= 0;
                            tilling_buffer_wr_en[tilling_buffer_index] <= 4'd0;
                        end
                    end
          	        else
                    begin
                        wr_ptr[tilling_buffer_index]                  <= wr_ptr[tilling_buffer_index];
                        tilling_buffer_wr_en[tilling_buffer_index]    <= 4'd0;
                    end
                end
  	        end
        end
    endgenerate

//    genvar mux_index;
//    generate
//      	for (mux_index=0; mux_index <4; mux_index = mux_index+1)
//        begin
//            demultiplexer #(
//                .SIZE_OF_INPUT((SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)),
//                .NO_OF_INPUT(4)
//            ) demux_inst(
//                .clk_i(clk_i),
//                .rst_i(rst_i),
//                .select_i(loop_var[1:0]),
//                .data_i( {  tilling_buffer_rd_data[3][mux_index*(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)],
//                            tilling_buffer_rd_data[2][mux_index*(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)],
//                            tilling_buffer_rd_data[1][mux_index*(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)],
//                            tilling_buffer_rd_data[0][mux_index*(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)]
//                        }),
//                .data_o (tilling_machine_o[mux_index*(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)+:(SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)])
//            );
//        end
//    endgenerate
    
            demultiplexer #(
                .SIZE_OF_INPUT((SIZE_OF_INPUT/2)*(SIZE_OF_FEATURE/2)*4),
                .NO_OF_INPUT(4)
            ) demux_inst(
                .clk_i(clk_i),
                .rst_i(rst_i),
                .select_i(loop_var[1:0]),
                .data_i( {  tilling_buffer_rd_data[3],
                            tilling_buffer_rd_data[2],
                            tilling_buffer_rd_data[1],
                            tilling_buffer_rd_data[0]
                        }),
                .data_o (tilling_machine_o)
            );
    
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            loop_var <= 0;
            tilling_machine_valid_o <= 0;
        end
        else
        begin
            loop_var <= loop_var + 1;
            tilling_machine_valid_o <= |tilling_buffer_en;
        end
    end
endmodule
