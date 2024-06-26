//------------------------------------------------------------
//
//
//                  SIREN GENERATOR DRIVER
//
//
//------------------------------------------------------------
module siren_generator(
    input enable_siren, half_hz_enable,
    output[2:0] siren
);

// Blue/Red/OFF
assign siren = (enable_siren && half_hz_enable) ? 3'b001 :
               (enable_siren && !half_hz_enable) ? 3'b100 : 0;

endmodule