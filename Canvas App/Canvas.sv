module vga_controller (
    input  logic        clk_100MHz,
    input  logic        reset,
    input  logic        btnu,
    input  logic        btnd,
    input  logic        btnr,
    input  logic        btnl,
    input  logic        btnc,
    input  logic [7:0]  switches,
    output logic        hsync,
    output logic        vsync,
    output logic [3:0]  red,
    output logic [3:0]  green,
    output logic [3:0]  blue
);

    parameter HD = 640;
    parameter VD = 480;

  
    logic [1:0] clk_div;
    logic       pixel_clk;

    always_ff @(posedge clk_100MHz or posedge reset) begin
        if (reset)
            clk_div <= 2'b0;
        else
            clk_div <= clk_div + 1;
    end

    assign pixel_clk = clk_div == 2'b00;

  
    logic [9:0] h_count, v_count;

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == 799) begin
                h_count <= 10'd0;
                if (v_count == 524)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

   
    assign hsync = ~(h_count >= 656 && h_count < 752);
    assign vsync = ~(v_count >= 490 && v_count < 492);

  
    logic video_active;
    assign video_active = (h_count < HD) && (v_count < VD);

    
    logic [9:0] x_cursor, y_cursor;


    logic [20:0] slow_clk_div;
    logic        slow_clk;

    always_ff @(posedge clk_100MHz or posedge reset) begin
        if (reset)
            slow_clk_div <= 21'd0;
        else
            slow_clk_div <= slow_clk_div + 1;
    end

    assign slow_clk = slow_clk_div[20]; 

    always_ff @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            x_cursor <= HD / 2;
            y_cursor <= VD / 2;
        end else begin
            if (btnr && x_cursor < HD - 1) x_cursor <= x_cursor + 1;
            if (btnl && x_cursor > 0) x_cursor <= x_cursor - 1;
            if (btnu && y_cursor > 0) y_cursor <= y_cursor - 1;
            if (btnd && y_cursor < VD - 1) y_cursor <= y_cursor + 1;
        end
    end

   
    logic [3:0] color_red, color_green, color_blue;

    always_comb begin
    case (switches)
        8'b00000001: {color_red, color_green, color_blue} = {4'hF, 4'h0, 4'h0};  
        8'b00000010: {color_red, color_green, color_blue} = {4'h0, 4'hF, 4'h0};   
        8'b00000100: {color_red, color_green, color_blue} = {4'h0, 4'h0, 4'hF};    
        8'b00001000: {color_red, color_green, color_blue} = {4'hF, 4'hF, 4'h0};   
        8'b00010000: {color_red, color_green, color_blue} = {4'h0, 4'hF, 4'hF};   
        8'b00100000: {color_red, color_green, color_blue} = {4'hF, 4'h0, 4'hF};   
        8'b01000000: {color_red, color_green, color_blue} = {4'hF, 4'hF, 4'hF};    
        8'b10000000: {color_red, color_green, color_blue} = {4'h0, 4'h0, 4'h0};
        default: {color_red, color_green, color_blue} = {4'hF, 4'hF, 4'hF};      
    endcase
end

  
    logic [11:0] canvas_memory [(HD * VD) - 1:0];
    logic [11:0] canvas_data;

  
    initial begin
        for (int i = 0; i < HD * VD; i++) begin
            canvas_memory[i] = 12'hFFF; 
        end
    end

    always_ff @(posedge pixel_clk) begin
        if (btnc) begin
           
            canvas_memory[y_cursor * HD + x_cursor] <= {color_red, color_green, color_blue};
        end
      
        canvas_data <= canvas_memory[v_count * HD + h_count];
    end

    
    always_comb begin
        if (video_active) begin
        
            if ((h_count == x_cursor) && (v_count == y_cursor)) begin
                red   = 4'h0;
                green = 4'h0;
                blue  = 4'h0;
            end else begin
              
                {red, green, blue} = canvas_data;
            end
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

endmodule

