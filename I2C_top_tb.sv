module I2C_top_tb;
    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [6:0] addr;
    reg rw;
    reg [7:0] data_wr;

    // Outputs
    wire [7:0] data_rd_master;
    wire [7:0] data_rd_slave;
    wire ack_master;
    wire ack_slave;

    // Instantiate the top-level module
    I2C_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .addr(addr),
        .rw(rw),
        .data_wr(data_wr),
        .data_rd_master(data_rd_master),
        .data_rd_slave(data_rd_slave),
        .ack_master(ack_master),
        .ack_slave(ack_slave)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    // Testbench logic
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        addr = 7'b0;
        rw = 0;
        data_wr = 8'b0;

        // Apply reset
        #10 rst_n = 1;

        // Test 1: Write data from master to slave
        $display("Test 1: Write data from master to slave");
        addr = 7'b1010101;  // Slave address
        rw = 0;             // Write operation
        data_wr = 8'b11001100;  // Data to write
        start = 1;          // Start transaction
        #20 start = 0;      // Deassert start
        wait (ack_master);  // Wait for acknowledgment
        $display("Data written by master: %b", data_wr);
        $display("Data received by slave: %b", data_rd_slave);
        #100;

        // Test 2: Read data from slave to master
        $display("Test 2: Read data from slave to master");
        addr = 7'b1010101;  // Slave address
        rw = 1;             // Read operation
        start = 1;          // Start transaction
        #20 start = 0;      // Deassert start
        wait (ack_master);  // Wait for acknowledgment
        $display("Data read by master: %b", data_rd_master);
        #100;

        // Test 3: Randomized test with error injection
        $display("Test 3: Randomized test with error injection");
        repeat (10) begin
            addr = $random;  // Random slave address
            rw = $random;    // Random read/write operation
            data_wr = $random;  // Random data
            start = 1;       // Start transaction
            #20 start = 0;   // Deassert start
            wait (ack_master);  // Wait for acknowledgment
            if (addr == 7'b1010101) begin
                $display("Valid transaction: Addr = %b, R/W = %b, Data = %b", addr, rw, data_wr);
                if (rw == 0) begin
                    $display("Data written by master: %b", data_wr);
                    $display("Data received by slave: %b", data_rd_slave);
                end else begin
                    $display("Data read by master: %b", data_rd_master);
                end
            end else begin
                $display("Invalid transaction: Addr = %b (no acknowledgment)", addr);
            end
            #100;
        end

        // End simulation
        $display("Simulation completed.");
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time = %0t: SCL = %b, SDA = %b, Ack Master = %b, Ack Slave = %b",
                 $time, uut.scl, uut.sda, ack_master, ack_slave);
    end
endmodule


