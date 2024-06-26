`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3
`define STOP_ALARM 4

`define WAIT_IGNITION_OFF 0
`define WAIT_DOOR_OPEN 1
`define WAIT_DOOR_CLOSE 2
`define START_ARM_DELAY 3

module fsm(
    input clock, reset, ignition, door_driver, door_pass, one_hz_enable, expired, reprogram,
    output start_timer, status, enable_siren, 
    output[1:0] interval, ARM_EA_DISPLAY,
    output[2:0] EA_DISPLAY
);

reg[2:0] EA, PE;
reg[1:0] ARM_EA, ARM_PE, time_sel;

wire arm;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        EA <= `SET;
    end else begin
        EA <= PE;
    end
end

always @*
begin
    if(reprogram) begin 
        PE <= `SET;
    end else begin 
    if(ignition)  PE <= `OFF;
    else begin
        case(EA)
            `SET:
            begin
                if(door_driver || door_pass)    PE <= `TRIGGER;
                else        PE <= `SET;
            end

            `OFF:
            begin
                if(expired && arm)  PE <= `SET;
                else PE <= `OFF;
            end

            `TRIGGER:
            begin
                if(expired)     PE <= `ON;
                else            PE <= `TRIGGER;
            end

            `ON:
            begin
                if(!door_driver && !door_pass)     PE <= `STOP_ALARM;
                else    PE <= `ON;
            end

            `STOP_ALARM:
            begin
                if(expired)     PE <= `SET;
                else if(door_driver || door_pass)   PE <= `ON;
                else    PE <= `STOP_ALARM;
            end

            default: PE <= `SET;

        endcase
        end
    end
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        ARM_EA <= `WAIT_IGNITION_OFF;
    end else begin
        ARM_EA <= ARM_PE;
    end
end

always @*
begin
    case(ARM_EA)
        `WAIT_IGNITION_OFF:
        begin
            if(!ignition)     ARM_PE <= `WAIT_DOOR_OPEN;
            else        ARM_PE <= `WAIT_IGNITION_OFF;
        end 

        `WAIT_DOOR_OPEN:
        begin
            if(door_driver)       ARM_PE <= `WAIT_DOOR_CLOSE;
            else        ARM_PE <= `WAIT_DOOR_OPEN;
        end

        `WAIT_DOOR_CLOSE:
        begin
            if(ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(!door_driver && !door_pass)      ARM_PE <= `START_ARM_DELAY;
            else        ARM_PE <= `WAIT_DOOR_CLOSE;
        end 

        `START_ARM_DELAY:
        begin
            if(ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(door_driver || door_pass)   ARM_PE <= `WAIT_DOOR_CLOSE;
            else        ARM_PE <= `START_ARM_DELAY;
        end 
    endcase
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        time_sel <= 1;
    end else begin
        case(EA)
            `SET:
            begin
                if(door_pass) time_sel <= 2;
                else time_sel <= 1;
            end
            `OFF:   time_sel <= 0;

            `TRIGGER:   time_sel <= 3;
            // default: time_sel <= 3;
        endcase
    end
end

assign start_timer = (EA == `TRIGGER && expired) || 
                     (EA == `OFF && ARM_EA == `WAIT_DOOR_CLOSE && ARM_PE == `START_ARM_DELAY) ||
                     (EA == `SET && PE == `TRIGGER) ||
                     (EA == `ON && PE == `STOP_ALARM);

assign arm = (ARM_EA == `START_ARM_DELAY);

assign status = ((EA == `SET && (one_hz_enable)) || (EA == `TRIGGER) || (EA == `ON) || EA == (`STOP_ALARM));

assign enable_siren = (EA == `ON || EA == `STOP_ALARM);

assign interval = time_sel;

assign EA_DISPLAY = EA;
assign ARM_EA_DISPLAY = ARM_EA;

endmodule