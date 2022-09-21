//this is the top level module
module digi_clock(input CLOCK_50,
						input [9:0] SW,
						input [3:0] KEY,
						output [6:0] HEX0, 
						output [6:0] HEX1, 
						output [6:0] HEX2, 
						output [6:0] HEX3, 
						output [6:0] HEX4, 
						output [6:0] HEX5);
	
	//define the enable input to the seconds counter
	wire clk;
	
	//mention the count variables for seconds, minutes and hours
	wire [5:0] count_sec;
	wire [5:0] count_min;
	wire [4:0] count_hour;
	
	//to store the 5 or 6 bit converted values into 4 bit values to send it to the decTo7 module
	reg [3:0] sec_hex0=4'd0;
	reg [3:0] sec_hex1=4'd0;
	reg [3:0] min_hex0=4'd0;
	reg [3:0] min_hex1=4'd0;
	reg [3:0] hour_hex0=4'd0;
	reg [3:0] hour_hex1=4'd0;
	
	//mention the enable I/O's which has to be given as the output to the next modules
	wire enable_sec;
	wire enable_min;
	//wire enable_hour;
	
	//this is the input which when inserted makes the value of all HEX displays to the value of the load input
	reg load;
	reg pre_load, pre_min, set_min;
	
	//defining the load inputs for the hours and minutes
	reg [4:0]load_input_hours=5'd0;    //={SW[9],SW[8],SW[7],SW[6],SW[5]};
	reg [5:0]load_input_minutes=6'd0;
//	assign load_input_minutes[5:1]={SW[4],SW[3],SW[2],SW[1],SW[0]};
//	assign load_input_minutes[0]=KEY[3];
	
	
	//instantiate the clock
	divide_by_50000000 clock(CLOCK_50,clk);
	
	//instantiating the seconds counter
	counter60 seconds(clk,load,6'b000000,count_sec,enable_sec);
	
	
	//instantiating the minutes counter
	counter60 minutes(enable_sec,load,load_input_minutes, count_min, enable_min);
	
	//instantiating the hours counter
	counter24 hours(enable_min,load,load_input_hours, count_hour);
	
	
	//convert the count values of 5 bit and 6 bit to 4 bits
	always @(count_sec or count_min or count_hour)
	begin
		sec_hex0  <= (count_sec % 10);
		sec_hex1  <= (count_sec / 10);
		min_hex0  <= (count_min % 10);
		min_hex1  <= (count_min / 10);
		hour_hex0 <= (count_hour % 10);
		hour_hex1 <= (count_hour / 10);
	end
	
	//prevent the debounce of KEY0
	always @ (posedge(CLOCK_50))
	begin 
		pre_load <= !KEY[0];
		load	   <= pre_load;
		pre_min  <= !KEY[3];
		set_min	   <= pre_min;			
	end
	
	always @ (posedge(CLOCK_50) or posedge(load))
	begin 
			load_input_minutes<={SW[4],SW[3],SW[2],SW[1],SW[0],set_min};
			load_input_hours  <={SW[9],SW[8],SW[7],SW[6],SW[5]};
	end
		
	
	
	//instantiate the hex displays
	decTo7 sec_hexa0(sec_hex0, HEX0);
	decTo7 sec_hexa1(sec_hex1, HEX1);
	decTo7 min_hexa0(min_hex0, HEX2);
	decTo7 min_hexa1(min_hex1, HEX3);
	decTo7 hour_hexa0(hour_hex0, HEX4);
	decTo7 hour_hexa1(hour_hex1, HEX5);
	
endmodule 

module counter60(input enable, 
					  input load, 
					  input [5:0] load_value, 
					  output reg [5:0] count, 
					  output reg carry);

	always @(posedge(enable) or posedge(load))
	begin
		if(load==1'b1)
		begin
			if(load_value>60)
			begin
				count<=0;
				end
			else
			begin
				count<=load_value;
			end
		end
		else
		begin
			if((count+1)==60)
			begin
				count<=((count+1)%60);
				carry<=1;
			end
			else
			begin
				count<=count+1;
				carry<=0;
			end		
		end
	end 
endmodule 


module counter24(input enable, 
					  input load, 
					  input [4:0] load_value, 
					  output reg [4:0] count);

	always @(posedge(enable) or posedge(load))
	begin
		if(load==1'b1)
		begin
			if(load_value>23)
			begin
				count<=0;
				end
			else
			begin
				count<=load_value;
			end
		end
		else
		begin
			if((count+1)==24)
			begin
				count<=((count+1)%24);
			end
			else
			begin
				count<=count+1;
			end		
		end
	end
endmodule 
	

	
module decTo7(input [3:0] in, output reg [6:0] out);	
	
	always @ (in)
	begin
		case (in)
			4'b0000: out=7'b1000000; //print 0
			4'b0001: out=7'b1111001; //print 1
			4'b0010: out=7'b0100100; //print 2
			4'b0011: out=7'b0110000; //print 3
			4'b0100: out=7'b0011001; //print 4
			4'b0101: out=7'b0010010; //print 5
			4'b0110: out=7'b0000010; //print 6
			4'b0111: out=7'b1111000; //print 7
			4'b1000: out=7'b0000000; //print 8
			4'b1001: out=7'b0010000; //print 9
			default: out=7'b1111111; //dont print anything if something else is given as input
		endcase  
	end	
endmodule 


//keeps the signal high for half second and low for another half second
module divide_by_50000000(input clk_1, output reg out);
	reg [25:0] count;
	
	always @ (posedge(clk_1) )
	begin
	if (count < 50000000)
	begin
		count <= count + 1;
		out <= 1'b0;
	end
	else
	begin
		count <= 0;
		out <= 1;
	end
end
endmodule	
	
	
