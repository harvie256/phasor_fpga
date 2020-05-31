----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:21:24 05/26/2020 
-- Design Name: 
-- Module Name:    spi_passthrough - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_passthrough is
    Port ( 
			  o_spi_clk : out  STD_LOGIC;
           io_spi_IO : inout  STD_LOGIC_VECTOR (3 downto 0);
           o_spi_ncs : out  STD_LOGIC;
			  
			  arduino_spi_clk_i : in std_logic;
			  arduino_spi_MOSI : in std_logic;
			  arduino_spi_MISO : out std_logic;
			  arduino_spi_nCS : in std_logic;
			  
			  arduino_IO_CTRL : in std_logic;
			  arduino_nWP : in std_logic;
			  arduino_nHOLD : in std_logic;
			  o_IO_CTRL : out std_logic
			  );
			  
			  
			  
end spi_passthrough;

architecture Behavioral of spi_passthrough is

	signal output_io_spi_IO : std_logic_vector(3 downto 0) := x"F";
	signal input_io_spi_IO : std_logic_vector(3 downto 0);

begin

input_io_spi_IO <= io_spi_IO;
io_spi_IO(0) <= output_io_spi_IO(0) when arduino_IO_CTRL = '1' else 'Z';
io_spi_IO(1) <= 'Z';
io_spi_IO(2) <= output_io_spi_IO(2) when arduino_IO_CTRL = '1' else 'Z';
io_spi_IO(3) <= output_io_spi_IO(3) when arduino_IO_CTRL = '1' else 'Z';

o_IO_CTRL <= arduino_IO_CTRL;

output_io_spi_IO(0) <= arduino_spi_MOSI;
output_io_spi_IO(2) <= arduino_nWP;
output_io_spi_IO(3) <= arduino_nHOLD;

arduino_spi_MISO <= input_io_spi_IO(1);

o_spi_clk <= arduino_spi_clk_i;
o_spi_ncs <= arduino_spi_nCS;

end Behavioral;

