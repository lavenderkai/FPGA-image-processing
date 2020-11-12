//2020-02-17
//Huang.Wei
`timescale 1ns/1ns

module video_cap(
    reset_l,        //异步复位信号
    DVD,            //输入视频流
    DVSYN,            //输入场同步信号
    DHSYN,            //输入行同步
    DVCLK,            //输入DV时钟
    cap_dat,        //输出RGB通道像素流，24位
    cap_dvalid,        //输出数据有效
    cap_vsync,        //输出场同步
    cap_clk,        //本地逻辑时钟
    img_en,
    cmd_rdy,        //命令行准备好，代表可以读取
    cmd_rdat,        //命令行数据输出
    cmd_rdreq        //命令行读取请求
);

    parameter TRIG_VALUE = 250;            //读触发值，也即行消隐时间
    parameter IW = 640;                    //图像宽度
    parameter IH = 512;                    //图像高度

    parameter DW_DVD = 8;                //输入像素宽度
    parameter DVD_CHN = 3;                //输入像素通道: RGB 3通道
    parameter DW_LOCAL = 24;            //本地捕获的数据宽度24位
    parameter DW_CMD = 24;                //命令行数据宽度
    parameter VSYNC_WIDTH = 100;    //9        //场同步宽度，9个时钟

    parameter CMD_FIFO_DEPTH = 1024;    //行缓存位宽
    parameter CMD_FIFO_DW_DEPTH = 10;
    parameter IMG_FIFO_DEPTH = 512;        //异步fifo深度，选512
    parameter IMG_FIFO_DW_DEPTH = 9;

    //Port Declared
    input reset_l;
    input [DW_DVD-1:0] DVD;
    input DVSYN;
    input DHSYN;
    input DVCLK;

    output reg [DW_LOCAL-1:0] cap_dat;
    output reg cap_dvalid;
    output cap_vsync;
    input cap_clk;
    output img_en;

    output reg cmd_rdy;
    output [DW_CMD-1:0] cmd_rdat;
    input cmd_rdreq;

    //首先完成数据位宽转换
    wire pixel_clk;
    reg [1:0] vc_reset;
    reg dv_enable;
    reg [9:0] count_lines;
    reg cmd_en;
    reg cmd_wrreq;
    reg cmd_wrreq_r;
    reg rst_cmd_fifo;
    wire [DW_CMD-1:0] cmd_din;
    reg [DW_CMD-1:0] cmd_dat;

    assign pixel_clk = DVCLK;

    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l))) == 1'b1)
        begin
            vc_reset <= 2'b00;
            dv_enable <= 1'b0;
        end
        else
        begin
            dv_enable <= #1 1'b1;
            if((~(DVSYN)) == 1'b1 & dv_enable == 1'b1)
                vc_reset <= #1 ({vc_reset[0],1'b1});
        end
    end

    reg [DW_DVD-1:0] vd_r[0:DVD_CHN-1];
    reg [DVD_CHN*DW_DVD-1:0] data_merge;

    reg vsync;
    reg [DVD_CHN:0] hsync_r;
    reg mux;
    reg mux_r;

    //缓存场同步和行同步信号
    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l))) == 1'b1)
        begin
            vsync <= 1'b0;
            hsync_r <= {DVD_CHN+1{1'b0}};
        end
        else
        begin
            vsync <= #1 DVSYN;
            hsync_r <= #1 {hsync_r[DVD_CHN-1:0],DHSYN};
        end
    end

    //像素通道计算，指示当前像素属于RGB那个通道
    reg [DVD_CHN:0] pixel_cnt;

    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l))) == 1'b1)
        begin
            pixel_cnt <= {DVD_CHN+1{1'b1}};
        end
        else
        begin
            if(hsync_r[1] == 1'b0)
                pixel_cnt <= #1 {DVD_CHN+1{1'b1}};
            else
                if(pixel_cnt == DVD_CHN -1)
                    pixel_cnt <= #1 {DVD_CHN+1{1'b0}};
                else
                    pixel_cnt <= #1 pixel_cnt + 1'b1;
        end
    end

    integer i;
    integer j;

    //缓存输入DV，获得3个RGB通道值

    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l)))==1'b1)
            for(i=0;i<DVD_CHN;i=i+1)
                vd_r[i] <= {DW_DVD{1'b0}};
        else
        begin
            vd_r[0] <= #1 DVD;
            for(j=1;j<DVD_CHN;j=j+1)
                vd_r[j] <= vd_r[j-1];
        end
    end


    //RGB 合并有效信号
    wire mux_valid;

    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l))) == 1'b1)
            mux <= 1'b0;
        else begin
            if(hsync_r[DVD_CHN-2] == 1'b0)
                mux <= #1 1'b1;
            else
                if(mux_valid == 1'b1)
                    mux <= #1 1'b1;
                else
                    mux <= #1 1'b0;
        end
    end

    always@(posedge pixel_clk)
        mux_r <= mux;


    wire [DVD_CHN*DW_DVD-1:0] dvd_temp;
    wire mux_1st;

    assign mux_1st = (~hsync_r[DVD_CHN]) & (hsync_r[DVD_CHN-1]);

    //一个颜色通道
    generate
        if(DVD_CHN == 1)
        begin: xhdl1
            assign mux_valid = hsync_r[0];
            assign dvd_temp = vd_r[0];
        end
    endgenerate


    //两个颜色通道
    generate
        if(DVD_CHN == 2)
        begin: xhdl2
            assign mux_valid = mux_1st | (pixel_cnt == DVD_CHN - 1);
            assign dvd_temp = {vd_r[0],vd_r[1]};
        end
    endgenerate

    //三个颜色通道，将三路RBG数据合并到dvd_temp信号中
    generate
        if(DVD_CHN == 3)
        begin: xhdl3
            assign mux_valid = mux_1st | (pixel_cnt == 0);
            assign dvd_temp = {vd_r[0],vd_r[1],vd_r[2]};
        end
    endgenerate

    //四个颜色通道
    generate
        if(DVD_CHN == 4)
        begin: xhdl4
            assign mux_valid = mux_1st | (pixel_cnt == 1);
            assign dvd_temp = {vd_r[0],vd_r[1],vd_r[2],vd_r[3]};
        end
    endgenerate

    //将合并后的数据存入寄存器
    always@(posedge pixel_clk or negedge reset_l)begin
        if(((~(reset_l))) == 1'b1)
            data_merge <= {DVD_CHN*DW_DVD{1'b0}};
        else
        begin
            if(hsync_r[DVD_CHN] == 1'b1 & mux == 1'b1)
                data_merge <= #1 dvd_temp;
        end
    end

    //将合并后的数据打入异步fifo
    wire [DW_DVD*DVD_CHN-1:0] fifo_din;
    wire [DW_DVD*DVD_CHN-1:0] fifo_dout;

    wire [IMG_FIFO_DW_DEPTH-1:0] rdusedw;
    reg [9:0] trig_cnt;
    wire fifo_empty;
    reg fifo_wrreq;
    reg fifo_wrreq_r;
    //wire fifo_wrreq;

    //assign fifo_wrreq =  mux & hsync_r[DVD_CHN];

    reg fifo_rdreq;
    reg fifo_rdreq_r1;
    reg rst_fifo;

    //实例化异步fifo
/*     cross_clock_fifo img_fifo(
        .data(fifo_din),
        .rdclk(cap_clk),
        .rdreq(fifo_rdreq),
        .wrclk(pixel_clk),
        .wrreq(fifo_wrreq),
        .q(fifo_dout),
        .rdempty(fifo_empty),
        .rdusedw(rdusedw),
        .aclr(rst_fifo)
    ); */

fifo_generator_0 img_fifo (
  .rst(rst_fifo),                      // input wire rst
  .wr_clk(pixel_clk),                // input wire wr_clk
  .rd_clk(cap_clk),                // input wire rd_clk
  .din(fifo_din),                      // input wire [23 : 0] din
  .wr_en(fifo_wrreq),                  // input wire wr_en
  .rd_en(fifo_rdreq),                  // input wire rd_en
  .dout(fifo_dout),                    // output wire [23 : 0] dout
  .full(),                    // output wire full
  .empty(fifo_empty),                  // output wire empty
  .rd_data_count(rdusedw)  // output wire [9 : 0] rd_data_count
);
    /*
    defparam img_fifo.DW = DW_DVD*DVD_CHN;
    defparam img_fifo.DEPTH = IMG_FIFO_DEPTH;
    defparam img_fifo.DW_DEPTH = IMG_FIFO_DW_DEPTH;
    */

    assign fifo_din = data_merge;


    //RGB合并时写入fifo
    always@(posedge pixel_clk or negedge reset_l)begin
        if(reset_l == 1'b0)begin
            fifo_wrreq <= #1 1'b0;
            fifo_wrreq_r <= #1 1'b0;
        end
        else begin
            fifo_wrreq <= hsync_r[DVD_CHN] & mux_r;
            fifo_wrreq_r <= fifo_wrreq;
        end
    end

    //fifo中数据大于触发值时开始读，读完一行停止
    always@(posedge cap_clk or negedge reset_l)begin
        if(reset_l == 1'b0)
            fifo_rdreq <= #1 1'b0;
        else
        begin
            if((rdusedw >= TRIG_VALUE) & (fifo_empty == 1'b0))
                fifo_rdreq <= #1 1'b1;
            else if(trig_cnt == (IW - 1))
                fifo_rdreq <= #1 1'b0;
        end
    end

    //读计数
    always@(posedge cap_clk or negedge reset_l)begin
        if(reset_l == 1'b0)
            trig_cnt <= #1 {10{1'b0}};
        else
        begin
            if(fifo_rdreq == 1'b0)
                trig_cnt <= #1 {10{1'b0}};
            else
                if(trig_cnt == (IW - 1))
                    trig_cnt <= #1 {10{1'b0}};
                else
                    trig_cnt <= #1 trig_cnt + 10'b0000000001;
        end
    end

    wire [DW_LOCAL-1:0] img_din;

    assign img_din = ((cmd_en == 1'b0)) ? fifo_dout[DW_LOCAL-1:0] : {DW_LOCAL{1'b0}};

    assign cmd_din = ((cmd_en == 1'b1)) ? fifo_dout[DW_CMD-1:0] : {DW_CMD{1'b0}};

    //生成场同步信号、数据有效信号及像素数据输出
    reg vsync_async;
    reg vsync_async_r1;
    reg [VSYNC_WIDTH:0] vsync_async_r;
    reg cap_vsync_tmp;

    always@(posedge cap_clk or negedge reset_l)begin
        if(reset_l == 1'b0)
        begin
            vsync_async <= #1 1'b0;
            vsync_async_r1 <= #1 1'b0;
            vsync_async_r <= {VSYNC_WIDTH+1{1'b0}};
            cap_vsync_tmp <= #1 1'b0;
        end
        else
        begin
            vsync_async <= #1 (~vsync);
            vsync_async_r1 <= #1 vsync_async;
            vsync_async_r <= {vsync_async_r[VSYNC_WIDTH-1:0], vsync_async_r1};
            if(vsync_async_r[1] == 1'b1 & vsync_async_r[0] == 1'b0)
                cap_vsync_tmp <= #1 1'b1;
            else if(vsync_async_r[VSYNC_WIDTH] == 1'b0 & vsync_async_r[0] == 1'b0)
                cap_vsync_tmp <= #1 1'b0;
        end
    end

    assign cap_vsync = cap_vsync_tmp;

    always@(posedge cap_clk or negedge reset_l)begin
        if(reset_l==1'b0)
        begin
            cap_dat            <= #1 {DW_LOCAL{1'b0}};
            fifo_rdreq_r1     <= #1 1'b0;
            cap_dvalid         <= #1 1'b0;
            cmd_dat         <= #1 {DW_CMD{1'b0}};
            cmd_wrreq         <= #1 1'b0;
            cmd_wrreq_r     <= #1 1'b0;
        end
        else
        begin
            cap_dat         <= #1 img_din;
            fifo_rdreq_r1     <= #1 fifo_rdreq;
            cap_dvalid         <= #1 fifo_rdreq_r1 & (~(cmd_en));
            cmd_dat         <= #1 cmd_din;
            cmd_wrreq         <= #1 fifo_rdreq_r1 & cmd_en;
            cmd_wrreq_r     <= cmd_wrreq;
        end
    end

    //frame count and img_en signal
    reg [1:0] fr_cnt;
    reg img_out_en;

    always@(posedge cap_clk)begin
        if(vc_reset[1] == 1'b0)
        begin
            img_out_en <= 1'b0;
            fr_cnt <= {2{1'b0}};
        end
        else
        begin
            if(vsync_async_r1 == 1'b0 & vsync_async == 1'b1)
            begin
                fr_cnt <= fr_cnt + 2'b01;
                if(fr_cnt == 2'b11)
                    img_out_en <= 1'b1;
            end
        end
    end

    assign img_en = img_out_en;


    //行计数，确定cmd数据到来时刻
    always@(posedge cap_clk)begin
        if(cap_vsync_tmp == 1'b1)
        begin
            count_lines <= {10{1'b0}};
            cmd_en         <= 1'b0;
            cmd_rdy     <= 1'b0;
        end
        begin
            if(fifo_rdreq_r1 == 1'b1 & fifo_rdreq == 1'b0)
                count_lines <= #1 count_lines + 4'h1;
            if(count_lines == (IH - 2))
                rst_cmd_fifo <= 1'b1;
            else
                rst_cmd_fifo <= 1'b0;
            if(count_lines >= IH)
                cmd_en <= #1 1'b1;
            if(cmd_wrreq_r == 1'b1 & cmd_wrreq == 1'b0)
                cmd_rdy <= 1'b1;
            if(cmd_wrreq_r == 1'b1 & cmd_wrreq == 1'b0)
                rst_fifo <= 1'b1;
            else
                rst_fifo <= 1'b0;
        end
    end


    //Instance a line buffer to store the cmd line
/*     line_buffer_new
        cmd_buf(
            .aclr(rst_cmd_fifo),
            .clock(cap_clk),
            .data(cmd_dat),
            .rdreq(cmd_rdreq),
            .wrreq(cmd_wrreq),
            .empty(),
            .full(),
            .q(cmd_rdat),
            .usedw()
        ); */
fifo_generator_1 cmd_buf (
  .clk(cap_clk),      // input wire clk
  .srst(rst_cmd_fifo),    // input wire srst
  .din(cmd_dat),      // input wire [23 : 0] din
  .wr_en(md_wrreq),  // input wire wr_en
  .rd_en(cmd_rdreq),  // input wire rd_en
  .dout(cmd_rdat),    // output wire [23 : 0] dout
  .full(),    // output wire full
  .empty()  // output wire empty
);

    /*
    defparam cmd_buf.DW = DW_CMD;
    defparam cmd_buf.DEPTH = CMD_FIFO_DEPTH;
    defparam cmd_buf.DW_DEPTH = CMD_FIFO_DW_DEPTH;
    defparam cmd_buf.IW = IW;
    */
endmodule