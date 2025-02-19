`timescale 1ns/1ps

module ForwardSub4x4(
    input              clk,
    input              rst,
    input              start,
    // Flattened 4x4 L matrix: 16 elements × 32 bits = 512 bits.
    input      [511:0] L_in,  
    // Flattened b vector: 4 elements × 32 bits = 128 bits.
    input      [127:0] b_in,
    output reg         done,
    // Flattened y vector: 4 elements × 32 bits = 128 bits.
    output reg [127:0] y_out
);

  // Internal arrays to store L, b, y
  reg signed [31:0] L [0:15];
  reg signed [31:0] b [0:3];
  reg signed [31:0] y [0:3];

  // Indices
  integer i, j;
  
  // State machine
  localparam IDLE  = 3'd0,
             LOAD  = 3'd1,
             CALC  = 3'd2,
             DONE  = 3'd3;
  reg [2:0] state;
  
  // Summation accumulator
  reg signed [31:0] sum;
  
  // For loops in always block
  integer idx;
  
  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      done  <= 0;
    end else begin
      case(state)
        // Wait for start
        IDLE: begin
          done <= 0;
          if(start)
            state <= LOAD;
        end
        
        // LOAD: Copy L_in, b_in into arrays
        LOAD: begin
          // Unpack L_in into L
          for(idx=0; idx<16; idx=idx+1) begin
            L[idx] <= L_in[idx*32 +: 32];
          end
          // Unpack b_in into b
          for(idx=0; idx<4; idx=idx+1) begin
            b[idx] <= b_in[idx*32 +: 32];
          end
          // Clear y
          for(idx=0; idx<4; idx=idx+1) begin
            y[idx] <= 0;
          end
          
          i <= 0;  // Start with row 0
          state <= CALC;
        end

        // CALC: Do forward-sub row-by-row
        CALC: begin
          // sum = b[i]
          sum = b[i];
          
          // Subtract L[i][0..i-1]*y[0..i-1]
          for(j=0; j<i; j=j+1) begin
            sum = sum - (L[i*4 + j] * y[j]);
          end
          
          // Now do integer divide by L[i][i]
          // (Note: if L has diag=1 in your Doolittle approach, this is just sum.)
          if(L[i*4 + i] != 0)
            y[i] <= sum / L[i*4 + i];
          else
            y[i] <= 0; // or handle error case
          
          // Move to next row
          if(i<3) begin
            i <= i+1;
          end else begin
            state <= DONE;
          end
        end
        
        // DONE: pack y[] to y_out
        DONE: begin
          done <= 1;
          for(idx=0; idx<4; idx=idx+1) begin
            y_out[idx*32 +: 32] <= y[idx];
          end
          // Remain in DONE or go back to IDLE if desired
        end
      endcase
    end
  end
endmodule