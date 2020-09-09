// audio data processing
// stereo sigma/delta bitstream modulator
//
// bit resolution reduced from 15 bits to 9 bits mix by OKK
// this module is to be moved out of the paula tree!!! and instantiated in the minimig top file.
// Infact it should be instantiated in the mist top file as this dac type is platform specific!


module audio_sigmadelta
(
  input   clk,                //bus clock
  input   clk7_en,
  input   cck,
  input  [8:0] ldatasum,      // left channel data
  input  [8:0] rdatasum,      // right channel data
  output  reg left = 0,       //left bitstream output
  output  reg right = 0       //right bitsteam output
);


// local signals
localparam DW = 9;
localparam CW = 2;
localparam RW  = 4;
localparam A1W = 2;
localparam A2W = 5;

wire [DW+2+0  -1:0] sd_l_er0, sd_r_er0;
reg  [DW+2+0  -1:0] sd_l_er0_prev=0, sd_r_er0_prev=0;
wire [DW+A1W+2-1:0] sd_l_aca1,  sd_r_aca1;
wire [DW+A2W+2-1:0] sd_l_aca2,  sd_r_aca2;
reg  [DW+A1W+2-1:0] sd_l_ac1=0, sd_r_ac1=0;
reg  [DW+A2W+2-1:0] sd_l_ac2=0, sd_r_ac2=0;
wire [DW+A2W+3-1:0] sd_l_quant, sd_r_quant;

// LPF noise LFSR (DISABLED!)
reg [24-1:0] seed_out = 0;

// DISABLED Interpolator!
wire [DW+0-1:0] ldata_int_out, rdata_int_out;

assign ldata_int_out = ldatasum;
assign rdata_int_out = rdatasum;



// input gain x3
wire [DW+2-1:0] ldata_gain, rdata_gain;
assign ldata_gain = {ldata_int_out[DW-1], ldata_int_out, 1'b0} + {{(2){ldata_int_out[DW-1]}}, ldata_int_out};
assign rdata_gain = {rdata_int_out[DW-1], rdata_int_out, 1'b0} + {{(2){rdata_int_out[DW-1]}}, rdata_int_out};

// accumulator adders
assign sd_l_aca1 = {{(A1W){ldata_gain[DW+2-1]}}, ldata_gain} - {{(A1W){sd_l_er0[DW+2-1]}}, sd_l_er0} + sd_l_ac1;
assign sd_r_aca1 = {{(A1W){rdata_gain[DW+2-1]}}, rdata_gain} - {{(A1W){sd_r_er0[DW+2-1]}}, sd_r_er0} + sd_r_ac1;

assign sd_l_aca2 = {{(A2W-A1W){sd_l_aca1[DW+A1W+2-1]}}, sd_l_aca1} - {{(A2W){sd_l_er0[DW+2-1]}}, sd_l_er0} - {{(A2W+1){sd_l_er0_prev[DW+2-1]}}, sd_l_er0_prev[DW+2-1:1]} + sd_l_ac2;
assign sd_r_aca2 = {{(A2W-A1W){sd_r_aca1[DW+A1W+2-1]}}, sd_r_aca1} - {{(A2W){sd_r_er0[DW+2-1]}}, sd_r_er0} - {{(A2W+1){sd_r_er0_prev[DW+2-1]}}, sd_r_er0_prev[DW+2-1:1]} + sd_r_ac2;

// accumulators
always @ (posedge clk) begin
  //if (clk7_en && cck) begin
    sd_l_ac1 <= #1 sd_l_aca1;
    sd_r_ac1 <= #1 sd_r_aca1;
    sd_l_ac2 <= #1 sd_l_aca2;
    sd_r_ac2 <= #1 sd_r_aca2;
  //end
end

// value for quantizaton
assign sd_l_quant = {sd_l_ac2[DW+A2W+2-1], sd_l_ac2} + {{(DW+A2W+3-RW){seed_out[RW-1]}}, seed_out[RW-1:0]};
assign sd_r_quant = {sd_r_ac2[DW+A2W+2-1], sd_r_ac2} + {{(DW+A2W+3-RW){seed_out[RW-1]}}, seed_out[RW-1:0]};

// error feedback
assign sd_l_er0 = sd_l_quant[DW+A2W+3-1] ? {1'b1, {(DW+2-1){1'b0}}} : {1'b0, {(DW+2-1){1'b1}}};
assign sd_r_er0 = sd_r_quant[DW+A2W+3-1] ? {1'b1, {(DW+2-1){1'b0}}} : {1'b0, {(DW+2-1){1'b1}}};

always @ (posedge clk) begin
  //if (clk7_en && cck) begin
    sd_l_er0_prev <= #1 (&sd_l_er0) ? sd_l_er0 : sd_l_er0+1;
    sd_r_er0_prev <= #1 (&sd_r_er0) ? sd_r_er0 : sd_r_er0+1;
  //end
end

// output
always @ (posedge clk) begin
  //if (clk7_en && cck) begin
    left  <= #1 (~|ldata_gain) ? ~left  : ~sd_l_er0[DW+2-1];
    right <= #1 (~|rdata_gain) ? ~right : ~sd_r_er0[DW+2-1];
  //end
end

endmodule


/*module audio_sigmadelta
(
  // This module crashes!

  input   clk,        	     //bus clock
  input   clk7_en,
  input	  cck,
  input  [8:0] ldatasum,     // left channel data
  input  [8:0] rdatasum,     // right channel data
  output  left,        	     //left bitstream output
  output  right              //right bitsteam output
);

reg [9:0] PWM_accumulatorL;
reg [9:0] PWM_accumulatorR;

assign left = PWM_accumulatorL[9];
assign right = PWM_accumulatorR[9];

always @(posedge clk) begin
	if (clk7_en && cck) begin
		PWM_accumulatorL <= PWM_accumulatorL[8:0] + ldatasum;
		PWM_accumulatorR <= PWM_accumulatorR[8:0] + rdatasum;
	end
end

endmodule*/

