
module counter #(parameter WIDTH = 7)(
	input logic [WIDTH-1:0] counter_N,
	input logic clk, rstn, counter_en,
	output logic [31:0] counter_out,
	output logic counter_words,	// whether to count bytes or words
	output logic counter_done
);
	logic [WIDTH-1:0] ci;
	
	always @(posedge clk or negedge rstn) begin
		if (!rstn) 
			ci <= 'b0;
			
		else if (counter_en) begin
			if (counter_done) 
				ci <= 'b0;
			else if (counter_words)
				ci <= ci + 4;
			else 
				ci <= ci + 1;
		end
		
		else ci <= ci;
	end
	
	assign counter_done = (ci + 1 == counter_N) || (ci + 4 == counter_N);
	assign counter_out = {{(32-WIDTH){1'b0}}, ci};
	assign counter_words = (ci + 4 < counter_N);
	
endmodule
			
		