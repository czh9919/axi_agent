This directory is intended to host AXI-Lite UVM package related include files
and to be added to the simulator include search path via .f files.

Typical usage:
- Put any shared SVH/SV headers for axi_lite_pkg into this folder.
- Add '+incdir+./agent/include' (or absolute path) in your .f file.

