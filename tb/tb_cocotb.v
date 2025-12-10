//******************************************************************************
// file:    tb_coctb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/03/26
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
 * APB3 slave to uP interface DUT
 *
 * Parameters:
 *
 *   ADDRESS_WIDTH   - Width of the APB3 address port in bits.
 *   BUS_WIDTH       - Width of the APB3 bus data port in bytes.
 *
 * Ports:
 *
 *   clk              - Clock
 *   rstn             - negative reset
 *   s_apb_paddr      - APB3 address bus, up to 32 bits wide.
 *   s_apb_psel       - APB3 select per slave (1 for this core).
 *   s_apb_penable    - APB3 enable device for multiple transfers after first.
 *   s_apb_pready     - APB3 ready is a output from the slave to indicate its able to process the request.
 *   s_apb_pwrite     - APB3 Direction signal, active high is a write access. Active low is a read access.
 *   s_apb_pwdata     - APB3 write data port.
 *   s_apb_prdata     - APB3 read data port.
 *   s_apb_pslverror  - APB3 error indicates transfer failure, not implimented.
 *   up_rreq          - uP bus read request
 *   up_rack          - uP bus read ack
 *   up_raddr         - uP bus read address
 *   up_rdata         - uP bus read data
 *   up_wreq          - uP bus write request
 *   up_wack          - uP bus write ack
 *   up_waddr         - uP bus write address
 *   up_wdata         - uP bus write data
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
    //master interface
    //input master read address
    input   wire [ADDRESS_WIDTH-1:0]        s_axi_araddr,
    input   wire [2:0]                      s_axi_arprot,
    input   wire                            s_axi_arvalid,
    output  wire                            s_axi_arready,
    //output master read data
    output  wire [BUS_WIDTH*8-1:0]          s_axi_rdata,
    output  wire [1:0]                      s_axi_rresp,
    output  wire                            s_axi_rvalid,
    input   wire                            s_axi_rready,
    //slave interfaces
    //output slave read address
    output  wire [ADDRESS_WIDTH-1:0]        m_axi_araddr,
    output  wire [2:0]                      m_axi_arprot,
    output  wire                            m_axi_arvalid,
    input   wire                            m_axi_arready,
    //input slave read data
    input   wire [BUS_WIDTH*8-1:0]          m_axi_rdata,
    input   wire [1:0]                      m_axi_rresp,
    input   wire                            m_axi_rvalid,
    output  wire                            m_axi_rready,
    //unused write signals
    //master interface
    //input master write address
    input   wire [ADDRESS_WIDTH-1:0]        s_axi_awaddr,
    input   wire [2:0]                      s_axi_awprot,
    input   wire                            s_axi_awvalid,
    output  wire                            s_axi_awready,
    //input master write data
    input   wire [BUS_WIDTH*8-1:0]          s_axi_wdata,
    input   wire [BUS_WIDTH-1:0]            s_axi_wstrb,
    input   wire                            s_axi_wvalid,
    output  wire                            s_axi_wready,
    //output master write data state
    output  wire [1:0]                      s_axi_bresp,
    output  wire                            s_axi_bvalid,
    input   wire                            s_axi_bready,
    //slave interfaces
    //output slave write address
    output  wire [ADDRESS_WIDTH-1:0]        m_axi_awaddr,
    output  wire [2:0]                      m_axi_awprot,
    output  wire                            m_axi_awvalid,
    input   wire                            m_axi_awready,
    //output slave write data
    output  wire [BUS_WIDTH*8-1:0]          m_axi_wdata,
    output  wire [BUS_WIDTH-1:0]            m_axi_wstrb,
    output  wire                            m_axi_wvalid,
    input   wire                            m_axi_wready,
    //input slave write data state
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
  ) dut
  (
    .connected(connected),
    .aclk(aclk),
    .arstn(arstn),
    //master interface
    //input master read address
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    //output master read data
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    //slave interfaces
    //output slave read address
    .m_axi_araddr(w_m_axi_araddr),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    //input slave read data
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready)
  );
  
endmodule

