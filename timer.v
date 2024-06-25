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
    output half_hz_enable,       //Utilizado na Sirene como Input

    output [3:0] value_display   //Utilizado para mostrar no Display o Valor
);

//---------------------------------
//--                             --
//--     R E G I S T E R S       --
//--                             --
//---------------------------------

reg [30:0] t;       //Timer to later convert to Second
reg [30:0] t2;      //Timer for Half Hertz Enable

reg ohze;           //One Hz Enable
reg hhze;           //Two Hz Enable

reg [3:0] contador_interno;        //Contador Interno
reg [4:0] contador_interno_dobro;  //Contador Secundário para Meio Segundo  

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
        t2 <= 30'b0;
        contador_interno <= 4'b0;
        contador_interno_dobro <= 5'b0;
        contador_half <= 2'b0;
        ohze <= 0;
        hhze <= 0;
    end else begin
        if(start_timer) begin
            t <= 0;
            t2 <= 0
            contador_interno <= value;
            contador_interno_dobro <= value * 2;
            ohze <= 0;
            hhze <= 0;
        end else 
        begin
            if(contador_interno > 0) begin 
                if(t < 100_000_000) begin  
                    t <= t + 1;
                    ohze <= 0;
                end else begin             
                    t <= 0;
                    ohze <= 1;
                end                        
            end else begin
                t <= 0;
                ohze <= 0;
            end
        end

        begin
            if(contador_interno_dobro > 0) begin
                if(t2 < 50_000_000) begin
                    t2 <= t2 + 1;
                end else begin
                    t2 <= 0;
                    hhze <= ~hhze;
                end
            end else begin
                t2 <= 0;
                hhze <= 0;
            end
        end
    end
end

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------

assign value_display = contador_interno;
assign expired = (contador_interno <= 0)? 1 : 0;
assign one_hz_enable = ohze;
assign half_hz_enable = hhze;

endmodule
