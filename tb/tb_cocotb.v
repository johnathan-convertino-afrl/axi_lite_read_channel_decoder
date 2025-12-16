//******************************************************************************
// file:    tb_cocotb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/12/16
//
// about:   Brief
// Test bench wrapper for cocotb
//
// license: License MIT
// Copyright 2025 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.BUS_WIDTH
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: tb_cocotb
 *
 * AXI lite address recoder for read channel. Write channel lines included for 
 * cocotb cores to connect to.
 *
 * Parameters:
 *
 *   ADDRESS_WIDTH    - Width of the AXI LITE address port in bits.
 *   BUS_WIDTH        - Width of the AXI LITE bus data port in bytes.
 *   SLAVE_ADDRESS    - Array of Addresses for each slave (0 = slave 0 and so on).
 *   SLAVE_REGION     - Region for the address that is valid for the SLAVE ADDRESS.
 *
 * Ports:
 *
 *   connected        - Core has established channel connection
 *   aclk             - Input clock
 *   arstn            - Input negative reset
 *   s_axi_araddr     - Slave read chanel input address.
 *   s_axi_arprot     - Slave read chanel input address protection
 *   s_axi_arvalid    - Slave read chanel input address is valid
 *   s_axi_arready    - Slave read chanel input is ready.
 *   s_axi_rdata      - Slave read chanel input data.
 *   s_axi_rresp      - Slave read chanel input data response.
 *   s_axi_rvalid     - Slave read chanel input data valid
 *   s_axi_rready     - Slave read chanel input is ready.
 *   m_axi_araddr     - Master read chanel output address.
 *   m_axi_arprot     - Master read chanel output address protection
 *   m_axi_arvalid    - Master read chanel output address is valid
 *   m_axi_arready    - Master read chanel output is ready.
 *   m_axi_rdata      - Master read chanel output data.
 *   m_axi_rresp      - Master read chanel output data response.
 *   m_axi_rvalid     - Master read chanel output data valid
 *   m_axi_rready     - Master read chanel output is ready.
 *
 */
module tb_cocotb #(
    parameter integer               ADDRESS_WIDTH = 32,
    parameter integer               BUS_WIDTH     = 4,
    parameter [ADDRESS_WIDTH-1:0]   SLAVE_ADDRESS = 32'h44A20000,
    parameter [ADDRESS_WIDTH-1:0]   SLAVE_REGION  = 32'h0000FFFF
  ) 
  (
    output  wire                            connected,
    input   wire                            aclk,
    input   wire                            arstn,
    input   wire [ADDRESS_WIDTH-1:0]        s_axi_araddr,
    input   wire [2:0]                      s_axi_arprot,
    input   wire                            s_axi_arvalid,
    output  wire                            s_axi_arready,
    output  wire [BUS_WIDTH*8-1:0]          s_axi_rdata,
    output  wire [1:0]                      s_axi_rresp,
    output  wire                            s_axi_rvalid,
    input   wire                            s_axi_rready,
    output  wire [ADDRESS_WIDTH-1:0]        m_axi_araddr,
    output  wire [2:0]                      m_axi_arprot,
    output  wire                            m_axi_arvalid,
    input   wire                            m_axi_arready,
    input   wire [BUS_WIDTH*8-1:0]          m_axi_rdata,
    input   wire [1:0]                      m_axi_rresp,
    input   wire                            m_axi_rvalid,
    output  wire                            m_axi_rready,
    input   wire [ADDRESS_WIDTH-1:0]        s_axi_awaddr,
    input   wire [2:0]                      s_axi_awprot,
    input   wire                            s_axi_awvalid,
    output  wire                            s_axi_awready,
    input   wire [BUS_WIDTH*8-1:0]          s_axi_wdata,
    input   wire [BUS_WIDTH-1:0]            s_axi_wstrb,
    input   wire                            s_axi_wvalid,
    output  wire                            s_axi_wready,
    output  wire [1:0]                      s_axi_bresp,
    output  wire                            s_axi_bvalid,
    input   wire                            s_axi_bready,
    output  wire [ADDRESS_WIDTH-1:0]        m_axi_awaddr,
    output  wire [2:0]                      m_axi_awprot,
    output  wire                            m_axi_awvalid,
    input   wire                            m_axi_awready,
    output  wire [BUS_WIDTH*8-1:0]          m_axi_wdata,
    output  wire [BUS_WIDTH-1:0]            m_axi_wstrb,
    output  wire                            m_axi_wvalid,
    input   wire                            m_axi_wready,
    input   wire [1:0]                      m_axi_bresp,
    input   wire                            m_axi_bvalid,
    output  wire                            m_axi_bready
  );
  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end
  
  // mask since we are using a ram core that takes the full address due to...
  // reasons.
  wire  [ADDRESS_WIDTH-1:0] w_m_axi_araddr;
  
  assign m_axi_araddr = w_m_axi_araddr & SLAVE_REGION;
  
  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, axi_lite_read_channel_decoder
   */
  axi_lite_read_channel_decoder #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .BUS_WIDTH(BUS_WIDTH),
    .SLAVE_ADDRESS(SLAVE_ADDRESS),
    .SLAVE_REGION(SLAVE_REGION)
  ) dut (
    .connected(connected),
    .aclk(aclk),
    .arstn(arstn),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .m_axi_araddr(w_m_axi_araddr),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready)
  );
  
endmodule

