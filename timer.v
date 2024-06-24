module timer(
    input clock, reset, start_timer,
    input[3:0] value, 
    output expired, one_hz_enable, half_hz_enable
);

reg[30:0] t;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        t <= 30'b0;
    end else begin
        if(start_timer)
    end
end


endmodule