//////////////////////////////////////////////////////
// Module name:		parser_package
// Description: 	
// Originator:  	KOSTOCHKIN
// Rev:		Rev1.0 
// Date:	13_11_2019
// Project: 10G 
//////////////////////////////////////////////////////	

`timescale 1ns / 1ps   

package search_pkg; 

	localparam c_n_byte_1         = 16'h0578;
	localparam c_num_bytes_tab_1  = (c_n_byte_1 - 1'b1);
	localparam c_num_bytes_tab_2  = ((c_num_bytes_tab_1<<1)-1);
	localparam c_num_bytes_tab_3  = ((c_num_bytes_tab_1*3)-1);
	localparam c_num_bytes_tab_4  = ((c_num_bytes_tab_1<<2)-1);
	localparam c_num_bytes_tab_5  = ((c_num_bytes_tab_1*5)-1);
	localparam c_num_bytes_tab_6  = ((c_num_bytes_tab_1*6)-1);
	localparam c_num_bytes_tab_7  = ((c_num_bytes_tab_1*7)-1);	
	localparam c_num_bytes_tab_8  = ((c_num_bytes_tab_1<<3)-1);	
	localparam c_num_bytes_tab_9  = ((c_num_bytes_tab_1*9)-1);	
	localparam c_num_bytes_tab_10 = ((c_num_bytes_tab_1*10)-1);	
	localparam c_num_bytes_tab_11 = ((c_num_bytes_tab_1*11)-1);	
	localparam c_num_bytes_tab_12 = ((c_num_bytes_tab_1*12)-1);	
	localparam c_num_bytes_tab_13 = ((c_num_bytes_tab_1*13)-1);	
	localparam c_num_bytes_tab_14 = ((c_num_bytes_tab_1*14)-1);	
	localparam c_num_bytes_tab_15 = ((c_num_bytes_tab_1*15)-1);		

	function integer flog2(input integer num);
		begin
			num = num - 1;
			for (flog2=0; num>0; flog2++) begin
				num = num >> 1;
			end
		end
	endfunction	
   
	function logic [15:0] fdiv(input logic [15:0] divt, input logic [3:0] divr);	 
	
	  	logic [31:0] divident_copy; 
	  	logic [31:0] divider_copy; 
	  	logic [31:0] diff_w; 
	  	logic [4:0]  ii;	
		  
		  	divident_copy = {16'h0000, divt};
			divider_copy  = {13'h0000, divr, 15'h0000};  
			
			for (ii=16; ii>0; ii--) begin  
				diff_w = divident_copy - divider_copy;
				divider_copy = {1'b0, divider_copy[31:1]};
				if (~diff_w[31]) begin 	
	                divident_copy = diff_w;
	                fdiv = {fdiv[14:0], 1'b1};
				end
	            else fdiv = {fdiv[14:0], 1'b0};
			end
	
	endfunction

	
endpackage