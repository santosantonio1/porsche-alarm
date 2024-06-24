module timer(
    input clock, reset, en, load,
    input[3:0] t_default,
    output waited, output[3:0] t_display
);

reg[30:0] t;
reg p;
reg[3:0] t_seg;

always @(posedge clock, posedge reset) begin
    if(reset) begin
        t <= 0;
        t_seg <= 0;
        p <= 0;
    end else begin
        if(load) begin
            t <= t_default * 100_000_000;
            t_seg <= t_default;
            p <= 0;
        end
        else if(en) begin
            if(t>0) begin
                t <= t - 1;
                if(t%100_000_000 == 0) 
                    t_seg <= t_seg - 1;
            end
            else p <= 1;
        end
    end
end

assign waited = (en) ? p : 0; 
assign t_display = t_seg;

endmodule
