// Code your design here
`timescale 1ns/1ps

//---------------------------------------------------------------------
// 4x4 LU Decomposition (no pivoting) in RTL
// Integer inputs (32-bit) and 32-bit arithmetic used; the outputs
// can be interpreted as floating–point values.
// (Note: In a real design, you would likely want to use a fixed-
// point or floating-point arithmetic unit.)
//
// The algorithm computes:
//   For k=0 to 3:
//     For j=k to 3:
//       U[k][j] = A[k][j] - sum_{m=0}^{k-1} ( L[k][m] * U[m][j] )
//     For i=k+1 to 3:
//       L[i][k] = (A[i][k] - sum_{m=0}^{k-1} ( L[i][m] * U[m][k] )) / U[k][k]
//   and sets L[i][i] = 1.
//---------------------------------------------------------------------
module LU_Decomposition(
    input         clk,
    input         rst,
    input         start,
    input  [511:0] A_in,   // 16 words × 32 bits = 4x4 matrix (flattened)
    output reg    done,
    output reg [511:0] L_out,
    output reg [511:0] U_out
);

  // Internal arrays: we “flatten” our 4x4 matrices into arrays of 16 32-bit words.
  reg signed [31:0] A [0:15];
  reg signed [31:0] L [0:15];
  reg signed [31:0] U [0:15];
  
  // We'll use 3–bit counters (since indices 0..3 are needed)
  reg [2:0] k, i, j, m;
  reg signed [31:0] sum;
  
  // State-machine states.
  localparam IDLE            = 4'd0,
             LOAD            = 4'd1,
             INIT            = 4'd2,
             U_START         = 4'd3,  // Begin computing U[k][j]
             U_M_LOOP        = 4'd4,  // Loop over m for U[k][j]
             U_STORE         = 4'd5,  // Store computed U[k][j]
             L_START         = 4'd6,  // Begin computing L[i][k]
             L_M_LOOP        = 4'd7,  // Loop over m for L[i][k]
             L_STORE         = 4'd8,  // Store computed L[i][k]
             NEXT_K          = 4'd9,  // Next pivot column
             DONE_STATE      = 4'd10;
  reg [3:0] state;
  
  // A loop variable for packing outputs.
  integer idx;
  
  // Main state–machine:  
  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      done  <= 0;
      k <= 0; i <= 0; j <= 0; m <= 0; sum <= 0;
    end else begin
      case(state)
        // Wait for start.
        IDLE: begin
          done <= 0;
          if(start)
            state <= LOAD;
        end

        // Load the input matrix A_in into our internal A array.
        LOAD: begin
          for(idx = 0; idx < 16; idx = idx+1)
            A[idx] <= A_in[idx*32 +: 32];
          state <= INIT;
        end

        // Initialize L and U arrays: set everything to 0 and set diagonal of L to 1.
        INIT: begin
          for(idx = 0; idx < 16; idx = idx+1) begin
            L[idx] <= 0;
            U[idx] <= 0;
          end
          // set L[0][0], L[1][1], L[2][2], L[3][3] to 1.
          for(idx = 0; idx < 4; idx = idx+1)
            L[idx*4+idx] <= 32'd1;
          k <= 0;
          state <= U_START;
        end

        // --- Compute U[k][j] for j=k..3 ---
        U_START: begin
          // For current pivot row k, set j=k and clear the summation.
          j   <= k;
          sum <= 0;
          m   <= 0;
          state <= U_M_LOOP;
        end

        U_M_LOOP: begin
          // Accumulate: sum = sum + L[k][m] * U[m][j] for m = 0 to k-1.
          if(m < k) begin
            sum <= sum + L[k*4 + m] * U[m*4 + j];
            m <= m + 1;
          end else begin
            state <= U_STORE;
          end
        end

        U_STORE: begin
          // Now compute U[k][j] = A[k][j] - sum.
          U[k*4+j] <= A[k*4+j] - sum;
          // Move to the next column in row k.
          if(j < 3) begin
            j   <= j + 1;
            sum <= 0;
            m   <= 0;
            state <= U_M_LOOP;
          end else begin
            // Finished computing row k of U; now compute L for column k.
            if(k < 3) begin
              i <= k + 1;
              state <= L_START;
            end else begin
              state <= DONE_STATE;
            end
          end
        end

        // --- Compute L[i][k] for i=k+1..3 ---
        L_START: begin
          if(i < 4) begin
            sum <= 0;
            m   <= 0;
            state <= L_M_LOOP;
          end else begin
            state <= NEXT_K;
          end
        end

        L_M_LOOP: begin
          // Accumulate: sum = sum + L[i][m] * U[m][k] for m = 0 to k-1.
          if(m < k) begin
            sum <= sum + L[i*4 + m] * U[m*4 + k];
            m <= m + 1;
          end else begin
            state <= L_STORE;
          end
        end

        L_STORE: begin
          // Now compute L[i][k] = (A[i][k] - sum) / U[k][k].
          // (Assumes U[k][k] is nonzero.)
          L[i*4+k] <= (A[i*4+k] - sum) / U[k*4+k];
          // Move to the next row for L.
          if(i < 3) begin
            i   <= i + 1;
            sum <= 0;
            m   <= 0;
            state <= L_M_LOOP;
          end else begin
            state <= NEXT_K;
          end
        end

        // Increment k (the pivot column) and restart U computations.
        NEXT_K: begin
          if(k < 3) begin
            k <= k + 1;
            state <= U_START;
          end else begin
            state <= DONE_STATE;
          end
        end

        // Pack the internal arrays into output busses.
        DONE_STATE: begin
          done <= 1;
          for(idx = 0; idx < 16; idx = idx+1) begin
            L_out[idx*32 +: 32] <= L[idx];
            U_out[idx*32 +: 32] <= U[idx];
          end
        end

      endcase
    end
  end

endmodule