module DUT (
    input               clk             ,
    input               rst_n           ,
    input       [1:0]   data_in0        ,
    input       [5:0]   data_in1        ,
    input               data_in_vld     ,
    output reg  [7:0]   data_out        ,
    output reg          data_out_vld    ,   
    input               bus_cs          ,
    input               bus_op          ,
    input       [15:0]  bus_addr        ,
    input       [15:0]  bus_wr_data     ,
    output reg  [15:0]  bus_rd_data

);

reg cfg;
reg [2:0] stat;
wire stat0,stat1,stat2;
assign {stat0,stat1,stat2} = stat;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 8'b0;
    end
    else begin
        if (data_in_vld == 1) begin
            data_out <= {data_in1, data_in0};
        end
        else begin
            data_out <= data_out;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_vld <= 1'b0;
    end
    else begin
        data_out_vld <= data_out_vld;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cfg <= 0;
    end
    else if (bus_cs && bus_op) begin
        case (bus_addr)
            18'h9: cfg <= bus_wr_data[0]; 
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bus_rd_data <= 0;
    end
    else if (bus_cs && !bus_op) begin
        case (bus_addr)
            16'h9: bus_rd_data <= {15'b0, cfg};
            16'h8: bus_rd_data <= {13'b0, stat};
            default: bus_rd_data <= 16'b0;
        endcase
    end
end

endmodule