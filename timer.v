module timer(
    input clock, reset, start_timer,
    input[3:0] value, 
    output expired, one_hz_enable, half_hz_enable,
    output[3:0] value_display
);

reg[30:0] t, half_hz_counter;
reg[3:0] t_seg;

reg ohze, hhze;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        t_seg <= 0;
    end else begin
        if(start_timer) begin
            t_seg <= value;
        end else begin
            if(ohze) begin
                if(t_seg > 0)
                    t_seg <= t_seg - 1;
            end
        end
    end
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        ohze <= 0;
        t <= 0;
    end else begin
        if(start_timer) begin
            ohze <= 0;
            t <= 0;
        end else begin
            if(t < 100_000_000) begin
                t <= t + 1;
                ohze <= 0;
            end else begin
                ohze <= 1;
                t <= 0;
            end
        end
    end
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        half_hz_counter <= 0;
        hhze <= 0;
    end else begin
        if(half_hz_counter < 50_000_000) begin
            half_hz_counter <= half_hz_counter + 1;
        end else begin
            half_hz_counter <= 0;
            hhze <= ! hhze;
        end

    end
end

assign expired = (t<=0) ? 1 : 0;

assign value_display = t_seg;

assign half_hz_enable = hhze;

endmodule