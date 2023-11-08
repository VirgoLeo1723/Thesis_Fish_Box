`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 03:46:09 PM
// Design Name: 
// Module Name: bram_reader
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
module bram_controller #(
        parameter ADDRESS_WIDTH         = 13,
        parameter BRAM_DATA_WIDTH       = 32,
        parameter WRITER_DATA_IN_WIDTH  = 512,
        parameter READER_DATA_OUT_WIDTH = 8
    )(
        input                               clk_i        ,
        input                               rst_i        ,
        input                               rd_en_i      ,
        input                               wr_en_i      ,
        input                               wr_valid_i   ,
        input [WRITER_DATA_IN_WIDTH-1:0]    wr_data_i    ,
        output                              wr_finish_o  ,
        output                              rd_valid_o   ,
        output [READER_DATA_OUT_WIDTH-1:0]  rd_data_o    ,
    
        output [ADDRESS_WIDTH-1:0]          bram_addr    ,
        output                              bram_en      ,
        output                              bram_we      ,
        input  [BRAM_DATA_WIDTH-1:0]        bram_data_out,
        output [BRAM_DATA_WIDTH-1:0]        bram_data_in 
    );

    assign rdr_bram_rd_data = bram_data_out;
    assign bram_addr        = rd_en_i ? rdr_bram_rd_addr : wr_en_i ? wrt_bram_wr_addr : {ADDRESS_WIDTH{1'b0}};
    assign bran_data_in     = wrt_bram_wr_data;
    assign bram_en          = (rdr_bram_en & rd_en_i) | (wrt_bram_en & wr_en_i);
    assign bram_we          = (rdr_bram_we & rd_en_i) | (wrt_bram_we & wr_en_i); 

    assign rd_data_o        = rdr_data_out    ;
    assign rd_valid_o       = rdr_valid       ;
    assign wrt_data_in      = wr_data_i       ;
    assign wrt_valid        = wr_valid_i      ;
    assign wr_finish_o      = wrt_finish      ;

    bram_reader #(
        .ADDRESS_WIDTH  (ADDRESS_WIDTH          ),
        .DATA_IN_WIDTH  (BRAM_DATA_WIDTH        ),
        .DATA_OUT_WIDTH (READER_DATA_OUT_WIDTH  )
    )bram_reader_inst(
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .en_i           (rd_en_i                ),
        .data_o         (rdr_data_out           ),
        .valid_o        (rdr_valid              ),
        .data_i         (rdr_bram_rd_data       ),
        .bram_addr      (rdr_bram_rd_addr       ),
        .bram_en        (rdr_bram_en            ),
        .bram_we        (rdr_bram_we            )
    );
    
    bram_writer #(
        .ADDRESS_WIDTH  (ADDRESS_WIDTH          ),
        .DATA_IN_WIDTH  (WRITER_DATA_IN_WIDTH   ),
        .DATA_OUT_WIDTH (BRAM_DATA_WIDTH        )
    )bram_writer_inst(
        .clk_i          (clk_i                  ),
        .rst_i          (rst_i                  ),
        .en_i           (wr_en_i                ),
        .vaid_i         (wrt_valid              ),
        .data_i         (wrt_data_in            ),
        .data_o         (wrt_bram_wr_data       ),
        .finish_o       (wrt_finish             )
        .bram_addr      (wrt_bram_wr_addr       ),
        .bram_en        (wrt_bram_en            ),
        .bram_we        (wrt_bram_we            )
    );
endmodule

module bram_writer #(
        parameter ADDRESS_WIDTH  = 13,
        parameter DATA_IN_WIDTH  = 512,
        parameter DATA_OUT_WIDTH = 32 
    )(
        input                               clk_i       ,      
        input                               rst_i       ,      
        input                               en_i        ,      
        input                               vaid_i      ,      
        input      [DATA_IN_WIDTH-1:0 ]     data_i      ,      
        output reg [DATA_OUT_WIDTH-1:0]     data_o      ,
        output reg                          finish_o    ,      
        output reg [ADDRESS_WIDTH-1:0 ]     bram_addr   ,      
        output                              bram_en     ,      
        output                              bram_we       
    );

    localparam RESULT_BASED_ADDRESS = 5;
    assign bram_en = en_i;
    assign bram_we = 1'b1;

    reg [DATA_IN_WIDTH-1:0] result_data;
    integer counter;

    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            bram_addr   <= RESULT_BASED_ADDRESS;
            data_o      <= {DATA_OUT_WIDTH{1'b0}};
            result_data <= {DATA_IN_WIDTH{1'b0}};
            finish_o    <= 1'b0;
        end
        else
        begin
            if (en_i)
            begin
                if (valid_i)
                begin
                    result_data <= data_i;
                    counter     <= 0 ;
                    data_o      <= {DATA_OUT_WIDTH{1'b0}};
                    finish_o    <= 1'b0;
                end   
                else
                begin
                    if (counter < DATA_IN_WIDTH/DATA_OUT_WIDTH)
                    begin
                        bram_addr               <= bram_addr + 1; 
                        counter                 <= counter + 1;
                        finish_o                <= 1'b0;
                        {result_data, data_o}   <= {DATA_OUT_WIDTH{1'b0},result_data};
                    end
                    else
                    begin
                        counter     <= 0;
                        finish_o    <= 1'b1;
                    end
                end
            end
            else
            begin
                bram_addr   <= RESULT_BASED_ADDRESS;
                data_o      <= {DATA_OUT_WIDTH{1'b0}};
                result_data <= {DATA_IN_WIDTH{1'b0}};
                finish_o    <= 1'b0;
            end
        end
    end
endmodule

module bram_reader #(
        parameter ADDRESS_WIDTH  = 13,
        parameter DATA_IN_WIDTH  = 32,
        parameter DATA_OUT_WIDTH = 8
    )(
        input                               clk_i       ,
        input                               rst_i       ,
        input                               en_i        ,
        input       [DATA_IN_WIDTH-1:0]     data_i      ,
        output reg  [DATA_OUT_WIDTH-1:0]    data_o      ,
        output reg                          valid_o     ,
        output reg  [ADDRESS_WIDTH-1:0]     bram_addr   ,
        output                              bram_en     ,
        output      [3:0]                   bram_we          
    );

    reg [31:0]  bram_data       ; 
    reg         bram_init = 1'b1;
    integer     masking_counter ;
    
    assign bram_we = 4'd0;
    assign bram_en = en_i;
    
 	always @(posedge clk_i, negedge rst_i)
  	begin
		if (!rst_i)
      	begin
            bram_data       <= {DATA_IN_WIDTH{1'b0}} ;
            bram_addr       <= {DATA_OUT_WIDTH{1'b0}};
            data_o          <= {DATA_OUT_WIDTH{1'b0}};
            masking_counter <= 4'd0                  ;
            valid_o         <= 1'b0                  ;
        end
        else
        begin
            if (bram_en)
          	begin
            	if (bram_init==1'b1)
             	begin
             	    masking_counter <= masking_counter + 1;  
                	if (masking_counter == 0 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                    begin
                      	valid_o <= 1'b0;
                    end
                    else if (masking_counter == 1 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                 	begin
                      	valid_o   <= 1'b1;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, data_i};
                  	end
                  	else if ( masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-2 )
                    begin
                      	bram_addr           <= bram_addr + 1                      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	if ((DATA_IN_WIDTH/DATA_OUT_WIDTH)>2) 
                      	begin
                      	     {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};
                      	     valid_o    	     <= 1'b1							      ;

                      	end
                      	else
                      	begin
                    	 	 {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, data_i};
                      	end                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-1)
                    begin
                    	if ((DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                    	begin
                      	     masking_counter    <= masking_counter + 1   			  ;
                            {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};   
                            valid_o             <= 1'b1;
                        end
                        else
                        begin
                            masking_counter     <= 0                      			  ;
                            bram_init           <= 1'b0                               ;
                            bram_data           <= data_i                             ;
                            data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ; 
                        end                   
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH))
                  	begin
                        valid_o             <= 1'b1								  ;
                      	masking_counter     <= 0                      			  ;
                      	bram_init           <= 1'b0                               ;
                        bram_data           <= data_i                             ;
                      	data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ;  	     
                  	end
                  	else
                    begin
                    	valid_o 			<= 1'b1								  ;
                      	masking_counter     <= masking_counter + 1				  ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
              	end
              	else
                begin
                  	if (masking_counter == 0 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                   	begin
                      	valid_o             <= 1'b1                               ;
                      	masking_counter     <= masking_counter + 1                ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                    else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-3)
                    begin
                      	valid_o    			<= 1'b1							      ;
                      	bram_addr           <= bram_addr + 1                      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-2)
                    begin
                      	valid_o    			<= 1'b1	;			
                      	if ( (DATA_IN_WIDTH/DATA_OUT_WIDTH) <=2) bram_addr <= bram_addr+ 1			      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-1)
                    begin
                    	valid_o             <= 1'b1								  ;
                      	masking_counter     <= 0                      			  ;
                        bram_data           <= data_i                             ;
                      	data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ;                     
                    end
                  	else
                    begin
                    	valid_o 			<= 1'b1								  ;
                      	masking_counter     <= masking_counter + 1				  ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                end
          	end
          	else
          	begin
              	valid_o     <= 1'b0;
         	  	bram_addr   <= bram_addr;
        	  	bram_data   <= bram_data;
          	end
        end
    end
endmodule 