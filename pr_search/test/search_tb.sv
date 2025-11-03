////////////////////////////////////////////////////////////////
// Module name:		search_tb
// Description: 	
// Originator:  	Kostochkin
// Rev:		Rev1.0 
// Date:	17_01_2023
//////////////////////////////////////////////////////////////// 
//TESTBENCH SEARCH
////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module search_tb;
//Parameters declaration: 

import test_pkg::*;

parameter H_C_NUM_TABLE 	 = 4;
parameter H_C_RULE_WIDTH     = 24;
parameter H_C_DATA_IN_WIDTH  = 8;
parameter H_C_MEM_DATA_WIDTH = 56;
parameter H_C_MEM_ADDR_WIDTH = 8;


//Internal signals declarations:  

logic clk_i;
logic rstn_i;

logic en_i;
       
logic data_vd_i;      
logic [(H_C_DATA_IN_WIDTH-1):0] data_i;  

logic search_i;      
logic [(H_C_RULE_WIDTH-1):0] key_i; 

logic [(H_C_NUM_TABLE-1):0]    				ready_o;
logic [(H_C_NUM_TABLE-1):0]    				busy_o;
logic 										hit_vd_o;
logic 										hit_o;
logic [3:0]                                 hit_tab_o;    
logic [(H_C_MEM_ADDR_WIDTH-1):0]            hit_addr_o;  
logic [(H_C_MEM_DATA_WIDTH-H_C_RULE_WIDTH-1):0]	hit_data_o;


logic r_start_gen;
logic r_stop_gen;

event reset_trigger;
event reset_done_trigger;
event terminate_sim; 

task T_WR_WORDS (int index);

	int cnt_words;

	cnt_words = index;

	@(posedge clk_i);
	data_vd_i = 1'b1;
	data_i = data_arr_words[cnt_words][31:24];
	@(posedge clk_i);
	data_i = data_arr_words[cnt_words][23:16];
	@(posedge clk_i);
	data_i = data_arr_words[cnt_words][15:8];
	@(posedge clk_i);
	data_i = data_arr_words[cnt_words][7:0];
	repeat (16) begin
		@(posedge clk_i);
		cnt_words = cnt_words + 1;
		data_i = data_arr_words[cnt_words][55:48];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][47:40];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][39:32];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][31:24];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][23:16];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][15:8];
		@(posedge clk_i);
		data_i = data_arr_words[cnt_words][7:0];
	end
	if (H_C_MEM_ADDR_WIDTH > 4)	begin
		repeat (16) begin
			cnt_words = cnt_words + 1;
			repeat (7) begin 
				@(posedge clk_i);
				data_i = 8'hFF;
			end
		end
	end
	@(posedge clk_i);
	data_vd_i = 1'b0;
	data_i = '0;
	
endtask			 

task T_WR_BYTES (int index, int arr, int rep);

	int cnt_bytes;
	logic [7:0] cnt_cyc;

	cnt_cyc   = '0;
	cnt_bytes = index;
	repeat (rep) begin
		@(posedge clk_i);
		data_vd_i = 1'b1; 
		case (arr)
			0: data_i = data_arr_bytes_0[cnt_bytes];
			1: data_i = data_arr_bytes_1[cnt_bytes];
			2: data_i = data_arr_bytes_2[cnt_bytes];
			3: data_i = data_arr_bytes_3[cnt_bytes];
			4: data_i = data_arr_bytes_4[cnt_bytes];
			5: data_i = data_arr_bytes_5[cnt_bytes];
			6: data_i = data_arr_bytes_6[cnt_bytes];
			7: data_i = data_arr_bytes_7[cnt_bytes];
			8: begin
				data_i = 8'h10;
				@(posedge clk_i);
				data_i = 8'h68;
				@(posedge clk_i);
				data_i = 8'h05;
				@(posedge clk_i);
				data_i = 8'h78;
				@(posedge clk_i);
				repeat (200) begin					
					data_i = 8'h01;
					@(posedge clk_i);
					data_i = 8'h01;	
					@(posedge clk_i);
					data_i = cnt_cyc;
					@(posedge clk_i);
					data_i = cnt_cyc;
					@(posedge clk_i);
					data_i = cnt_cyc;
					@(posedge clk_i);
					data_i = cnt_cyc;
					@(posedge clk_i);
					data_i = cnt_cyc;
					@(posedge clk_i);
					cnt_cyc = cnt_cyc + 1'b1;
				end
			end
			default:;
		endcase 
		cnt_bytes = cnt_bytes + 1;
	end
	
	@(posedge clk_i);
	data_vd_i = 1'b0;
	data_i = '0;
	
endtask	

//initial
initial                                                
begin                                                  
    clk_i 		  = 1'b0;
	rstn_i 		  = 1'b1;
	en_i          = 1'b0;
	data_vd_i 	  = 1'b0;
	data_i        = '0;
	r_start_gen   = 1'b0;
	r_stop_gen    = 1'b0;	
    $display("Running simulation");                       
end   

//reset
initial begin 
 forever begin
  @ (reset_trigger);
  @ (posedge clk_i);
  rstn_i = 0; 
  @ (posedge clk_i); 
  rstn_i = 1; 
  #100;
  -> reset_done_trigger;
  end 
end

//reset simulation
initial begin 
  #300  -> reset_trigger; 
  @ (reset_done_trigger); 
  #40000 -> reset_trigger; 
  @ (reset_done_trigger); 
  #20000-> terminate_sim;
end

//stop simulation 
initial begin  
 @ (terminate_sim);
 $display($time, "End of sim");
 #5 $stop; 
end 

//simulation sens words
/*initial 
	begin
		@ (reset_done_trigger);
		#1000;
		T_WR_WORDS (0);
		@(posedge clk_i);
		#150;
		if (H_C_NUM_TABLE > 1) T_WR_WORDS (17);
		@(posedge clk_i);
		#300;
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#500;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	
		#100;
		if (H_C_NUM_TABLE > 2) T_WR_WORDS (34);
		@(posedge clk_i);
		#200; 
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#100;
		if (H_C_NUM_TABLE > 2) T_WR_WORDS (51);
		#300;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	
		#300; 
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#600;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	
		#100; 
		
	end*/	  
	
//simulation sens bytes
initial 
	begin
		@ (reset_done_trigger);
		#1000;
		en_i = 1'b1;
		#1500;
		T_WR_BYTES (0, 0, 33);
		@(posedge clk_i);
		#150;
		if (H_C_NUM_TABLE > 1) T_WR_BYTES (0, 1, 33);
		@(posedge clk_i);
		#500;
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);	
		#100;
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#500;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	
		#100;
		if (H_C_NUM_TABLE > 2)  T_WR_BYTES (0, 3, 45);
		@(posedge clk_i);
		#500; 			 
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);	
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#100;
		if (H_C_NUM_TABLE > 2) T_WR_BYTES (0, 2, 33);
		#500;		
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);	
		#50;	
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	
		#300; 	  
		if (H_C_NUM_TABLE > 2) T_WR_BYTES (0, 4, 45);
		#600;
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);		
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#400; 
		if (H_C_NUM_TABLE > 2) T_WR_BYTES (0, 5, 45); 
		#500;
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);		
		#200;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	  
		#100; 
		if (H_C_NUM_TABLE > 2) T_WR_BYTES (0, 8, 1);  
		#500;
		if (busy_o[0]) @(negedge busy_o[0]); 
		if (busy_o[1]) @(negedge busy_o[1]);
		if (busy_o[2]) @(negedge busy_o[2]); 
		if (busy_o[3]) @(negedge busy_o[3]);	
		#50; 
		@(posedge clk_i);
		r_start_gen = 1'b1;
		@(posedge clk_i);
		r_start_gen = 1'b0;
		#3200;
		@(posedge clk_i);
		r_stop_gen = 1'b1;
		@(posedge clk_i);
		r_stop_gen = 1'b0;	  
		#100;
	end

always #4 clk_i = ~clk_i;  

key_gen	#( 
	.C_RULE_WIDTH (H_C_RULE_WIDTH),
	.C_PAUSE      (16),
	.C_NUM_GEN    (1))
key_gen_inst ( 	
	.clk_i        (clk_i), 
	.rstn_i       (rstn_i), 
	.strb_start_i (r_start_gen),
	.strb_stop_i  (r_stop_gen),	
	.search_o     (search_i),
	.key_o        (key_i));

search_m #( 
	.C_NUM_TABLE      (H_C_NUM_TABLE),
	.C_RULE_WIDTH     (H_C_RULE_WIDTH),
	.C_DATA_IN_WIDTH  (H_C_DATA_IN_WIDTH),
	.C_MEM_DATA_WIDTH (H_C_MEM_DATA_WIDTH),
	.C_MEM_ADDR_WIDTH (H_C_MEM_ADDR_WIDTH))
search_m_inst ( 	
	.clk_i      (clk_i), 
	.rstn_i     (rstn_i),
	.en_i       (en_i),
	.data_vd_i  (data_vd_i),
	.data_i     (data_i),
	.search_i   (search_i),
	.key_i      (key_i),
	.ready_o    (ready_o),
	.busy_o     (busy_o),
	.hit_vd_o   (hit_vd_o),
	.hit_o      (hit_o),
	.hit_tab_o	(hit_tab_o),
	.hit_addr_o (hit_addr_o),
	.hit_data_o (hit_data_o));
	
monitor_test #(
	.C_RULE_WIDTH     (H_C_RULE_WIDTH),
	.C_MEM_DATA_WIDTH (H_C_MEM_DATA_WIDTH),
	.C_MEM_ADDR_WIDTH (H_C_MEM_ADDR_WIDTH))
monitor_test_inst (	
	.clk_i      (clk_i), 
	.rstn_i     (rstn_i),
	.search_i   (search_i),
	.key_i      (key_i),
	.ready_i    (ready_o),
	.busy_i     (busy_o),
	.hit_vd_i   (hit_vd_o),
	.hit_i      (hit_o),
	.hit_tab_i	(hit_tab_o),
	.hit_addr_i (hit_addr_o),
	.hit_data_i (hit_data_o));

endmodule
