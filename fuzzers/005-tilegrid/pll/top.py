import os
import random
random.seed(int(os.getenv("SEED"), 16))
from prjxray import util
from prjxray import verilog


def gen_sites():
    for tile_name, site_name, _site_type in util.get_roi().gen_sites(
        ['PLLE2_ADV']):
        yield tile_name, site_name


def write_params(params):
    pinstr = 'tile,val,site\n'
    for tile, (site, val) in sorted(params.items()):
        pinstr += '%s,%s,%s\n' % (tile, val, site)
    open('params.csv', 'w').write(pinstr)


def run():
    print(
        '''
module top(input clk, stb, di, output do);
    localparam integer DIN_N = 8;
    localparam integer DOUT_N = 8;

    reg [DIN_N-1:0] din;
    wire [DOUT_N-1:0] dout;

    reg [DIN_N-1:0] din_shr;
    reg [DOUT_N-1:0] dout_shr;

    always @(posedge clk) begin
        din_shr <= {din_shr, di};
        dout_shr <= {dout_shr, din_shr[DIN_N-1]};
        if (stb) begin
            din <= din_shr;
            dout_shr <= dout;
        end
    end

    assign do = dout_shr[DOUT_N-1];
    ''')

    params = {}
    # FIXME: can't LOC?
    # only one for now, worry about later
    sites = list(gen_sites())
    assert len(sites) == 1
    for (tile_name, site_name), isone in zip(sites,
                                             util.gen_fuzz_states(len(sites))):
        # 0 is invalid
        # shift one bit, keeping LSB constant
        CLKOUT1_DIVIDE = {0: 2, 1: 3}[isone]
        params[tile_name] = (site_name, CLKOUT1_DIVIDE)

        print(
            '''
    (* KEEP, DONT_TOUCH *)
    PLLE2_ADV #(/*.LOC("%s"),*/ .CLKOUT1_DIVIDE(%u)) dut_%s(
            .CLKFBOUT(),
            .CLKOUT0(),
            .CLKOUT1(),
            .CLKOUT2(),
            .CLKOUT3(),
            .CLKOUT4(),
            .CLKOUT5(),
            .DRDY(),
            .LOCKED(),
            .DO(),
            .CLKFBIN(),
            .CLKIN1(),
            .CLKIN2(),
            .CLKINSEL(),
            .DCLK(),
            .DEN(),
            .DWE(),
            .PWRDWN(),
            .RST(),
            .DI(),
            .DADDR());
''' % (site_name, CLKOUT1_DIVIDE, site_name))

    print("endmodule")
    write_params(params)


if __name__ == '__main__':
    run()
