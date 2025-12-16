#******************************************************************************
# file:    tb_cocotb.py
#
# author:  JAY CONVERTINO
#
# date:    2025/12/16
#
# about:   Brief
# Cocotb test bench
#
# license: License MIT
# Copyright 2025 Jay Convertino
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#******************************************************************************

import random
import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event, ReadWrite
from cocotb.types import Logic
from cocotb.binary import BinaryValue
from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiLiteRam

# Function: random_bool
# Return a infinte cycle of random bools
#
# Returns: List
def random_bool():
  temp = []

  for x in range(0, 256):
    temp.append(bool(random.getrandbits(1)))

  return itertools.cycle(temp)

# Function: start_clock
# Start the simulation clock generator.
#
# Parameters:
#   dut - Device under test passed from cocotb test function
def start_clock(dut):
  cocotb.start_soon(Clock(dut.aclk, 2, units="ns").start())

# Function: reset_dut
# Cocotb coroutine for resets, used with await to make sure system is reset.
async def reset_dut(dut):
  dut.arstn.value = 0
  await Timer(200, units="ns")
  dut.arstn.value = 1

# Function: increment_test_read
# Coroutine that is identified as a test routine. Read data from the device at the proper address and region.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_read(dut):

  start_clock(dut)

  axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)
  
  axil_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, "m_axi"), dut.aclk, dut.arstn, False, (dut.SLAVE_REGION.value+1)*dut.BUS_WIDTH.value)

  await reset_dut(dut)

  for x in range(4, dut.SLAVE_REGION.value, dut.BUS_WIDTH.value):
    payload_bytes = x.to_bytes(dut.BUS_WIDTH.value, "little")
    
    axil_ram.write(x, bytearray(payload_bytes))
    
    data = await axil_master.read(dut.SLAVE_ADDRESS.value + x, dut.BUS_WIDTH.value)
    
    # axil_ram.hexdump(x, dut.BUS_WIDTH.value, prefix="RAM_")
  
    assert data.data == payload_bytes, "Data written to RAM does not match read data."


# Function: increment_test_random_ready_read_data
# Coroutine that is identified as a test routine. Read data from the device at the proper address and region, randomize read data channel ready.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_random_ready_read_data(dut):

  start_clock(dut)

  axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)
  
  axil_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, "m_axi"), dut.aclk, dut.arstn, False, (dut.SLAVE_REGION.value+1)*dut.BUS_WIDTH.value)
  
  axil_master.read_if.r_channel.set_pause_generator(random_bool())

  await reset_dut(dut)

  for x in range(4, dut.SLAVE_REGION.value, dut.BUS_WIDTH.value):
    payload_bytes = x.to_bytes(dut.BUS_WIDTH.value, "little")
    
    axil_ram.write(x, bytearray(payload_bytes))
    
    data = await axil_master.read(dut.SLAVE_ADDRESS.value + x, dut.BUS_WIDTH.value)
    
    # axil_ram.hexdump(x, dut.BUS_WIDTH.value, prefix="RAM_")
  
    assert data.data == payload_bytes, "Data written to RAM does not match read data."
    
# Function: increment_test_random_ready_read_addr
# Coroutine that is identified as a test routine. Read data from the device at the proper address and region, randomize address channel ready.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_random_ready_read_addr(dut):

  start_clock(dut)

  axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)
  
  axil_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, "m_axi"), dut.aclk, dut.arstn, False, (dut.SLAVE_REGION.value+1)*dut.BUS_WIDTH.value)
  
  axil_ram.read_if.ar_channel.set_pause_generator(random_bool())

  await reset_dut(dut)

  for x in range(4, dut.SLAVE_REGION.value, dut.BUS_WIDTH.value):
    payload_bytes = x.to_bytes(dut.BUS_WIDTH.value, "little")
    
    axil_ram.write(x, bytearray(payload_bytes))
    
    data = await axil_master.read(dut.SLAVE_ADDRESS.value + x, dut.BUS_WIDTH.value)
    
    # axil_ram.hexdump(x, dut.BUS_WIDTH.value, prefix="RAM_")
  
    assert data.data == payload_bytes, "Data written to RAM does not match read data."
    
# Function: increment_test_timeout_no_answer
# Coroutine that is identified as a test routine. Check if timeout will work as it should.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_timeout_no_answer(dut):

  start_clock(dut)
  
  dut.m_axi_rvalid.value = 0
  
  axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)
  
  await reset_dut(dut)

  for x in range(4, dut.SLAVE_REGION.value, dut.BUS_WIDTH.value):
    payload_bytes = x.to_bytes(dut.BUS_WIDTH.value, "little")
    
    axil_master.init_read(dut.SLAVE_ADDRESS.value + x, dut.BUS_WIDTH.value)
    
    await RisingEdge(dut.aclk)
    
    await FallingEdge(dut.connected)
    
    assert dut.s_axi_rvalid.value == 0, "Valid data is present."
    
    axil_master.read_if.ar_channel.clear()
    
    await RisingEdge(dut.aclk)

# Function: increment_test_random_ready_timeout_no_answer
# Coroutine that is identified as a test routine. Check if the timeout will work with random data read channel ready.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_random_ready_timeout_no_answer(dut):

  start_clock(dut)
  
  dut.m_axi_rvalid.value = 0
  
  axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)
  
  axil_master.read_if.r_channel.set_pause_generator(random_bool())

  await reset_dut(dut)

  for x in range(4, dut.SLAVE_REGION.value, dut.BUS_WIDTH.value):
    payload_bytes = x.to_bytes(dut.BUS_WIDTH.value, "little")
    
    axil_master.init_read(dut.SLAVE_ADDRESS.value + x, dut.BUS_WIDTH.value)
    
    await RisingEdge(dut.aclk)
    
    await FallingEdge(dut.connected)
    
    assert dut.s_axi_rvalid.value == 0, "Valid data is present."
    
    axil_master.read_if.ar_channel.clear()
    
    await RisingEdge(dut.aclk)

# Function: in_reset
# Coroutine that is identified as a test routine. This routine tests if device stays
# in unready state when in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def in_reset(dut):

    start_clock(dut)

    dut.arstn.value = 0

    await Timer(100, units="ns")

    assert dut.s_axi_arready.value.integer == 0, "s_axi_aready is not 0!"

# Function: no_clock
# Coroutine that is identified as a test routine. This routine tests if no ready when clock is lost
# and device is left in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def no_clock(dut):

    dut.arstn.value = 0

    await Timer(100, units="ns")

    assert dut.s_axi_arready.value.integer == 0, "s_axi_aready is not 0!"
