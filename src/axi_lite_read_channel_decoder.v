//******************************************************************************
// file:    axi_lite_rd_addr.v
//
// author:  JAY CONVERTINO
//
// date:    2025/12/01
//
// about:   Brief
// Verify read address and contain holdbuffer interface. Valid address? Allow output till invalid address presented.
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
// IN THE SOFTWARE.
//
//******************************************************************************

`resetall
`timescale 1 ns/100 ps
`default_nettype none

/*
 * Module: axi_lite_rd_addr
 *
 * APB3 slave to uP interface
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
 *
 */
module axi_lite_read_channel_decoder #(
    parameter integer               ADDRESS_WIDTH = 32,
    parameter integer               BUS_WIDTH     = 4,
    parameter integer               DATA_BUFFER   = 1,
    parameter integer               TIMEOUT_BEATS = 32,
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
    output  wire                            m_axi_rready
  );
  
  wire                            w_connected;

  
  reg                             r_timeout;
  reg [31:0]                      r_timeout_counter;
  
  assign connected = w_connected;
  
  holdbuffer #(
    .BUS_WIDTH(ADDRESS_WIDTH+3)
  ) inst_addr_buffer (
    .clk(aclk),
    .rstn(arstn),
    .timeout(r_timeout),
    .enable(w_connected),
    .s_data({s_axi_arprot, s_axi_araddr}),
    .s_data_last(1'b0),
    .s_data_valid(s_axi_arvalid),
    .s_data_ready(s_axi_arready),
    .s_data_ack(),
    .m_data({m_axi_arprot, m_axi_araddr}),
    .m_data_last(),
    .m_data_valid(m_axi_arvalid),
    .m_data_ready(m_axi_arready),
    .m_data_ack(1'b0)
  );

  bus_addr_decoder #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .ADDRESS(SLAVE_ADDRESS),
    .REGION(SLAVE_REGION)
  ) inst_addr_verify (
    .timeout(r_timeout),
    .connected(w_connected),
    .aclk(aclk),
    .arstn(arstn),
    .addr(s_axi_araddr),
    .valid(s_axi_arvalid)
  );
  
  generate
    if(DATA_BUFFER == 1) begin : gen_DATA_BUFFER
      holdbuffer #(
        .BUS_WIDTH(BUS_WIDTH*8+2)
      ) inst_data_buffer (
        .clk(aclk),
        .rstn(arstn),
        .timeout(r_timeout),
        .enable(w_connected),
        .s_data({m_axi_rresp, m_axi_rdata}),
        .s_data_last(1'b0),
        .s_data_valid(m_axi_rvalid),
        .s_data_ready(m_axi_rready),
        .s_data_ack(),
        .m_data({s_axi_rresp, s_axi_rdata}),
        .m_data_last(),
        .m_data_valid(s_axi_rvalid),
        .m_data_ready(s_axi_rready)
        .m_data_ack(1'b0)
      );
    end else begin : gen_NO_DATA_BUFFER
      assign s_axi_rresp = m_axi_rresp;
      assign s_axi_rdata = m_axi_rdata;
      assign s_axi_rvalid = m_axi_rvalid & w_connected;
      assign m_axi_rready = s_axi_rready & w_connected;
    end
    
    if(TIMEOUT_BEATS == 0) begin : gen_NO_TIMEOUT
      always @(posedge aclk)
      begin
        r_timeout_counter <= {32{1'b0}};
        r_timeout <= 1'b0;
      end
    end else begin : gen_TIMEOUT
      always @(posedge aclk)
      begin
        if(arstn == 1'b0)
        begin
          r_timeout_counter <= {32{1'b0}};
          r_timeout <= 1'b0;
        end else begin
          r_timeout_counter <= {32{1'b0}};
          r_timeout <= r_timeout;
          
          if(!s_axi_arvalid && !m_axi_rvalid && w_connected)
          begin
            r_timeout_counter <= r_timeout_counter + 1;
            
            if(r_timeout_counter >= TIMEOUT_BEATS)
            begin
              r_timeout_counter <= r_timeout_counter;
              r_timeout <= 1'b1;
            end
          end
          
          if(r_timeout)
          begin
            r_timeout_counter <= {32{1'b0}};
            r_timeout <= 1'b0;
          end
        end
      end
    end
  endgenerate
  
endmodule

`resetall
