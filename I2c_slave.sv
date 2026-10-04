`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2025 19:56:41
// Design Name: 
// Module Name: I2c_slave
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


module I2C_slave(
    input wire clk,               //system clock
    input wire rst_n,             // active-low reset
    input wire scl,              // I2C serial clock line
    inout wire sda,              // I2C serial data line
    input wire [6:0] addr,      // 7-bit slave address 
    output reg [7:0] data_rd,    // data read from master
    output reg ack              // Acknowledgement signal
    );
 // internal states for I2C slave state machine
 
 typedef enum logic[2:0] {IDLE, ADDR, READ, WRITE, ACK} state_t;
 state_t state;  //current state of the I2C slave state machine
 
 reg [7:0] shift_reg;   //shift register for data transmission / reception
 reg [2:0] bit_cnt;     //bit counter for tracking bits in a byte
 reg sda_out;          // internal SDA output signal
 reg sda_oe;           // SDA output enable (1: drive SDA, 0: Tri-state)
 
 // Tri-state buffer for SDA
 assign sda = sda_oe ? sda_out : 1'bz;
 
 // I2C slave state machine
 always @(posedge clk or negedge rst_n) begin 
  if (!rst_n) begin 
    state <= IDLE;
    data_rd <= 8'b0;
    ack <= 1'b0;
    sda_out <= 1'b1;
    sda_oe <= 1'b0;
    bit_cnt <= 3'd0;
    shift_reg <= 8'b0;
  end else begin 
   case (state) 
      IDLE: begin 
           sda_out <= 1'b1;
           sda_oe <= 1'b0;
           if (scl == 1'b1 && sda == 1'b0) begin    // detect start condition 
           state <= ADDR;
           bit_cnt <= 3'd7;
       end
     end
     ADDR: begin 
           if (scl == 1'b1) begin 
            shift_reg[bit_cnt] <= sda;          //sample address bit
            if(bit_cnt == 3'b0) begin 
             if (shift_reg[7:1] == addr) begin  // check address match
              state <= ACK;
              ack <= 1'b1;                   // acknowledge address match
             end else begin 
                state <= IDLE;                 // adress mismatch, return to idle
              end
            end  else begin 
             bit_cnt <= bit_cnt - 3'd1;
            end
         end
     end
     READ: begin 
           if (scl == 1'b1) begin 
            data_rd[bit_cnt] <= sda;           // sample data bit
            if (bit_cnt == 3'b0) begin 
              state <= ACK;                    
              ack <= 1'b1;                     // acknowledge data reception
            end else begin 
             bit_cnt <= bit_cnt - 3'd1;
            end
        end
     end
     WRITE: begin 
          if (scl == 1'b1) begin 
            sda_out <= shift_reg[bit_cnt];      // transmit the data bit
            sda_oe <= 1'b1;
            if (bit_cnt == 3'd0) begin 
             state <= ACK;
            end else begin 
              bit_cnt <= bit_cnt - 3'd1;
            end
          end
     end
     ACK: begin 
         if (scl == 1'b1) begin 
            sda_out <= 1'b0;     //drive sda low for ACk
            sda_oe <= 1'b1;
            if (shift_reg[0] == 1'b0) begin  //check R / W bit
                state <= READ;             // master wants to read
            end else begin 
                state <= WRITE;              // master wants to write
           end
         end
     end
          default: state <= IDLE;
   endcase
  end
 end
endmodule

















