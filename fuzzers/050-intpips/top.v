`include "setseed.vh"

`define DIN_N 150
`define DOUT_N 151

module top(input clk, din, stb, output dout);

    reg [`DIN_N-1:0] din_bits;
    wire [`DOUT_N-1:0] dout_bits;

    reg [`DIN_N-1:0] din_shr;
    reg [`DOUT_N-1:0] dout_shr;

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

module roi(input clk, input [`DIN_N-1:0] din_bits, output [`DOUT_N-1:0] dout_bits);
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
		.clk(clk),
		.din(din_bits[149:42]),
		.dout(dout_bits[150:79])
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

    /*
    Chain luts together
    din forms seed feeding the first group of luts
    Eight of these are grouped together to form another group
    Without k, the first 5/8 would feed to next group
    However, k adds random offsets that will feed to any 1-5
    of the previous 8 will get selected as inputs
    */
	wire [(N+1)*8-1:0] nets;

	assign nets[7:0] = din;
	assign dout = nets[(N+1)*8-1:N*8];

	genvar i, j;
	generate
		for (i = 0; i < N; i = i+1) begin:is
			for (j = 0; j < 8; j = j+1) begin:js
				localparam integer k = xorshift32(xorshift32(xorshift32(xorshift32((i << 20) ^ (j << 10) ^ `SEED)))) & 255;
				(* KEEP, DONT_TOUCH *)
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

module randbrams(input wire clk, input [107:0] din, output [71:0] dout);
	localparam integer N = 10;

	wire [(N+1)*108-1:0] nets;

	assign nets[107:0] = din;
	assign dout = nets[(N+1)*108-1:N*108];

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

	genvar i;
	generate
		for (i = 0; i < N; i = i+1) begin:is
			localparam integer k = xorshift32(xorshift32(xorshift32(xorshift32((i << 20) ^ `SEED)))) & 255;
			localparam dout_base = 108*i+108;
			//Leave 1 bit on edges to prevent boundary conditions
			//XXX: will this loose a pip we need?
			localparam dout_off = k%(108-72-2) + 1;

			//Randomly assign into next output block so that next input gets something interesting
            b36_maxwidth b0(.clk(clk), .din(nets[108*i]), .dout(nets[dout_base+dout_off+72-1:dout_base+dout_off]));
            //Fixes "ERROR: [DRC NDRV-1] Driverless Nets"
            assign nets[dout_base+dout_off-1:dout_base] = 108'b0;
            assign nets[dout_base+108-1:dout_base+dout_off+72] = 108'b0;
        end
    endgenerate
endmodule

/*
36 kb width => 1024 addresses => 10 bit address
Hook up everything anyway?
Any restrictions on address bus?
*/
module b36_maxwidth(input wire clk, input [107:0] din, output [71:0] dout);
    (* KEEP, DONT_TOUCH *)
    RAMB36E1 #(
            .RAM_MODE("TDP"),

            .READ_WIDTH_A(36),
            .READ_WIDTH_B(36),
            .WRITE_WIDTH_A(36),
            .WRITE_WIDTH_B(36)
        ) ram (
            .CLKARDCLK(clk),
            .CLKBWRCLK(clk),
            .ENARDEN(din[0]),
            .ENBWREN(din[1]),
            .REGCEAREGCE(din[2]),
            .REGCEB(din[3]),
            .RSTRAMARSTRAM(din[4]),
            .RSTRAMB(din[5]),
            .RSTREGARSTREG(din[6]),
            .RSTREGB(din[7]),
            //Address
            .ADDRARDADDR(din[15:8]),
            .ADDRBWRADDR(din[23:16]),
            //Data in
            .DIADI(din[55:24]),
            .DIBDI(din[87:56]),
            //Data in (parity)
            .DIPADIP(din[91:88]),
            .DIPBDIP(din[95:92]),
            //Write enable
            .WEA(din[99:96]),
            .WEBWE(din[107:100]),
            .DOADO(dout[31:0]),
            .DOBDO(dout[63:32]),
            .DOPADOP(dout[67:64]),
            .DOPBDOP(dout[71:68]));
endmodule

