
output wire  left_addr;

wire inst_valid;
wire left_quant_valid;
reg  reg_left_quant_valid;
wire coef_end
wire right_quant_valid;
reg  reg_right_quant_valid;
wire left_req_ready;
wire right_req_ready;
wire left_buffer_ready;
wire right_buffer_ready;
wire index_buffer_readt;

reg CSR_QUANT;
reg k_max;
reg k_cnt;
reg n_max;
reg n_cnt;
reg m_max;
reg m_cnt;
reg unit_row_max;
reg unit_row_cnt;
wire k_last;
wire n_last;
wire m_last;
wire unit_row_last;
wire left_read_finish;


reg left_state;

k_last = k_max - 1 == k_cnt;
n_last = n_max - 1 == n_cnt;
m_last = m_max - 1 == m_cnt;
unit_row_last = unit_row_max - 1 == unit_row_cnt;
left_read_finish = m_last && n_last && k_last && unit_row_last;

`define FSM_SRC_IDLE 0
`define FSM_COF_READ 1
`define FSM_COF_WAIT 2
`define FSM_SRC_READ 3
`define FSM_SRC_WAIT 4

always @(posedge clk) begin
    if (rstn) begin
        left_state <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    case(left_state)
        `FSM_SRC_IDLE   :
            if (inst_valid) begin
                if (left_quant_valid || right_quant_valid) begin
                    left_state <= `FSM_COF_READ;
                end
                else begin
                    left_state <= `FSM_SRC_READ;
                end
            end
            else begin
                left_state <= `FSM_SRC_IDLE;
            end

        `FSM_COF_READ   :
            if (left_req_ready) begin
                if (reg_quant_max - 1 == reg_quant_cnt) begin
                    left_state <= `FSM_SRC_READ;
                end
                else begin
                    left_state <= `FSM_COF_READ;
                end
            end
            else begin
                left_state <= `FSM_COF_WAIT;
            end
        `FSM_COF_WAIT   :
            if (left_req_ready) begin
                if (reg_quant_max - 1 == reg_quant_cnt) begin
                    left_state <= `FSM_SRC_READ;
                end
                else begin
                    left_state <= `FSM_COF_READ;
                end
            end
            else begin
                left_state <= `FSM_COF_WAIT;
            end
        `FSM_SRC_READ   :
            if (left_buffer_ready && left_req_ready) begin
                if (left_read_finish) begin
                    left_state <= `FSM_SRC_IDLE;
                end
                else if (unit_row_last) begin
                    if (reg_left_quant_valid || reg_right_quant_valid && k_last) begin
                        left_state <= `FSM_COF_READ;
                    end
                    else begin
                        left_state <= `FSM_SRC_READ;
                    end
                end
                else begin
                    left_state <= `FSM_SRC_READ;
                end
            end
            else begin
                left_state <= `FSM_SRC_WAIT;
            end
        `FSM_SRC_WAIT   :
            if (left_buffer_ready && left_req_ready) begin
                if (left_read_finish) begin
                    left_state <= `FSM_SRC_IDLE;
                end
                else if (unit_row_last) begin
                    if (reg_left_quant_valid) begin
                        left_state <= `FSM_COF_READ;
                    end
                    else if (reg_right_quant_valid && k_last) begin
                        left_state <= `FSM_COF_READ;
                    end
                    else begin
                        left_state <= `FSM_SRC_READ;
                    end
                end
                else begin
                    left_state <= `FSM_SRC_READ;
                end
            end
            else begin
                left_state <= `FSM_SRC_WAIT
            end
    endcase
end

wire left_state_idle     = left_state == `FSM_SRC_IDLE;
wire left_state_coe_read = left_state == `FSM_COF_READ;
wire left_state_coe_wait = left_state == `FSM_COF_WAIT;
wire left_state_src_read = left_state == `FSM_SRC_READ;
wire left_state_src_wait = left_state == `FSM_SRC_WAIT;


always @(posedge clk or negedge rstn) begin
    if (rstn) begin
        k_max <= 0;
        k_cnt <= 0;
        n_max <= 0;
        n_cnt <= 0;
        m_max <= 0;
        m_cnt <= 0;
        unit_row_max <= 0;
        unit_row_cnt <= 0;
    end
    else if (left_state_idle && inst_valid) begin
        k_max <= X;
        k_cnt <= 0;
        n_max <= X;
        n_cnt <= 0;
        m_max <= X;
        m_cnt <= 0;
        reg_quant_cnt = 0;
        if (left_quant_valid) begin
            reg_left_quant_valid <= 1;
            reg_quant_max   <= X;
            next_left_addr = start_quant_addr;
        end
        else if (right_quant_valid) begin
            reg_right_quant_valid <= 1;
            reg_quant_max   <= X;
            next_left_addr = start_quant_addr;
        end
        else begin
            reg_quant_max <= 0;
            next_left_addr = start_src_addr;
        end
    end
    else if (left_state_coe_read && ram_ready) begin
        if (reg_quant_max - 1 == reg_quant_cnt) begin
            reg_quant_cnt <= 0;
            reg_quant_max <= 0;
            unit_row_max <= X;
            unit_row_cnt <= 0;
            left_addr = src_addr;
        end
        else begin
            reg_quant_cnt <= reg_quant_cnt + 1; 
            left_addr = next_quant_addr;
        end 
    end
    else if (left_state_coe_wait && ram_ready) begin
        if (reg_quant_max - 1 == reg_quant_cnt) begin
            reg_quant_cnt <= 0;
            reg_quant_max <= 0;
            unit_row_max <= X;
            unit_row_cnt <= 0;
            next_left_addr = src_addr;
        end
        else begin
            reg_quant_cnt <= reg_quant_cnt + 1;
            next_left_addr = next_quant_addr;
        end
    end
    else if (left_state_src_read && left_buffer_ready && left_req_ready) begin
        if (unit_row_last) begin
            if (reg_left_quant_valid || reg_right_quant_valid && k_last) begin
                reg_quant_cnt <= 0;
                reg_quant_max <= X;
                unit_row_max <= 0;
                unit_row_cnt <= 0;
                next_left_addr <= next_quant_addr;
            end
            else if (left_read_finish) begin
                k_max <= 0;
                k_cnt <= 0;
                n_max <= 0;
                n_cnt <= 0;
                m_max <= 0;
                m_cnt <= 0;
                unit_row_max <= 0;
                unit_row_cnt <= 0;
                next_left_addr <= 0;
            end
            else begin
                unit_row_max <= X;
                unit_row_cnt <= 0;
                next_left_addr <= src_addr;
            end
        end
        else begin
            unit_row_cnt <= unit_row_cnt + 1;
            next_left_addr <= src_addr;
        end
    end
    else if (left_state_src_wait && left_buffer_ready && left_req_ready) begin
        if (left_read_finish) begin
                k_max <= 0;
                k_cnt <= 0;
                n_max <= 0;
                n_cnt <= 0;
                m_max <= 0;
                m_cnt <= 0;
                unit_row_max <= 0;
                unit_row_cnt <= 0;
                left_addr <= 0;
        end
        else if (unit_row_last) begin
            if (reg_left_quant_valid || reg_right_quant_valid && k_last) begin
                left_state <= `FSM_COF_READ;
                reg_quant_cnt <= 0;
                reg_quant_max <= X;
                unit_row_max <= 0;
                unit_row_cnt <= 0;
                left_addr <= next_quant_addr;
            end
            else begin
                unit_row_max <= X;
                unit_row_cnt <= 0;
                left_addr <= src_addr;
            end
        end
        else begin
            unit_row_cnt <= unit_row_cnt + 1;
            left_addr <= src_addr;
        end
    end
end
//地址计算逻辑
wire left_addr_send_success =   (left_state_src_wait  || left_state_src_read) && left_buffer_ready && left_req_ready
reg   next_left_addr;
wire   left_addr;    
wire  fill_left_addr;     
always @(posedge clk ) begin
    if (left_addr_send_success) begin
        if (unit_row_last) begin
            if (addr_is_align) begin
                concat_finish <= 1;
                unit_row_cnt <= 0;
                next_left_addr <= next_left_addr +  cstride;
            end
            else begin
                concat_finish <= 0;
            end
            next_left_addr <= next_left_addr +  cstride;
            unit_row_cnt <= 0;
            k_cnt <= k_cnt + 1;


            if (k_last) begin
                k_cnt <= 0;
                n_cnt <= n_cnt + 1;
                if (n_last) begin
                    n_cnt <= 0;
                    m_cnt <= m_cnt + 1;
                    if (m_last) begin
                        m_cnt <= 0;
                    end
                end
            end
        end
        else begin
            next_left_addr <= next_left_addr + unit_row_elem_number * unit_row_elem_type;
            if (concat_finish) begin
                unit_row_cnt <= unit_row_cnt + 1;
                next_left_addr <= next_left_addr + unit_row_elem_number * unit_row_elem_type;
                concat_finish <= addr_is_align;
            end
            else begin
                concat_finish <= 1;
                next_left_addr <= fill_left_addr;
            end
        end
    end
end
// 判断地址是否对齐
reg concat_finish; // 1
fill_left_addr = next_left_addr + unit_row_elem_number * unit_row_elem_type;
addr_is_align = left_addr[32:8] == fill_left_addr[32:8];
concat_finish = addr_is_align;


left_addr = next_left_addr;


// 地址计算