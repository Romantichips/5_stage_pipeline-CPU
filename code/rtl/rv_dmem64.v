`timescale 1ns/1ps

module rv_dmem64 #(
    parameter ADDR_BITS = 8,
    parameter INIT_HEX  = "",
    parameter ALT_INIT_HEX = ""
) (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [63:0] wdata,
    input  wire [7:0]  wstrb,
    input  wire        we,
    output wire [63:0] rdata
);
    reg [63:0] mem[0:(1 << ADDR_BITS)-1];
    wire [ADDR_BITS-1:0] word_addr;
    integer i;
    integer b;
    integer init_fd;

    assign word_addr = addr[ADDR_BITS+2:3];
    assign rdata     = mem[word_addr];

    always @(posedge clk) begin
        if (we) begin
            for (b = 0; b < 8; b = b + 1) begin
                if (wstrb[b])
                    mem[word_addr][8*b +: 8] <= wdata[8*b +: 8];
            end
        end
    end

    initial begin
        for (i = 0; i < (1 << ADDR_BITS); i = i + 1)
            mem[i] = 64'd0;
        if (INIT_HEX != "") begin
            init_fd = $fopen(INIT_HEX, "r");
            if (init_fd != 0) begin
                $fclose(init_fd);
                $readmemh(INIT_HEX, mem);
            end else if (ALT_INIT_HEX != "") begin
                init_fd = $fopen(ALT_INIT_HEX, "r");
                if (init_fd != 0) begin
                    $fclose(init_fd);
                    $readmemh(ALT_INIT_HEX, mem);
                end else begin
                    $display("[rv_dmem64] WARNING: could not open %0s or %0s", INIT_HEX, ALT_INIT_HEX);
                end
            end else begin
                $display("[rv_dmem64] WARNING: could not open %0s", INIT_HEX);
            end
        end
    end
endmodule
