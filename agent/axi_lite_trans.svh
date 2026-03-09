// ------------------------------------------------------------
// Transaction
// ------------------------------------------------------------
class axi_lite_trans extends uvm_sequence_item;
  `uvm_object_utils(axi_lite_trans)

  rand axi_lite_cmd_e cmd;
  rand bit [AXI_LITE_ADDR_WIDTH-1:0] addr;
  rand bit [AXI_LITE_DATA_WIDTH-1:0] data;
  rand bit [(AXI_LITE_DATA_WIDTH/8)-1:0] strb;

  // Response
  bit [1:0] resp;

  // Constraints for AXI-Lite alignment
  constraint c_align {
    addr[1:0] == 2'b00;
  }

  function new(string name="axi_lite_trans");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("cmd=%s addr=0x%0h data=0x%0h strb=0x%0h resp=0x%0h",
                     cmd.name(), addr, data, strb, resp);
  endfunction
endclass : axi_lite_trans