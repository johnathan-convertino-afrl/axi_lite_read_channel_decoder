# AXI Lite Read Channel Decoder
### Decoded addresses applied to a axi lite channel. Allow data to pass if matched.
---

![image](docs/manual/img/AFRL.png)

---

  author: Jay Convertino   
  
  date: 2024.03.19
  
  details: Decoded addresses applied to a axi lite channel. Allow data to pass if matched.
  
  license: MIT   
   
  Actions:  

  [![Lint Status](../../actions/workflows/lint.yml/badge.svg)](../../actions)  
  [![Manual Status](../../actions/workflows/manual.yml/badge.svg)](../../actions)  
  
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axi_lite_read_channel_decoder.pdf](docs/manual/axi_lite_read_channel_decoder.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axi_lite_read_channel_decoder/)

### PARAMETERS

* ADDRESS_WIDTH : Bit width of the address bus.
* BUS_WIDTH     : Bus width in number of bytes.

### COMPONENTS
#### SRC

* up_apb3.v

#### TB

* tb_apb3.v
* tb_cocotb.py
* tb_cocotb.v
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - lint
  - sim
  - sim_cocotb
