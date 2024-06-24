//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3

//---------------------------------
//--                             --
//--         M O D U L E         --
//--                             --
//---------------------------------

module top(
    input clock, reset, ignition, door_driver, door_pass, hidden_sw, pedal, reprogram,
    input[1:0] time_select_param,
    input[3:0] time_value,
    output status, fuel_pump_status,
    output[2:0] siren
);

//---------------------------------
//--                             --
//--   R E G I S T E R S         --
//--                             --
//---------------------------------

    //FSM States Update
    reg[1:0] EA, PE;

    //Debouncers Outputs
    reg c_ignition, c_door_driver, c_door_pass, c_hidden_sw, c_pedal, c_reprogram;
    reg tsp1, tsp0, t3, t2, t1, t0;

    //Register for Interval
    reg [1:0] interval;

    //Wires
    wire siren_color;
    wire [3:0] value;

//---------------------------------
//--                             --
//--   D E B O U N C E R S       --
//--                             --
//---------------------------------

debouncer DEB_IG(
    clock, reset, ignition, c_ignition
);

debouncer DEB_DOOR_DRIVER(
    clock, reset, door_driver, c_door_driver
);

debouncer DEB_DOOR_PASS(
    clock, reset, door_pass, c_door_pass
);

debouncer DEB_HIDDEN_SW(
    clock, reset, hidden_sw, c_hidden_sw
);

debouncer DEB_PEDAL(
    clock, reset, pedal, c_pedal
);

debouncer DEB_REPROGRAM(
    clock, reset, reprogram, c_reprogram
);

debouncer DEB_TIME_SELECT_PARAM_1(
    clock, reset, time_select_param[1], tsp1
);

debouncer DEB_TIME_SELECT_PARAM_0(
    clock, reset, time_select_param[0], tsp0
);

debouncer DEB_TIME_VALUE_3(
    clock, reset, time_value[3], t3
);

debouncer DEB_TIME_VALUE_2(
    clock, reset, time_value[2], t2
);

debouncer DEB_TIME_VALUE_1(
    clock, reset, time_value[1], t1
);

debouncer DEB_TIME_VALUE_0(
    clock, reset, time_value[0], t0
);

//-----------------------------------------------------------------------

//---------------------------------
//--                             --
//--         D U T ' s           --
//--                             --
//---------------------------------

fuel_pump FUEL_PUMP_DRIVER(
    clock, reset, c_ignition, c_hidden_sw, c_pedal, fuel_pump_status
);

time_parameters TIME_PARAMETERS_DRIVER(
    clock, reset, time_param_sel, time_value, reprogram, interval, value
);

rgb SIREN_DRIVER(
    siren_color
);

//-----------------------------------------------------------------------

endmodule