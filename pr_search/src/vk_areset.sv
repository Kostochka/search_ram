/////////////////////////////////////
// asynchronous reset
/////////////////////////////////////
`timescale 1ns / 1ps 

module vk_areset #()
   (input logic clk_i,
    input logic areset_i,
   	output logic sreset_o);
	
	(* shreg_extract = "no",  ASYNC_REG = "TRUE" *) logic r_reset; 
	(* shreg_extract = "no",  ASYNC_REG = "TRUE" *) logic r_reset_del; 

always_ff @(posedge clk_i or negedge areset_i) begin
	if (~areset_i) begin
		r_reset <= 1'b0;
		r_reset_del <= 1'b0;
	end
	else begin
		r_reset <= 1'b1;
		r_reset_del <= r_reset;
	end
end

always_comb
begin
	sreset_o = r_reset_del;
end

endmodule
