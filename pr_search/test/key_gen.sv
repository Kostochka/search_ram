////////////////////////////////////////////////////////////////
// Module name:		key_gen
// Description: 	
// Originator:  	Kostochkin
// Rev:		Rev1.0 
// Date:	25_01_2023
//////////////////////////////////////////////////////////////// 
//MODULE KEY GENERATION
////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module key_gen	 	
#( 
	parameter C_RULE_WIDTH = 24,
	parameter C_PAUSE      = 3,
	parameter C_NUM_GEN    = 5)
( 	
	input  logic 				 		clk_i, 
	input  logic 				 		rstn_i,
	input  logic						strb_start_i,	
	input  logic						strb_stop_i,
	output logic 						search_o,
	output logic [(C_RULE_WIDTH-1):0] 	key_o);	

	
	logic						rstn;
	
	logic 						r_search;
	logic [(C_RULE_WIDTH-1):0]	r_key;
	logic [31:0]	            r_key_rndm;

	logic [3:0] cnt_pause;
	logic [3:0] cnt_gen;

	enum logic [1:0] {INIT, KEY_G, STOP} state;  
	
	vk_areset #()
    areset_inst (
		.clk_i    (clk_i),
    	.areset_i (rstn_i),
   		.sreset_o (rstn));

always_ff @(posedge clk_i or negedge rstn) begin
	if (~rstn) begin
		state    <= INIT;
		r_search <= 1'b0;
		r_key    <= '0;
	end
	else begin
		r_key_rndm <= $random;
		case (state)	
			INIT: begin
				r_search  <= 1'b0;
				cnt_pause <= '0;
				cnt_gen   <= '0;
				if (strb_start_i) state <= KEY_G;
			end
			KEY_G: begin
				if (strb_stop_i) state <= INIT;
				else begin
					r_search 	<= 1'b1; 
					r_key[23:8]	<= 16'h0101;
					r_key[7:0]	<= r_key_rndm[7:0];
					cnt_gen  	<= (cnt_gen == (C_NUM_GEN-1)) ? '0 : (cnt_gen+1'b1);
					state    	<= (cnt_gen == (C_NUM_GEN-1)) ? STOP : KEY_G;
				end	
			end
			STOP: begin
				if (strb_stop_i) state <= INIT;
				else begin
					r_search  <= 1'b0;	
					cnt_pause <= (cnt_pause == (C_PAUSE-1)) ? '0 : (cnt_pause+1'b1);
					state     <= (cnt_pause == (C_PAUSE-1)) ? KEY_G : STOP;	
				end
			end
			default:;
		endcase
	end 
end	

assign search_o = r_search;
assign key_o    = r_key;	
	

endmodule
