/////////////////////////////////////
// clock sync
////////////////////////////////////
`timescale 1ns/1ps
module vk_clock_sync_v2
#(
    parameter     WIDTH    = 1,
    parameter     DEPTH    = 2,
    parameter bit INIT_VAL = 1'b0
)
(
    input                     dst_clk,
    input                     rstn,
    input       [WIDTH - 1:0] din,
    output wire [WIDTH - 1:0] dout
);

(* shreg_extract = "NO", ASYNC_REG = "TRUE" *) logic [(WIDTH-1):0] cdcr [(DEPTH-1):0];
int ii;

assign dout = cdcr[DEPTH-1];

always_ff @(posedge dst_clk)
begin
    if(~rstn) begin
        for(ii=0; ii<DEPTH; ii++) begin
            cdcr[ii] <= '{WIDTH{INIT_VAL}};
        end
    end
    else begin
        for(ii=1; ii<DEPTH; ii++) begin
            cdcr[ii] <= cdcr[ii-1];
        end
        cdcr[0] <= din;
    end
end

endmodule
