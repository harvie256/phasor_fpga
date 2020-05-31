----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:34:12 05/25/2020 
-- Design Name: 
-- Module Name:    top - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity qspi_rom is
	generic(WordRunLength: integer range 1 to 255 := 2);
    Port ( i_clk : in  STD_LOGIC;
			  i_nreset : in STD_LOGIC;
           o_spi_clk : out  STD_LOGIC;
           o_spi_nCS : out  STD_LOGIC;
           io_spi_IO : inout  STD_LOGIC_VECTOR (3 downto 0);
			  i_load : in std_logic;
			  i_address : in std_logic_vector(23 downto 0);
			  o_data : out std_logic_vector(15 downto 0);
			  o_data_valid : out std_logic
			  );
end qspi_rom;

architecture Behavioral of qspi_rom is

	component qspi_io is
		 Port ( i_sys_clk : in  STD_LOGIC;
				  i_spi_CS_enable : in  STD_LOGIC;
				  i_spi_clk_enable : in  STD_LOGIC;
				  i_spi_data_direction : in  STD_LOGIC; -- 3-state enable input, high=input, low=output
				  i_spi_data_out : in  STD_LOGIC_VECTOR (3 downto 0);
				  o_spi_data_in : out  STD_LOGIC_VECTOR (3 downto 0);
				  o_spi_clk_pin : out  STD_LOGIC;
				  o_spi_cs_pin : out  STD_LOGIC;
				  io_spi_data_pin : inout  STD_LOGIC_VECTOR (3 downto 0));
	end component;

	signal spi_CS_enable, spi_clk_enable, spi_data_direction : std_logic;
	signal spi_data_in : std_logic_vector(3 downto 0);
	
	signal spi_clk_enable_control : std_logic := '0';
	
	signal xip_mode : std_logic := '0';
	signal flash_address : std_logic_vector(31 downto 0) := x"00000000";
	signal data_word : std_logic_vector(15 downto 0);

begin

spi_io : qspi_io 
	port map (
		i_sys_clk => i_clk,
		i_spi_CS_enable => spi_CS_enable,-- Active high signal will start nCS on the next falling DDR edge
		i_spi_clk_enable => spi_clk_enable,-- Active high signal will start clock
		i_spi_data_direction => spi_data_direction, -- 3-state enable input, high=input, low=output
		i_spi_data_out => flash_address(31 downto 28),-- Data to be transmitted
		o_spi_data_in => spi_data_in, -- Data clocked in through input registers
		o_spi_clk_pin => o_spi_clk,
		o_spi_cs_pin => o_spi_nCS,
		io_spi_data_pin => io_spi_IO
	);
		
o_data <= data_word;

spi_state_machine: process(i_clk)
	variable state_counter : integer range 0 to 37 := 0;
	variable data_shift_counter : integer range 0 to 4 := 0;
	variable word_counter : integer range 0 to 255 := 0;
	begin
		if rising_edge(i_clk) then
			-- Default asignments
			-- Register hold the output data
			data_word <= data_word;
			o_data_valid <= '0';

			spi_CS_enable <= '1'; -- Default, nCS driven
			spi_data_direction <= '0'; -- Default output

		-- Reset vector
			if i_nreset = '0' then
			-- On reset we do not know the status of the flash memory, if still powered it may be in XIP mode already.
				state_counter := 37;
				spi_data_direction <= '1'; -- Input while reset is held
				spi_CS_enable <= '0'; -- Chip select idle while reset is held
				--spi_clk_enable <= '0'; -- Spi Clock off
			else
				case state_counter is
					when 0 =>
						state_counter := 0;
						-- Idle the bus with nCS high and the bus driven
						spi_data_direction <= '0';
						spi_CS_enable <= '0';
						spi_clk_enable <= '0';
						
						if i_load = '1' then
							-- load address
							flash_address <= i_address & x"A0"; -- M code bytes sit on the end of the address
							spi_CS_enable <= '1';
							state_counter := 16;
						end if;
					
					-- Reset the flash into normal operation, then enter XIP mode
					-- 8 spi clocks of 1 , i.e. 0xFF command, will put the device into normal SPI mode
					-- in the situation the FPGA is reset while the flash memory is still in XIP mode.		
						
					when 37 =>
						flash_address <= x"FFFFFFFF";
						spi_data_direction <= '0'; -- bus output
						spi_CS_enable <= '1'; -- chip select active
						spi_clk_enable <= '0';
						state_counter := state_counter -1;
					
					when 36 downto 29 =>
						spi_data_direction <= '0'; -- bus output
						spi_CS_enable <= '1'; -- chip select active
						spi_clk_enable <= '1';
						state_counter := state_counter -1;
					
					-- idle the bus for a couple of clock cycles between instructions.
					when 28 downto 26 =>
						spi_data_direction <= '1'; -- bus input
						spi_CS_enable <= '0'; -- chip select inactive
						spi_clk_enable <= '0';
						state_counter := state_counter -1;

					-- shift out the 0xEB instruction to put into XIP mode,
					-- this will transition directly into the normal read instruction.
					when 25 =>
						flash_address <= x"99989899";
						spi_data_direction <= '0'; -- bus output
						spi_CS_enable <= '1'; -- chip select active
						spi_clk_enable <= '0';
						state_counter := state_counter -1;

					when 24 downto 17 =>
						spi_data_direction <= '0'; -- bus output
						spi_clk_enable <= '1';
						spi_CS_enable <= '1';
						if state_counter = 18 then
							flash_address <= flash_address(27 downto 0) & x"A"; -- shift in the M-code byte
						else
							flash_address <= flash_address(27 downto 0) & x"0";
						end if;
						state_counter := state_counter -1;
					
					
					-- XIP Mode - system normal operation
					-- Address, M-code and dummy bytes output
					when 16 downto 5 =>
						-- On the last dummy byte the IO needs to switch to 'Z'
						spi_clk_enable <= '1';
						spi_CS_enable <= '1';

						spi_data_direction <= '0'; -- bus output
						flash_address <= flash_address(27 downto 0) & x"0";
						state_counter := state_counter -1;

					-- Switch the bus into 'Z' to read in the data
					-- and reset the data counters
					when 2 to 4 =>
						spi_data_direction <= '1'; -- bus input
						spi_clk_enable <= '1';
						spi_CS_enable <= '1';
						
						flash_address <= flash_address(27 downto 0) & x"0";
						state_counter := state_counter -1;
						
						data_shift_counter := 0;
						word_counter := 0;					
						
						-- Read in data
					when 1 =>
						spi_data_direction <= '1'; -- bus input
						spi_clk_enable <= '1';
						spi_CS_enable <= '1';
						
						data_word <= data_word(11 downto 0) & spi_data_in; -- Shift the data into a word
						
						data_shift_counter := data_shift_counter + 1;
						if data_shift_counter=4 then
							o_data_valid <= '1';
							data_shift_counter:=0;
							word_counter := word_counter +1;
						end if;
						
						if word_counter = WordRunLength then
							state_counter := 0;
						else
							state_counter := 1;
						end if;

					when others =>
						state_counter := 0;
						spi_data_direction <= '0'; -- bus output
						spi_clk_enable <= '0';
						spi_CS_enable <= '0';				

				end case;
				
			end if;		
		end if;
	end process spi_state_machine;

		
end Behavioral;

