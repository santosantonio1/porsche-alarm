`timescale 1 ns/10 ps

module tb;

localparam PERIOD = 10;

reg clock, reset, ignition, d_door, p_door, switch, pedal;
reg[3:0] T_ARM_DELAY, T_DRIVER_DELAY, T_PASSENGER_DELAY, T_ALARM_ON;

wire set, siren;

top TOP_DRIVER(
    .clock(clock), .reset(reset), .ignition(ignition),
    .d_door(d_door), .p_door(p_door), .switch(switch), .pedal(pedal), 
    .T_ARM_DELAY(T_ARM_DELAY), .T_DRIVER_DELAY(T_DRIVER_DELAY), 
    .T_PASSENGER_DELAY(T_PASSENGER_DELAY), .T_ALARM_ON(T_ALARM_ON), 
    .set(set), .siren(siren)
);


initial begin
    reset = 1;
    T_ARM_DELAY = 4'd5;
    T_DRIVER_DELAY = 4'd7;
    T_PASSENGER_DELAY = 4'd6;
    T_ALARM_ON = 4'd3;
    
    ignition = 1;
    d_door = 0;
    p_door = 0;
    switch = 0;
    pedal = 0;
    
    #(2*PERIOD)
    reset = 0;
    #(2*PERIOD)

    ignition = 0;
    #PERIOD
    d_door = 1;
    #PERIOD
    d_door = 0;

    wait(set == 1)
    #(4*PERIOD)
    d_door = 1;

    wait(siren == 1)
    #(2*PERIOD)
    d_door = 0;
    wait(siren == 0)
    #(4*PERIOD)
    ignition = 1;
    switch = 1;
    pedal = 1;
    #(PERIOD)
    switch = 0;
    pedal = 0;

end

initial
begin
    clock = 0;
    forever #(PERIOD/2) clock = ~clock;
end

endmodule