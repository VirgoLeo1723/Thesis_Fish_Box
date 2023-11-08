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
    output                              rd_valid_o   ,
    output [READER_DATA_OUT_WIDTH-1:0]  rd_data_o    ,
    
    output [ADDRESS_WIDTH-1:0]          bram_addr    ,
    output                              bram_en      ,
    output                              bram_we      ,
    input  [BRAM_DATA_WIDTH-1:0]        bram_data_out,
    output [BRAM_DATA_WIDTH-1:0]        bram_data_in 
);
    bram_reader #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_IN_WIDTH(BRAM_DATA_WIDTH),
        .DATA_OUT_WIDTH(READER_DATA_OUT_WIDTH)
    )bram_reader_inst(
        .clk_i       (clk_i        ),
        .rst_i       (rst_i        ),
        .en_i        (rd_en_i      ),
        .data_i      (bram_data_out),
        .data_o      (rdr_data_out ),
        .valid_o     (rdr_valid    ),
        .bram_addr   (bram_rd_addr ),
        .bram_en     (bram_wr_addr ),
        .bram_we     (bram_wr_en   )
    );
    
    
    bram_writer bram_writer_inst();
endmodule

module bram_writer #(
    parameter 
)(

);

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
    // Code your design here
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