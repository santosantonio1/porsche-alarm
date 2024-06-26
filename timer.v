//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

module timer(
    input clock, reset, start_timer,
    input[3:0] value, 
    output expired, one_hz_enable, half_hz_enable,
    output[3:0] value_display
);

//---------------------------------
//--                             --
//--     R E G I S T E R S       --
//--                             --
//---------------------------------

reg [3:0] t_seg;
reg [30:0] t;
reg [30:0] t2;
reg ohze, hhze;

//---------------------------------
//--                             --
//--        P R O C E S S        --
//--                             --
//---------------------------------

//Always responsável pela ativação do One_Hz_Enable
always @(posedge clock, posedge reset) begin
    if(reset) begin
        t <= 31'b0;
        ohze <= 1'b0;
    end else begin
        if(start_timer) begin
            t <= 31'b0;
            ohze <= 1'b0;
        end else begin
            if(t < 100_000_000) begin
                t <= t + 1;
                ohze <= 1'b0;
            end else begin
                t <= 31'b0;
                ohze <= 1'b1;
            end
        end
    end
end

//Always responsável pela ativação do Half_Hz_Enable
always @(posedge clock, posedge reset) begin
    if(reset) begin
        t2 <= 31'b0;
        hhze <= 1'b0;
    end else begin
            if(t2 < 50_000_000) begin
                t2 <= t2 + 1;
                hhze <= 1'b0;
            end else begin
                t2 <= 31'b0;
                hhze <= 1'b1;
            end
    end
end

//Always responsável pela redução do Segundo (Utilizado no Timer para Expired e Display)
always @(posedge clock, posedge reset) begin
    if(reset) begin
        t_seg <= 4'b0;
    end else begin
        if(start_timer) begin  
            t_seg <= value;
        end else begin
            if(t_seg > 0) begin
                if(ohze) t_seg <= t_seg - 1;
            end
        end
    end
end

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------

assign value_display = t_seg;
assign expired = (t_seg <= 0);
assign one_hz_enable = ohze;
assign half_hz_enable = hhze;

endmodule
