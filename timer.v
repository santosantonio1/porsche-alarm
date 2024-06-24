//---------------------------------
//--                             --
//--          N O T E S          --
//--                             --
//---------------------------------
//--    
//--    -> Segundo a implementação, temos um Clock de 100 MHz, ou seja,
//-- 1 segundo = 100.000.000 ciclos de Clock. Para fazer testes, será
//-- usado a lógica 1 segundo = 10 clicos de Clock <Por enquanto>
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

reg EA, PE;          // Estado Atual - Proxime Estado

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

//Process padrão para a atualização da FSM

//Process de operações durante a minha FSM

//FSM

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------



endmodule
