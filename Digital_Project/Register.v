module Register //#(parameter TOP_ADDR_DATAO = 10'h0 , parameter TOP_ADDR_SR = 10'h4)
(
input wire clk,
input wire rst_n,
input wire wr_en,
input wire rd_en,
input wire [9:0] addr,
input wire [31:0] wdata,
output wire [31:0] rdata
);

//declare variable
wire [31:0] data0, data1;

write write_mode (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .addr(addr), .wdata(wdata), .data0(data0), .data1_pre(data1));

read read_mode (.wr_en(wr_en), .rd_en(rd_en), .addr(addr), .data0(data0), .data1(data1), .rdata(rdata));

endmodule

module read //#(parameter ADDR_DATAO = 10'h0 , ADDR_SR = 10'h4)
(
input wire wr_en,
input wire rd_en,
input wire [9:0] addr,
input wire [31:0] data0,
input wire [31:0] data1,
output wire [31:0] rdata
);

//declare variable
wire read_mode;
reg [31:0] rdata_tmp;

assign read_mode = ((-wr_en) & rd_en);

always @(*) begin
case (addr)
10'h0: rdata_tmp = data0;
10'h4: rdata_tmp = data0;
10'h8: rdata_tmp = data1;
10'hc: rdata_tmp = data1;
default: rdata_tmp = 32'h0;

endcase

end

assign rdata = (read_mode == 1'b1) ? rdata_tmp : 32'h0;
endmodule

module write //#(parameter ADDR_DATAO = 10'h0, ADDR_DATA1 = 10'h8 )
(
input wire clk,
input wire rst_n,
input wire wr_en,
input wire rd_en,
input wire [9:0] addr,
input wire [31:0] wdata,
output reg [31:0] data0,
output reg [31:0] data1
);

//declare variable
wire wr_mode;
wire [31:0] data0_pre, data1_pre;

assign wr_mode = ((~rd_en) & wr_en);

assign data0_pre = ((wr_mode == 1) & (addr == 10'h0)) ? wdata : data0;
assign data1_pre = ((wr_mode == 1) & (addr == 10'h8)) ? wdata : data1;

//D Flip Flop(default: 32'h0000_0000)

always @(posedge clk, negedge rst_n) begin
if (rst_n == 0)
data0 <= 32'h0;
else
data0 <= data0_pre;
end
//D Flip Flop(default: 32'hffff_ffff)
always @(posedge clk, negedge rst_n) begin
if (rst_n == 0)
data1 <= 32'hffff_ffff;
else
data1 <= data1_pre;

end

endmodule





module test_bench #(parameter RDATA_DEFAULT = 32'h0);

reg clk, rst_n, wr_en, rd_en;
reg [9:0] addr;
reg [31:0] wdata;
wire [31:0] rdata;

// register #(.TOP_ADDR_DATAO(TB_ADDR_DATAO), .TOP_ADDR_SR(TB_ADDR_SR) ) u_dut(.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .addr(addr), .wdata(wdata), .rdata(rdata));
register u_dut(.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .addr(addr), .wdata(wdata), .rdata(rdata));

//generate clock pulse
initial begin
clk = 0;#50;
forever begin clk = ~clk;#25; end
end
//generate rst_n waveform
initial begin
rst_n = 0;
repeat(2) @(posedge clk);
rst_n = 1;

end

//checker
initial begin
wr_en = 0;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT)// =========== casel===========
$display("t = $6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = $6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
repeat(4) @(posedge clk);
wr_en = 1;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT) // ========case2====================

$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
@(posedge clk);
wr_en = 0;
rd_en = 1;#1;
if (rdata === 32'hd0)//================ case 3==============
$display("t = $6t, PASS: rd_en = 1 , addr = 10'h3h , rdata = data0: 32'hd0", $stime, addr) ;
else begin
$display("t = $6t, FAIL: rd_en = 1 , rdata = 32'h%8h , expected value = data0: 32'hd0", $stime, rdata);
#100;$finish;
end
@(posedge clk);
wr_en = 0;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT)// ================ case 4==============
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
@(posedge clk);
wr_en = 1;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT)//================== case 5 ====================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end

repeat(2) @(posedge clk);
wr_en = 0;
rd_en = 1;#1;
if (rdata === 32'hd1)// ========= case 6 ========================
$display("t = %6t, PASS: rd_en = 1 , addr = 10'h%3h , rdata = data0: 32'hd1", $stime, addr) ;
else begin
$display("t = %6t, FAIL: rd_en = 1 , rdata = 32'h%8h , expected value = data0: 32'hd1", $stime, rdata);
#100;$finish;
end
@(posedge clk);
#1
if (rdata === 32'hffff_ffff)// ================ case 7 ========================
$display("t =%6t, PASS: rd_en = 1 , addr = 10'h3h , rdata = data1: 32'hffff_ffff", $stime, addr) ;
else begin
$display("t = %6t, FAIL: rd_en = 1 , rdata = 32'h%8h , expected value = data1: 32'hffff_ffff", $stime, rdata) ;
#100;$finish;
end
repeat(2) @(posedge clk);
wr_en = 0;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT) //=============== case 8 ================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
@(posedge clk);
wr_en = 1;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT) // ==================== case 9 ================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
@(posedge clk);
wr_en = 0;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT)// ================= case 10 ================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h%8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h%8h", $stime, rdata, RDATA_DEFAULT) ;
#100; $finish;
end

repeat(2) @(posedge clk);
wr_en = 1;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT) // ================ case 11 ================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h%8h , expected value = default_value: 32'h8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
@(posedge clk);
wr_en = 0;
rd_en = 1;#1;
if (rdata === 32'hd3) //============ case 12 ================
$display("t = %6t, PASS: rd_en = 1 , addr = 10'h3h , rdata = data1: 32'hd3", $stime, addr) ;
else begin
$display("t = %6t, FAIL: rd_en = 1 , rdata = 32'h8h , expected value = data1: 32'hd3", $stime, rdata);
#100;$finish;
end
@(posedge clk);
wr_en = 0;
rd_en = 0;#1;
if (rdata === RDATA_DEFAULT) // ================ case 13 ================
$display("t = %6t, PASS: rd_en = 0 , rdata = default_value: 32'h8h", $stime, RDATA_DEFAULT) ;
else begin
$display("t = %6t, FAIL: rd_en = 0 , rdata = 32'h8h , expected value = default_value: 32'h8h", $stime, rdata, RDATA_DEFAULT) ;
#100;$finish;
end
repeat(2) @(posedge clk);
$finish;

end

//generate values for wdata and addr
initial begin
wdata = 32'h0;
addr = 10'hf;
repeat(4) @(posedge clk);
wdata = 32'hd0;
addr = 10'h0;
repeat(3) @(posedge clk);
wdata = 32'hd1;
@(posedge clk);
wdata = 32'hd2;
addr = 10'h4;
repeat(2) @(posedge clk);
addr = 10'h8;
repeat(2) @(posedge clk);
wdata = 32'hd3;
repeat(2) @(posedge clk);
addr = 10'hc;

end

endmodule
