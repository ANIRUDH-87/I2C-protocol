`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.03.2025 10:25:41
// Design Name: 
// Module Name: I2C_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module I2C_top(
    input wire clk,                    //system clock
    input wire rst_n,                  // active-low reset
    input wire start,                 // start signal from the master
    input wire [6:0] addr,            // 7-bit slave address
    input wire rw,                    // read / write bit (0: write, 1: read)
    input wire [7:0] data_wr,          // data to write master to slave
    output wire [7:0] data_rd_master,  // data read by master to slave
    output wire [7:0] data_rd_slave,   // data  read by slave to master
    output wire ack_master,           //  acknowledge signal from master
    output wire ack_slave             // acknowledge signal from slave
    );
// internal signals from I2C communication
  
   wire scl;        // I2C serial clock line
   wire sda;        // I2C serial data line
// instantiate the I2C master

 I2C_master master(
                    .clk(clk),
                    .rst_n(rst_n),
                    .start(start),
                    .addr(addr),
                    .rw(rw),
                    .data_wr(data_wr),
                    .scl(scl),
                    .sda(sda),
                    .busy(),
                    .ack(ack_master),
                    .data_rd(data_rd_master)
                    );
// instantiate I2C slave

I2C_slave slave (
                    .clk(clk),
                    .rst_n(rst_n),
                    .scl(scl),
                    .sda(sda),
                    .addr(addr),
                    .data_rd(data_rd_slave),
                    .ack(ack_slave)
                    );
endmodule
















