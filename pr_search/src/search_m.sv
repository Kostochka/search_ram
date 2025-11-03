////////////////////////////////////////////////////////////////
// Module name:		search_m
// Description: 	
// Originator:  	Kostochkin
// Rev:		Rev1.0 
// Date:	25_01_2023
//////////////////////////////////////////////////////////////// 
//MODULE SEARCH FOR MARKER
////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module search_m	 
	
	import search_pkg::*;
	
#( 
	parameter C_NUM_TABLE       = 4,	// Number of block ram, value: 1,2,4,8 or 16
	parameter C_RULE_WIDTH      = 24,	// Bit width of rules
	parameter C_DATA_IN_WIDTH   = 8,    // Bit width of input data, value: 8
	parameter C_MEM_DATA_WIDTH  = 56,	// Bit width of data in ram
	parameter C_MEM_ADDR_WIDTH  = 8,	// Bit width of addres in ram
	parameter C_PORT            = 1)    // Number of port
( 	
	input  logic 				 						clk_i,        // Input clock
	input  logic 				 						rstn_i,		  // Input asynchronous reset, active '0'
	
	input  logic 				 						en_i,		  // Input asynchronous enable, active '1'	

	input  logic										data_vd_i,	  // Signal input data valid, active '1'
	input  logic [(C_DATA_IN_WIDTH-1):0]				data_i,		  // Input data, packet of rules (C_DATA_IN_WIDTH = 8)

	input  logic										search_i,	  // Strob signal, start rule search for key, active '1'
	input  logic [(C_RULE_WIDTH-1):0]					key_i,		  // Rule, whitch search in ram 

	output logic [(C_NUM_TABLE-1):0]    				ready_o,	  // Signal from each block ram, then it ready for load rules, active '1' 
	output logic [(C_NUM_TABLE-1):0]    				busy_o,	      // Signal from each block ram, then it busy for load rules, active '1' 

	output logic 										hit_vd_o,	  // Strob, search finished, active '1'
	output logic 										hit_o,		  // Strob, '1' - search was successful, '0' - search failed
	output logic [3:0]                                  hit_tab_o,    // Output number table, addres in that was found rule
	output logic [(C_MEM_ADDR_WIDTH-1):0]               hit_addr_o,   // Output addres, addres in that was found rule
	output logic [(C_MEM_DATA_WIDTH-C_RULE_WIDTH-1):0]	hit_data_o);  // Output data, data that was found in ram by rule						
		

	localparam C_SIZE_MEM 		= 2**C_MEM_ADDR_WIDTH;
	localparam C_DATA_OUT_WIDTH = C_MEM_DATA_WIDTH-C_RULE_WIDTH;
	localparam C_SIZE_P         = flog2(C_NUM_TABLE);

	localparam logic [(C_MEM_DATA_WIDTH-1):0] c_init_data = '1;

	//c_num_bytes_tab_1 =  ((C_SIZE_MEM*7)-1);

	logic                           rstn;
	logic [(C_NUM_TABLE-1):0]		r_ready;
	logic 							r_hit_vd;
	logic 							r_hit;
	logic [(C_MEM_ADDR_WIDTH-1):0]	r_hit_addr;
	logic [3:0]	                    r_hit_tab;
	logic [(C_DATA_OUT_WIDTH-1):0]	r_hit_data;
	logic [(C_DATA_IN_WIDTH-1):0] 	r_data_temp;						  
	logic [15:0]                    r_mem_offset;
	logic [15:0]                    r_size_block;
	logic [15:0]                    r_size_block_rules;
	logic [15:0]                    r_size_block_bytes_calc;
	logic [2:0]                     r_num_bytes;
	logic [7:0]                     r_num_rules;
	logic [0:0]						r_state_cnf;   
	logic [(C_SIZE_P-1):0]          tpoint;		   // number of block ram, where rules will be loaded 
	logic [(C_NUM_TABLE-1):0]		r_busy_tab;
	logic [(C_NUM_TABLE-1):0]		r_busy; 
	logic 							r_wake_up;

	//logic [C_SIZE_P:0] 				kk, jj;
	logic [9:0]                     r_shift; 
	logic [(C_RULE_WIDTH-1):0]      r_key;   
	logic							r_search_state;
	logic                           r_end_search, r_end_search_del;  	
	logic [1:0]                     r_start_wr;  
	logic [(C_NUM_TABLE-1):0][0:0]  stab;
	logic [(C_NUM_TABLE-1):0][0:0]  r_stab;
	logic                           r_en_sync;
	(* keep = "true" *) logic [(C_NUM_TABLE-1):0][0:0]  r_stab_test;
	
	(* keep = "true" *) logic [C_SIZE_P:0] r_hit_table;


	enum logic [1:0] {INIT, START, SEARCH, PAUSE} state_sr; 
	enum logic [1:0] {IDLE, WAIT, WR_DATA, STOP} state_wr; 

	struct packed {
		logic [1:0][(C_NUM_TABLE-1):0] weA;
		logic [1:0][(C_NUM_TABLE-1):0][(C_MEM_ADDR_WIDTH-1):0] addrA;
		logic [1:0][(C_NUM_TABLE-1):0][(C_MEM_ADDR_WIDTH-1):0] addrB;
		logic [1:0][(C_NUM_TABLE-1):0][(C_MEM_DATA_WIDTH-1):0] diA;		 
		logic [1:0][(C_NUM_TABLE-1):0][(C_MEM_DATA_WIDTH-1):0] doB;} STR_MEM;
		
	

////////////////////////////////////////////
//RESET
////////////////////////////////////////////
	vk_areset #()
    areset_inst (
		.clk_i    (clk_i),
    	.areset_i (rstn_i),
   		.sreset_o (rstn));
		
////////////////////////////////////////////
//SYNCHRONIZATION
////////////////////////////////////////////		

    vk_clock_sync_v2 #(
        .WIDTH    (1),
        .DEPTH    (2),
        .INIT_VAL (1'b0))
    sync_req_inst (
        .dst_clk    (clk_i),
        .rstn       (rstn),
        .din        (en_i),
        .dout       (r_en_sync));

////////////////////////////////////////////
//MEMORY
////////////////////////////////////////////
genvar ii;
generate 
	for (ii=0; ii<C_NUM_TABLE; ii++) begin: CTRL_MEM

		ram #(
			.WIDTH     (C_MEM_DATA_WIDTH),
			.ADDRWIDTH (C_MEM_ADDR_WIDTH))
		ram_0_inst (
			.clkA  (clk_i),   			
			.clkB  (clk_i),   			 
			.enA   (1'b1),   			 
			.enB   (1'b1),   			
			.weA   (STR_MEM.weA[0][ii]),   			
			.weB   (1'b0),    			
			.addrA (STR_MEM.addrA[0][ii]),  			
			.addrB (STR_MEM.addrB[0][ii]),  			
			.diA   (STR_MEM.diA[0][ii]),   		    
			.diB   (),   		    
			.doA   (),   		    
			.doB   (STR_MEM.doB[0][ii]));
			
		ram #(
            .WIDTH     (C_MEM_DATA_WIDTH),
            .ADDRWIDTH (C_MEM_ADDR_WIDTH))
        ram_1_inst (
            .clkA  (clk_i),               
            .clkB  (clk_i),                
            .enA   (1'b1),                
            .enB   (1'b1),               
            .weA   (STR_MEM.weA[1][ii]),               
            .weB   (1'b0),                
            .addrA (STR_MEM.addrA[1][ii]),              
            .addrB (STR_MEM.addrB[1][ii]),              
            .diA   (STR_MEM.diA[1][ii]),               
            .diB   (),               
            .doA   (),               
            .doB   (STR_MEM.doB[1][ii]));

	end
endgenerate

////////////////////////////////////////////
//WRITE MEM
////////////////////////////////////////////  

always_ff @(posedge clk_i or negedge rstn) begin
	if (~rstn) begin
		state_wr  	       <= IDLE;
		r_state_cnf        <= '0;
		r_num_bytes        <= '0;
		r_num_rules        <= '0;
		r_size_block_rules <= '0;
		tpoint             <= '0;
		STR_MEM.weA        <= '0;
		r_ready            <= '0;
		r_busy_tab         <= '0;
		STR_MEM.addrA      <= '1;
		r_wake_up          <= 1'b0;
		r_start_wr         <= '0;
		stab               <= '0;
		r_busy             <= '0;
		r_size_block_bytes_calc <= '0;
	end
	else begin
	
		if (~r_en_sync) begin
			state_wr  	       <= IDLE;
			r_state_cnf        <= '0;
			r_num_bytes        <= '0;
			r_num_rules        <= '0;
			r_size_block_rules <= '0;
			tpoint             <= '0;
			STR_MEM.weA        <= '0;
			r_ready            <= '0;
			r_busy_tab         <= '0;
			STR_MEM.addrA      <= '1;
			r_wake_up          <= 1'b0;
			r_start_wr         <= '0;
			stab               <= '0;
			r_busy             <= '0;
			r_size_block_bytes_calc <= '0;
		end
		else begin
		
			if (r_state_cnf) r_busy_tab <= 2**tpoint;
			else if (~r_search_state) r_busy_tab <= '0;

			case (state_wr)	
				IDLE: begin
					r_wake_up <= 1'b1;			
					for (int kk=0; kk<C_NUM_TABLE; kk++) begin
						STR_MEM.weA[0][kk]   <= 1'b1;
						STR_MEM.addrA[0][kk] <= STR_MEM.addrA[0][kk] + 1'b1;	
						STR_MEM.diA[0][kk]   <= c_init_data;
						STR_MEM.weA[1][kk]   <= 1'b1;
						STR_MEM.addrA[1][kk] <= STR_MEM.addrA[1][kk] + 1'b1;    
						STR_MEM.diA[1][kk]   <= c_init_data;
					end
					if ((r_wake_up) && (STR_MEM.addrA[0][0] == '1)) begin
						STR_MEM.weA <= '0;
						state_wr <= WAIT;
					end
				end
				WAIT: begin
					r_ready 	<= '1;
					r_state_cnf <= 1'b0;
					STR_MEM.weA <= '0;
					if (data_vd_i) begin
						state_wr  		<= WR_DATA;
						r_data_temp 	<= data_i;
						r_num_bytes 	<= 3'b001;
						r_num_rules 	<= '0;
						STR_MEM.addrA 	<= '1;
					end
				end
				WR_DATA: begin
					case (r_state_cnf)
						0: begin
							r_num_bytes <= (r_num_bytes == 3'b011) ? '0 : (r_num_bytes + 1'b1);
							r_data_temp <= data_i;
							if (r_num_bytes == 3'b001) r_mem_offset <= {r_data_temp, data_i};
							if (r_num_bytes == 3'b011) begin
								r_size_block <= {r_data_temp, data_i};
								r_state_cnf <= 1'b1;
								case (C_NUM_TABLE)
									1: tpoint <= '0;
									2: begin
										if (r_mem_offset > c_num_bytes_tab_1) tpoint <= 4'h1;
										else tpoint <= '0;
									end
									4: begin
										if      (r_mem_offset > c_num_bytes_tab_3) tpoint <= 4'h3;
										else if (r_mem_offset > c_num_bytes_tab_2) tpoint <= 4'h2;
										else if (r_mem_offset > c_num_bytes_tab_1) tpoint <= 4'h1;
										else tpoint <= '0;
									end
									8: begin
										if      (r_mem_offset > c_num_bytes_tab_7) tpoint <= 4'h7;
										else if (r_mem_offset > c_num_bytes_tab_6) tpoint <= 4'h6;
										else if (r_mem_offset > c_num_bytes_tab_5) tpoint <= 4'h5;
										else if (r_mem_offset > c_num_bytes_tab_4) tpoint <= 4'h4;
										else if (r_mem_offset > c_num_bytes_tab_3) tpoint <= 4'h3;
										else if (r_mem_offset > c_num_bytes_tab_2) tpoint <= 4'h2;
										else if (r_mem_offset > c_num_bytes_tab_1) tpoint <= 4'h1;
										else tpoint <= '0;
									end
									16: begin
										if      (r_mem_offset > c_num_bytes_tab_15) tpoint <= 4'hF;
										else if (r_mem_offset > c_num_bytes_tab_14) tpoint <= 4'hE;
										else if (r_mem_offset > c_num_bytes_tab_13) tpoint <= 4'hD;
										else if (r_mem_offset > c_num_bytes_tab_12) tpoint <= 4'hC;
										else if (r_mem_offset > c_num_bytes_tab_11) tpoint <= 4'hB;
										else if (r_mem_offset > c_num_bytes_tab_10) tpoint <= 4'hA;
										else if (r_mem_offset > c_num_bytes_tab_9)  tpoint <= 4'h9;
										else if (r_mem_offset > c_num_bytes_tab_8)  tpoint <= 4'h8;	
										else if (r_mem_offset > c_num_bytes_tab_7)  tpoint <= 4'h7;
										else if (r_mem_offset > c_num_bytes_tab_6)  tpoint <= 4'h6;
										else if (r_mem_offset > c_num_bytes_tab_5)  tpoint <= 4'h5;
										else if (r_mem_offset > c_num_bytes_tab_4)  tpoint <= 4'h4;
										else if (r_mem_offset > c_num_bytes_tab_3)  tpoint <= 4'h3;
										else if (r_mem_offset > c_num_bytes_tab_2)  tpoint <= 4'h2;
										else if (r_mem_offset > c_num_bytes_tab_1)  tpoint <= 4'h1;
										else tpoint <= '0;	
									end
									default: tpoint <= '0;
								endcase
							end
						end
						1: begin
							r_busy[tpoint]  <= 1'b1;
							r_ready[tpoint] <= 1'b0;
							r_size_block_bytes_calc <= r_size_block_bytes_calc + 1'b1;
							r_num_bytes <= (r_num_bytes == 3'b110) ? '0 : (r_num_bytes + 1'b1);
							r_num_rules <= (r_num_bytes == 3'b110) ? (r_num_rules + 1'b1) : r_num_rules;
							STR_MEM.diA[stab[tpoint]][tpoint] <= {STR_MEM.diA[stab[tpoint]][tpoint][(C_MEM_DATA_WIDTH-C_DATA_IN_WIDTH-1):0], data_i};
							if (r_num_bytes == 'b110) begin
								STR_MEM.weA[stab[tpoint]][tpoint]   <= 1'b1;
								STR_MEM.addrA[stab[tpoint]][tpoint] <= STR_MEM.addrA[stab[tpoint]][tpoint] + 1'b1;
							end
							else STR_MEM.weA[stab[tpoint]][tpoint] <= 1'b0;
							//if (r_start_wr == 3'b11) begin
							//    if (r_ready != '1) begin                       
							//        if (r_size_block_rules == '0) state_wr <= STOP;
							//        else if (STR_MEM.addrA[stab[tpoint]][tpoint] == (r_size_block_rules-1'b1)) state_wr <= STOP;
							//    end
							//end
							//else r_start_wr <= r_start_wr + 1'b1; 
							//if (r_start_wr == '0) r_size_block_rules <= fdiv(r_size_block, 4'h7);
							if (r_size_block == '0) state_wr <= STOP;
							else if (r_size_block_bytes_calc == (r_size_block - 1'b1)) state_wr <= STOP; 
						end
						default:;
					endcase
				end
				STOP: begin
					r_start_wr              <= '0;
					r_busy                  <= '0;
					r_ready 	            <= '1;
					r_size_block_bytes_calc <= '0;
					STR_MEM.weA             <= '0;
					if (~data_vd_i) begin
						state_wr <= WAIT;
						stab[tpoint] <= ~stab[tpoint];
					end	
				end
				default:;
			endcase
		end
	end 
end	

////////////////////////////////////////////
//SEARCH FOR MARKER
////////////////////////////////////////////
always_ff @(posedge clk_i or negedge rstn) begin
	if (~rstn) begin
		state_sr <= INIT;
		r_hit_vd <= 1'b0;
		r_hit    <= 1'b0;
		r_hit_data <= '1;
		r_search_state <= 1'b0;
		r_end_search   <= 1'b0;
		r_end_search_del <= 1'b0;
		r_stab           <= '1;
		r_stab_test      <= '1;
	end
	else begin
	
		if (~r_en_sync) begin
			state_sr <= INIT;
			r_hit_vd <= 1'b0;
			r_hit    <= 1'b0;
			r_hit_data <= '1;
			r_search_state <= 1'b0;
			r_end_search   <= 1'b0;
			r_end_search_del <= 1'b0;
			r_stab           <= '1;
			r_stab_test      <= '1;
		end
		else begin
		
			r_end_search_del <= r_end_search;
			case (state_sr)
				INIT: begin
					r_shift <= C_SIZE_MEM>>2;
					STR_MEM.addrB <= '0;	
					for (int jj=0; jj<C_NUM_TABLE; jj++) begin
						STR_MEM.addrB[0][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
						STR_MEM.addrB[1][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
					end				
					state_sr <= START;
				end
				START: begin 
					r_hit_vd <= 1'b0;
					if (search_i) begin
						r_stab <= stab;
						r_stab_test <= ~stab;
						r_key <= key_i;	
						r_search_state <= 1'b1;
						r_shift <= r_shift>>1;
						for (int jj=0; jj<C_NUM_TABLE; jj++) begin
							//if (~r_busy_tab[jj]) begin
								if (STR_MEM.doB[~stab[jj]][jj][(C_MEM_DATA_WIDTH-1):(C_MEM_DATA_WIDTH-C_RULE_WIDTH)] == key_i) begin
									r_hit_vd    <= 1'b1;
									r_hit       <= 1'b1;
									r_hit_tab   <= jj;
									r_hit_addr  <= STR_MEM.addrB[~stab[jj]][jj];
									r_hit_data  <= STR_MEM.doB[~stab[jj]][jj][(C_MEM_DATA_WIDTH-C_RULE_WIDTH-1):0];
									r_hit_table <= jj;
									break;
								end
								else begin
									if (STR_MEM.doB[~stab[jj]][jj][(C_MEM_DATA_WIDTH-1):(C_MEM_DATA_WIDTH-C_RULE_WIDTH)] > key_i) 
										 STR_MEM.addrB[~stab[jj]][jj] <= STR_MEM.addrB[~stab[jj]][jj] - r_shift;	
									else STR_MEM.addrB[~stab[jj]][jj] <= STR_MEM.addrB[~stab[jj]][jj] + r_shift;
								end
							//end 	
						end
						state_sr <= PAUSE;
					end
					else begin
						r_search_state <= 1'b0;
						r_shift <= C_SIZE_MEM>>2;
						STR_MEM.addrB <= '0;	
						for (int jj=0; jj<C_NUM_TABLE; jj++) begin
							STR_MEM.addrB[0][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
							STR_MEM.addrB[1][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
						end
					end	
				end
				SEARCH: begin
					if (r_shift == '0) r_end_search <= 1'b1;
					else r_shift <= r_shift>>1;
					for (int jj=0; jj<C_NUM_TABLE; jj++) begin
						//if (~r_busy_tab[jj]) begin
							if (STR_MEM.doB[~r_stab[jj]][jj][(C_MEM_DATA_WIDTH-1):(C_MEM_DATA_WIDTH-C_RULE_WIDTH)] == r_key) begin
								r_hit_vd 	<= 1'b1;
								r_hit    	<= 1'b1;
								r_hit_tab   <= jj;
								r_hit_addr  <= STR_MEM.addrB[~stab[jj]][jj];
								r_hit_data  <= STR_MEM.doB[~r_stab[jj]][jj][(C_MEM_DATA_WIDTH-C_RULE_WIDTH-1):0];
								state_sr    <= START; 
								r_hit_table <= jj;
								break;
							end
							else if (STR_MEM.doB[~r_stab[jj]][jj][(C_MEM_DATA_WIDTH-1):(C_MEM_DATA_WIDTH-C_RULE_WIDTH)] > r_key) begin
								if (r_shift != '0) STR_MEM.addrB[~r_stab[jj]][jj] <= STR_MEM.addrB[~r_stab[jj]][jj] - r_shift;
								else STR_MEM.addrB[~r_stab[jj]][jj] <= STR_MEM.addrB[~r_stab[jj]][jj] - 1'b1;	
							end
							else begin
								if (r_shift != '0) STR_MEM.addrB[~r_stab[jj]][jj] <= STR_MEM.addrB[~r_stab[jj]][jj] + r_shift;
								else STR_MEM.addrB[~r_stab[jj]][jj] <= STR_MEM.addrB[~r_stab[jj]][jj] + 1'b1;
							end
						//end 	
					end
					state_sr <= PAUSE;				
				end
				PAUSE:begin
					if ((r_hit_vd) | (r_end_search_del)) begin	  
						if (r_hit_vd) r_hit_vd <= 1'b0;
						else if (r_end_search_del) r_hit_vd <= 1'b1;	
						r_hit <= 1'b0;  
						r_end_search <= 1'b0; 
						state_sr <= START;
						STR_MEM.addrB <= '0;	
						for (int jj=0; jj<C_NUM_TABLE; jj++) begin
							STR_MEM.addrB[0][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
							STR_MEM.addrB[1][jj][(C_MEM_ADDR_WIDTH-1)] <= 1'b1;
						end
					end	
					else state_sr <= SEARCH;
				end
				default:;	 
			endcase
		end
	end 
end	

////////////////////////////////////////////
//OUT DATA
////////////////////////////////////////////
 
assign ready_o 		= r_ready;
assign busy_o       = r_busy;
assign hit_vd_o 	= r_hit_vd;
assign hit_o 		= r_hit;
assign hit_tab_o    = r_hit_tab;
assign hit_addr_o   = r_hit_addr;
assign hit_data_o 	= r_hit_data;	
	

endmodule
