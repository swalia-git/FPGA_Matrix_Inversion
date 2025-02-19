// Code your design here
`timescale 1ns/1ps

module BackwardSub4x4(
    input              clk,
    input              rst,
    input              start,
    // Flattened 4x4 U matrix
    input      [511:0] U_in,
    // Flattened y vector
    input      [127:0] y_in,
    output reg         done,
    // Flattened x vector
    output reg [127:0] x_out
);

  // Internal arrays
  reg signed [31:0] U [0:15];
  reg signed [31:0] y [0:3];
  reg signed [31:0] x [0:3];

  integer i, j;
  
  // States
  localparam IDLE  = 3'd0,
             LOAD  = 3'd1,
             CALC  = 3'd2,
             DONE  = 3'd3;
  reg [2:0] state;
  
  reg signed [31:0] sum;
  
  integer idx;
  
  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      done <= 0;
    end else begin
      case(state)
        IDLE: begin
          done <= 0;
          if(start)
            state <= LOAD;
        end
        
        LOAD: begin
          // Unpack U_in
          for(idx=0; idx<16; idx=idx+1) begin
            U[idx] <= U_in[idx*32 +: 32];
          end
          // Unpack y_in
          for(idx=0; idx<4; idx=idx+1) begin
            y[idx] <= y_in[idx*32 +: 32];
          end
          // Clear x
          for(idx=0; idx<4; idx=idx+1) begin
            x[idx] <= 0;
          end
          
          i <= 3; // Start from the last row (since it's backward)
          state <= CALC;
        end
        
        CALC: begin
          // sum = y[i]
          sum = y[i];
          
          // Subtract U[i][j]* x[j] for j=i+1..3
          for(j=3; j>i; j=j-1) begin
            sum = sum - (U[i*4 + j] * x[j]);
          end
          
          // x[i] = sum / U[i][i]
          if(U[i*4 + i] != 0)
            x[i] <= sum / U[i*4 + i];
          else
            x[i] <= 0; // or handle error
          
          // Move to next row upward
          if(i>0) begin
            i <= i - 1;
          end else begin
            state <= DONE;
          end
        end
        
        DONE: begin
          done <= 1;
          // Pack x[] => x_out
          for(idx=0; idx<4; idx=idx+1) begin
            x_out[idx*32 +: 32] <= x[idx];
          end
        end
      endcase
    end
  end

endmodule