`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.02.2025 19:06:13
// Design Name: 
// Module Name: I2C_protocol
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

// Inter-Integrated Circuit protocol

module I2C_master(
     input wire clk,               //clock signal
     input wire rst_n,             // Active-low reset signal
     output reg scl,                // I2C Serial clock line
     inout wire sda,               // I2C serial data line (bidirectional)
     input wire start,             // start signal to initiate I2C transaction
     input wire [6:0] addr,         // 7-bit slave address
     input wire rw,               // read / write bit (0: write, 1: read)
     input wire [7:0] data_wr,     // data to write to the slave
     output reg [7:0] data_rd,     // data read from the slave
     output reg busy,              // busy signal (1: busy, 0: idle)
     output reg ack                // acknowledge signal
    );
//I2C state machine for internal states
     typedef enum logic [2:0] {
      IDLE,                  // Idle state
      START,                 // we need to start condition state
      ADDR,                  // address transmission state
      WRITE,                 // write state for data
      READ,                 // data read store
      STOP                  // at last we need to stop condition state
     } state_t;
     
     state_t state;        
//I2C state machine current state
    reg [7:0] shift_reg;        // for data transmission / reception
    reg [2:0] bit_cnt;          // bit counter for tracking bits in a byte
    reg sda_out;                // internal SDA output signal
    reg sda_oe;                 // SDA output enable(1: drive SDA, 0: Tri-state)

// Tri-state buuffer for SDA
    assign sda = sda_oe ? sda_out : 1'bz;
    
// clock divider for generating SCL
    reg [7:0] clk_div;                 // used to divide the system clock to generate the SCL signal
    always @(posedge clk or negedge rst_n) begin 
     if (!rst_n) begin 
      clk_div <= 8'b0;                 
      scl <= 1'b1;
     end else begin 
       if (clk_div == 8'd199) begin    // assuming a 100MHz clock, divide by 200 for 400khz SCL
           clk_div <= 8'b0;
           scl <= ~scl;     // counters reaches 199 reset to '0' and toogle SCL
       end else begin 
         clk_div <= clk_div + 8'd1;
       end
     end
   end
// I2C state machine logic
    always @(posedge clk or negedge rst_n) begin 
      if (!rst_n) begin 
       state <= IDLE;
       busy <= 1'b0;
       ack <= 1'b0;
       sda_out <= 1'b1;          // it is high because in idle state
       sda_oe <= 1'b0;
       bit_cnt <= 3'd0;
       shift_reg <= 8'd0;
       data_rd <= 8'd0;
      end else begin 
        case (state)
          IDLE: begin 
             busy <= 1'b0;          // master is not busy
             sda_out <= 1'b1;        // SDA is high
             sda_oe <= 1'b0;        // SDA is tri-stated beacuse not driven by master
             if (start) begin 
                state <= START;
                busy <= 1'b1;      // when start signal start master is busy
             end
         end
         START: begin 
            sda_out <= 1'b0;            // it is low (start condition)
            sda_oe <= 1'b1;             // drive SDA
            if (scl == 1'b1) begin        // wait for SCl high
               state <= ADDR;
               shift_reg <= {addr, rw};
               bit_cnt <= 3'd7;          // initialize bit counter to 7 MSB first
            end
         end
         ADDR: begin 
              sda_out <= shift_reg[bit_cnt];       // need to transmit current bit of address
              sda_oe <= 1'b1;                      // drive SDA by master
              if (scl == 1'b0) begin                 // wait for SCL to be low
                 if (bit_cnt == 3'd0) begin   // all bits are transmitted  (7-bit address + R/W bit)
                   state <= WRITE;             // transition to write state
                   bit_cnt <= 3'd7;           // reset bit counter for data byte
                 end else begin
                 bit_cnt <= bit_cnt - 3'd1;       // decrement bit counter
                 end
              end
         end
         WRITE: begin 
          sda_out <= data_wr[bit_cnt];           // transmit current bit of data
          sda_oe <= 1'b1;                        // drive SDA
          if (scl == 1'b0) begin 
             if (bit_cnt == 3'd0) begin              // if all bits are transmitted go to STOP state
                state <= STOP;
                ack <= sda;                          // wew need to capture ACK / NACK
           end else begin 
              bit_cnt <= bit_cnt - 3'd1;   
           end
         end 
       end
       STOP: begin 
          sda_out <= 1'b0;                        // pull SDA to low
          sda_oe <= 1'b1;                          //drive SDA
       if (scl == 1'b1) begin                  // wait for SCL to begin high
          sda_out <= 1'b1;                  // pill SDA to high
          state <= IDLE;                     // transition to idle state
        end     
       end
       default: state <= IDLE;
     endcase
       end
      end
endmodule























