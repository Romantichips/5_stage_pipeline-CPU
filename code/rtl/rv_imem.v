`timescale 1ns/1ps

module rv_imem #(
    parameter ADDR_BITS = 10,
    parameter INIT_HEX  = "",
    parameter ALT_INIT_HEX = ""
) (
    input  wire [31:0] addr,
    output wire [31:0] rdata
);
    reg [31:0] mem[0:(1 << ADDR_BITS)-1];
    wire [ADDR_BITS-1:0] word_addr;
    integer i;
    integer init_fd;

    assign word_addr = addr[ADDR_BITS+1:2];
    assign rdata     = mem[word_addr];

    initial begin
        for (i = 0; i < (1 << ADDR_BITS); i = i + 1)
            mem[i] = 32'h00000013;
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
                    $display("[rv_imem] WARNING: could not open %0s or %0s", INIT_HEX, ALT_INIT_HEX);
                end
            end else begin
                $display("[rv_imem] WARNING: could not open %0s", INIT_HEX);
            end
        end
    end
endmodule
