#!/usr/bin/env python3

import re

from prjxray.segmaker import Segmaker


def load():
    # connections in each tile
    tiledata = dict()
    # all possible connections
    # pipdata[pip name] = (src pip, dst pip)
    pipdata = dict()
    # PIPs that don't encode bits
    ignpip = set()

    print("Loading tags from design.txt.")
    with open("design.txt", "r") as f:
        for line in f:
            # pip => an in use pip
            tile, pip, src, dst, pnum, pdir = line.split()
            _, pip = pip.split(".")
            _, src = src.split("/")
            _, dst = dst.split("/")
            # Number of pips that can drive destination
            pnum = int(pnum)
            # Property IS_DIRECTIONAL
            pdir = int(pdir)

            if tile not in tiledata:
                tiledata[tile] = {"pips": set(), "srcs": set(), "dsts": set()}

            if pip in pipdata:
                assert pipdata[pip] == (src, dst)
            else:
                pipdata[pip] = (src, dst)

            tiledata[tile]["pips"].add(pip)
            tiledata[tile]["srcs"].add(src)
            tiledata[tile]["dsts"].add(dst)

            if pdir == 0:
                tiledata[tile]["srcs"].add(dst)
                tiledata[tile]["dsts"].add(src)

            if pnum == 1 or pdir == 0 or \
                    re.match(r"^(L[HV]B?|G?CLK)(_L)?(_B)?[0-9]", src) or \
                    re.match(r"^(L[HV]B?|G?CLK)(_L)?(_B)?[0-9]", dst) or \
                    re.match(r"^(CTRL|GFAN)(_L)?[0-9]", dst):
                ignpip.add(pip)

    return tiledata, pipdata, ignpip


def run():
    '''
    Basic idea
    Index all observed possible connections within an INT tile
    Index all connections observed per tile
    For each observed possible INT connection:
        If the connection is observed in that tile instance, add symbol as one
        If no connection from that PIP group is placed, add symbol as a zero

    You must have at least one tile where a connection is not used
    Since there are multiple tile types, this should be easy
    '''

    tiledata, pipdata, ignpip = load()

    segmk = Segmaker("design.bits")

    # Iterate over all placed pips
    for tile, pips_srcs_dsts in tiledata.items():
        pips = pips_srcs_dsts["pips"]
        srcs = pips_srcs_dsts["srcs"]
        dsts = pips_srcs_dsts["dsts"]

        # Check all possible connections
        for pip, src_dst in pipdata.items():
            src, dst = src_dst
            if pip in ignpip:
                pass
            # Used in this particular tile?
            elif pip in pips:
                segmk.add_tile_tag(tile, "%s.%s" % (dst, src), 1)
            # No bits set on this particular connection?
            # Without this check shared bits won't solve correctly
            elif dst not in dsts:
                segmk.add_tile_tag(tile, "%s.%s" % (dst, src), 0)

    segmk.compile()
    segmk.write()


run()
