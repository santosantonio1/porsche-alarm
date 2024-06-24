module timer(
    input clock, reset, en, load,
    input[3:0] t_default,
    output waited
);

reg[30:0] t;
reg p;

always @(posedge clock, posedge reset) begin
    if(reset) begin
        t <= 0;
        p <= 0;
    end else begin
        if(load) begin
            t <= t_default * 100_000_000;
            p <= 0;
        end
        else if(en) begin
            if(t>0) t <= t - 1;
            else p <= 1;
        end
    end
end

assign waited = (en) ? p : 0; 

endmodule
