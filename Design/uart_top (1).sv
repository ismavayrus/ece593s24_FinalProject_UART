module uart_top#(
parameter clk_freq = 1000000,
parameter baud_rate = 9600
)
(input clk, rst,
 input newd,
 input [7:0] din,
 input en_tx1,en_rx1,en_tx2,en_rx2,
 output [7:0]dout,
 output donerx1, donerx2, donetx1, donetx2,
 output tx1rx2, tx2rx1

);



uart_single 
#(clk_freq,baud_rate)
uart1
(.clk(clk), .rst(rst), .rx(tx2rx1), .dintx(din), .newd(newd), .en_tx(en_tx1), .en_rx(en_rx1), .tx(tx1rx2), .doutrx(dout), .donetx(donetx1), .donerx(donerx1));


uart_single #(
clk_freq ,
baud_rate )uart2

(.clk(clk), .rst(rst), .rx(tx1rx2), .dintx(din), .newd(newd), .en_tx(en_tx2), .en_rx(en_rx2), .tx(tx1rx2), .doutrx(dout), .donetx(donetx2), .donerx(donerx1));



endmodule



interface uart_if;
  logic clk;
  logic uclktx;
  logic uclkrx;
  logic rst;
  logic rx;
  logic [7:0] din;
  logic newd;
  logic tx;
  logic [7:0] dout;
  logic donerx1, donerx2, donetx1, donetx2;
  logic tx1rx2, tx2rx1;
  logic en_tx1,en_rx1,en_tx2,en_rx2;

endinterface