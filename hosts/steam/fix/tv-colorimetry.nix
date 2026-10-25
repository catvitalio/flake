{ ... }:

{
  # The EDID this TV serves has corrupt chromaticity: the white point reads
  # 0.2832/0.2978 instead of D65, with narrowed primaries to match. gamescope
  # takes the display colorimetry from there and also sends it to the TV as the
  # default HDR mastering metadata, so the TV expands an already correct picture
  # and HDR comes out oversaturated (gamescope issue #1887). A known display
  # wins over the EDID: the backend only reads the EDID chromaticity when no
  # profile supplied any. These are the TV's own numbers from the ports whose
  # EDID is intact, with the white point set to exact D65.
  environment.etc."gamescope/scripts/tcl-65c755.lua".text = ''
    gamescope.config.known_displays.tcl_65c755 = {
        pretty_name = "TCL 65C755",
        colorimetry = {
            r = { x = 0.6729, y = 0.3135 },
            g = { x = 0.2754, y = 0.6475 },
            b = { x = 0.1504, y = 0.0645 },
            w = { x = 0.3127, y = 0.3290 },
        },
        matches = function(display)
            if display.vendor == "TCL" and display.product == 0x9653 then
                debug("[tcl_65c755] Matched TCL product 0x9653")
                return 5100
            end

            return -1
        end
    }
    debug("Registered TCL 65C755 as a known display")
  '';
}
