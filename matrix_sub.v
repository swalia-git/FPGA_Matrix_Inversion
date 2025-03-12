// Code your design here
module matrix_subtraction_fixed_point #(
    parameter SIZE = 4,            // Default size of the square matrix (4x4)
    parameter INT_WIDTH = 8,       // Integer part width (bits)
    parameter FRAC_WIDTH = 8       // Fractional part width (bits)
)(
    input wire clk,
    input wire reset,
    input wire start,                                           // Start signal to begin subtraction
    input wire signed [INT_WIDTH+FRAC_WIDTH-1:0] matrix_a [0:SIZE-1][0:SIZE-1],  // First input matrix
    input wire signed [INT_WIDTH+FRAC_WIDTH-1:0] matrix_b [0:SIZE-1][0:SIZE-1],  // Second input matrix
    output reg signed [INT_WIDTH+FRAC_WIDTH-1:0] result [0:SIZE-1][0:SIZE-1],    // Result matrix
    output reg done                                            // Done signal
);

    // Total bit width
    localparam TOTAL_WIDTH = INT_WIDTH + FRAC_WIDTH;

    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [$clog2(SIZE):0] i, j; // Counters for matrix traversal

    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                if (i == SIZE-1 && j == SIZE-1)
                    next_state = DONE;
                else
                    next_state = PROCESS;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Matrix subtraction process
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i <= 0;
            j <= 0;
            done <= 0;
            // Initialize result matrix to zeros
            for (integer x = 0; x < SIZE; x = x + 1) begin
                for (integer y = 0; y < SIZE; y = y + 1) begin
                    result[x][y] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        i <= 0;
                        j <= 0;
                        done <= 0;
                    end
                end
                PROCESS: begin
                    // Perform subtraction element by element
                    // Fixed-point subtraction is the same as integer subtraction
                    result[i][j] <= matrix_a[i][j] - matrix_b[i][j];
                    
                    // Update indices
                    if (j == SIZE-1) begin
                        j <= 0;
                        if (i == SIZE-1) begin
                            // All elements processed
                        end else begin
                            i <= i + 1;
                        end
                    end else begin
                        j <= j + 1;
                    end
                end
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
