`timescale 1 ns/1 ns
 
module test();
 
reg clk  ;
reg rst_n;
 
wire      dout0;
wire[7:0] dout1;
 
 
parameter CYCLE    = 20;
 
parameter RST_TIME = 3 ;
 
a uut(
    .clk          (clk     ),
    .rst_n        (rst_n   ),
    .dout         (dout1   )
 
);
 
 
initial begin
    clk = 0;
    forever
    #(CYCLE/2)
    clk=~clk;
end
 
initial begin
    rst_n = 1;
    #2;
    rst_n = 0;
    #(CYCLE*RST_TIME);
    rst_n = 1;
end
 
`ifdef DUMP_FSDB
    initial begin
        #100000;
        $finish;
    end
 
    initial begin
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars("+all");
    end
`endif
 
 
endmodule
 
