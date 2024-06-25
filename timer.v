//---------------------------------
//--                             --
//--          N O T E S          --
//--                             --
//---------------------------------
//--    
//---------------------------------

//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

//---------------------------------
//--                             --
//--         M O D U L E         --
//--                             --
//---------------------------------

module timer(
    input clock,
    input reset,

    input [3:0] value,          //Valor BIN que é equivalente a segundos
    input start_timer,

    output expired,             //Retorna para o sistema principal
    output one_hz_enable,       //Retorna para o sistema principal
    output half_hz_enable       //Utilizado na Sirene como Input
);

//---------------------------------
//--                             --
//--     R E G I S T E R S       --
//--                             --
//---------------------------------

reg [30:0] t;       //Timer to later convert to Second

reg ohze;           //One Hz Enable
reg [3:0] contador_interno; //Contador Interno

//---------------------------------
//--                             --
//--           D U T s           --
//--                             --
//---------------------------------

//---------------------------------
//--                             --
//--        P R O C E S S        --
//--                             --
//---------------------------------

//Always responsável pela redução dos ciclos do T e também da inicialização
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        t <= 30'b0;
        contador_interno <= 4'b0;
    end else begin
        if(start_timer) begin
            t <= 0;
            contador_interno <= value;
        end else begin
            if(contador_interno > 0) begin 
                if(t < 100_000_000) begin  
                    t <= t + 1;
                    ohze <= 0;
                end else begin             
                    t <= 0;
                    ohze <= 1;
                    contador_interno <= contador_interno - 1;
                end                        
            end
        end
    end
end

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------
assign expired = (contador_interno <= 0)? 1 : 0;
assign one_hz_enable = ohze;

endmodule
