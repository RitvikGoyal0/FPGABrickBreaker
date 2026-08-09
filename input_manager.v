module input_manager(
    input btn_right,
    input btn_left,
    input btn_rst,

    output right_sig,
    output left_sig,
    output go_sig,
    output rst_sig
);
    assign right_sig = ~btn_right;
    assign left_sig  = ~btn_left;
    assign go_sig    = ~btn_right && ~btn_left;
    assign rst_sig   = ~btn_rst;

endmodule