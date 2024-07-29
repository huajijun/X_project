module a(
    clk    ,
    rst_n  ,
 
    dout
);
 
parameter      DATA_W =         8;
 
input               clk    ;
input               rst_n  ;
 
output[DATA_W-1:0]  dout   ;
 
wire add_cnt;
wire end_cnt;
reg [5:0] cnt;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 0;
    end
    else if(add_cnt)begin
        if(end_cnt)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
end
 
assign add_cnt = 1;      
assign end_cnt = add_cnt && cnt== 8;  
 
assign dout = cnt;
endmodule
 

