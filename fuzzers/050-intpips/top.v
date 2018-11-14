`include "setseed.vh"

module top(input clk, din, stb, output dout);
	reg [49:0] din_bits;
	wire [86:0] dout_bits;

	reg [49:0] din_shr;
	reg [86:0] dout_shr;

	always @(posedge clk) begin
		if (stb) begin
			din_bits <= din_shr;
			dout_shr <= dout_bits;
		end else begin
			din_shr <= {din_shr, din};
			dout_shr <= {dout_shr, din_shr[41]};
		end
	end

	assign dout = dout_shr[78];

	roi roi (
		.clk(clk),
		.din_bits(din_bits),
		.dout_bits(dout_bits)
	);
endmodule

module roi(input clk, input [49:0] din_bits, output [86:0] dout_bits);
	picorv32 picorv32 (
		.clk(clk),
		.resetn(din_bits[0]),
		.mem_valid(dout_bits[0]),
		.mem_instr(dout_bits[1]),
		.mem_ready(din_bits[1]),
		.mem_addr(dout_bits[33:2]),
		.mem_wdata(dout_bits[66:34]),
		.mem_wstrb(dout_bits[70:67]),
		.mem_rdata(din_bits[33:2])
	);

	randluts randluts (
		.din(din_bits[41:34]),
		.dout(dout_bits[78:71])
	);

	randbrams randbrams (
		.din(din_bits[49:42]),
		.dout(dout_bits[86:79])
	);
endmodule

module randluts(input [7:0] din, output [7:0] dout);
	localparam integer N =
			`SEED % 3 == 2 ? 250 :
			`SEED % 3 == 1 ? 100 : 10;

	function [31:0] xorshift32(input [31:0] xorin);
		begin
			xorshift32 = xorin;
			xorshift32 = xorshift32 ^ (xorshift32 << 13);
			xorshift32 = xorshift32 ^ (xorshift32 >> 17);
			xorshift32 = xorshift32 ^ (xorshift32 <<  5);
		end
	endfunction

	function [63:0] lutinit(input [7:0] a, b);
		begin
			lutinit[63:32] = xorshift32(xorshift32(xorshift32(xorshift32({a, b} ^ `SEED))));
			lutinit[31: 0] = xorshift32(xorshift32(xorshift32(xorshift32({b, a} ^ `SEED))));
		end
	endfunction

	wire [(N+1)*8-1:0] nets;

	assign nets[7:0] = din;
	assign dout = nets[(N+1)*8-1:N*8];

	genvar i, j;
	generate
		for (i = 0; i < N; i = i+1) begin:is
			for (j = 0; j < 8; j = j+1) begin:js
				localparam integer k = xorshift32(xorshift32(xorshift32(xorshift32((i << 20) ^ (j << 10) ^ `SEED)))) & 255;
				LUT6 #(
					.INIT(lutinit(i, j))
				) lut (
					.I0(nets[8*i+(k+0)%8]),
					.I1(nets[8*i+(k+1)%8]),
					.I2(nets[8*i+(k+2)%8]),
					.I3(nets[8*i+(k+3)%8]),
					.I4(nets[8*i+(k+4)%8]),
					.I5(nets[8*i+(k+5)%8]),
					.O(nets[8*i+8+j])
				);
			end
		end
	endgenerate
endmodule

module randbrams(input [7:0] din, output [7:0] dout);
    ram_RAMB18E1 #(.LOC("RAMB18_X0Y20")) r0(.clk(clk), .din(din[  0 +: 8]), .dout(dout[  0 +: 8]));
endmodule

module ram_RAMB18E1 (input clk, input [7:0] din, output [7:0] dout);
    parameter LOC = "";

    parameter INIT0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    parameter INIT = 256'h0000000000000000000000000000000000000000000000000000000000000000;

    parameter IS_CLKARDCLK_INVERTED = 1'b0;
    parameter IS_CLKBWRCLK_INVERTED = 1'b0;
    parameter IS_ENARDEN_INVERTED = 1'b0;
    parameter IS_ENBWREN_INVERTED = 1'b0;
    parameter IS_RSTRAMARSTRAM_INVERTED = 1'b0;
    parameter IS_RSTRAMB_INVERTED = 1'b0;
    parameter IS_RSTREGARSTREG_INVERTED = 1'b0;
    parameter IS_RSTREGB_INVERTED = 1'b0;
    parameter RAM_MODE = "TDP";
    parameter WRITE_MODE_A = "WRITE_FIRST";
    parameter WRITE_MODE_B = "WRITE_FIRST";

    parameter DOA_REG = 1'b0;
    parameter DOB_REG = 1'b0;
    parameter SRVAL_A = 18'b0;
    parameter SRVAL_B = 18'b0;
    parameter INIT_A = 18'b0;
    parameter INIT_B = 18'b0;

    parameter READ_WIDTH_A = 0;
    parameter READ_WIDTH_B = 0;
    parameter WRITE_WIDTH_A = 0;
    parameter WRITE_WIDTH_B = 0;

    (* LOC=LOC *)
    RAMB18E1 #(
            .INITP_00(INIT),
            .INITP_01(INIT),
            .INITP_02(INIT),
            .INITP_03(INIT),
            .INITP_04(INIT),
            .INITP_05(INIT),
            .INITP_06(INIT),
            .INITP_07(INIT),

            .INIT_00(INIT0),
            .INIT_01(INIT),
            .INIT_02(INIT),
            .INIT_03(INIT),
            .INIT_04(INIT),
            .INIT_05(INIT),
            .INIT_06(INIT),
            .INIT_07(INIT),
            .INIT_08(INIT),
            .INIT_09(INIT),
            .INIT_0A(INIT),
            .INIT_0B(INIT),
            .INIT_0C(INIT),
            .INIT_0D(INIT),
            .INIT_0E(INIT),
            .INIT_0F(INIT),
            .INIT_10(INIT),
            .INIT_11(INIT),
            .INIT_12(INIT),
            .INIT_13(INIT),
            .INIT_14(INIT),
            .INIT_15(INIT),
            .INIT_16(INIT),
            .INIT_17(INIT),
            .INIT_18(INIT),
            .INIT_19(INIT),
            .INIT_1A(INIT),
            .INIT_1B(INIT),
            .INIT_1C(INIT),
            .INIT_1D(INIT),
            .INIT_1E(INIT),
            .INIT_1F(INIT),
            .INIT_20(INIT),
            .INIT_21(INIT),
            .INIT_22(INIT),
            .INIT_23(INIT),
            .INIT_24(INIT),
            .INIT_25(INIT),
            .INIT_26(INIT),
            .INIT_27(INIT),
            .INIT_28(INIT),
            .INIT_29(INIT),
            .INIT_2A(INIT),
            .INIT_2B(INIT),
            .INIT_2C(INIT),
            .INIT_2D(INIT),
            .INIT_2E(INIT),
            .INIT_2F(INIT),
            .INIT_30(INIT),
            .INIT_31(INIT),
            .INIT_32(INIT),
            .INIT_33(INIT),
            .INIT_34(INIT),
            .INIT_35(INIT),
            .INIT_36(INIT),
            .INIT_37(INIT),
            .INIT_38(INIT),
            .INIT_39(INIT),
            .INIT_3A(INIT),
            .INIT_3B(INIT),
            .INIT_3C(INIT),
            .INIT_3D(INIT),
            .INIT_3E(INIT),
            .INIT_3F(INIT),

            .IS_CLKARDCLK_INVERTED(IS_CLKARDCLK_INVERTED),
            .IS_CLKBWRCLK_INVERTED(IS_CLKBWRCLK_INVERTED),
            .IS_ENARDEN_INVERTED(IS_ENARDEN_INVERTED),
            .IS_ENBWREN_INVERTED(IS_ENBWREN_INVERTED),
            .IS_RSTRAMARSTRAM_INVERTED(IS_RSTRAMARSTRAM_INVERTED),
            .IS_RSTRAMB_INVERTED(IS_RSTRAMB_INVERTED),
            .IS_RSTREGARSTREG_INVERTED(IS_RSTREGARSTREG_INVERTED),
            .IS_RSTREGB_INVERTED(IS_RSTREGB_INVERTED),
            .RAM_MODE(RAM_MODE),
            .WRITE_MODE_A(WRITE_MODE_A),
            .WRITE_MODE_B(WRITE_MODE_B),

            .DOA_REG(DOA_REG),
            .DOB_REG(DOB_REG),
            .SRVAL_A(SRVAL_A),
            .SRVAL_B(SRVAL_B),
            .INIT_A(INIT_A),
            .INIT_B(INIT_B),

            .READ_WIDTH_A(READ_WIDTH_A),
            .READ_WIDTH_B(READ_WIDTH_B),
            .WRITE_WIDTH_A(WRITE_WIDTH_A),
            .WRITE_WIDTH_B(WRITE_WIDTH_B)
        ) ram (
            .CLKARDCLK(din[0]),
            .CLKBWRCLK(din[1]),
            .ENARDEN(din[2]),
            .ENBWREN(din[3]),
            .REGCEAREGCE(din[4]),
            .REGCEB(din[5]),
            .RSTRAMARSTRAM(din[6]),
            .RSTRAMB(din[7]),
            .RSTREGARSTREG(din[0]),
            .RSTREGB(din[1]),
            .ADDRARDADDR(din[2]),
            .ADDRBWRADDR(din[3]),
            .DIADI(din[4]),
            .DIBDI(din[5]),
            .DIPADIP(din[6]),
            .DIPBDIP(din[7]),
            .WEA(din[0]),
            .WEBWE(din[1]),
            .DOADO(dout[0]),
            .DOBDO(dout[1]),
            .DOPADOP(dout[2]),
            .DOPBDOP(dout[3]));

endmodule

