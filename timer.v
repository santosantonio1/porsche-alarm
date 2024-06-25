module timer(
    input clock, reset, start_timer,
    input[3:0] value, 
    output expired, half_hz_enable,
    output[3:0] value_display
);

reg[30:0] t;
reg[3:0] t_seg;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        t <= 30'b0;
    end else begin
        if(start_timer) begin
            t_seg <= value;
            t <= t_seg * 100_000_000;
        end else begin
            if(t > 0) begin
                t <= t - 1;
                if(t % 100_000_000)
                    t_seg <= t_seg - 1;
            end
        end
    end
end

assign expired = (t<=0) ? 1 : 0;

assign value_display = t_seg;

endmodule