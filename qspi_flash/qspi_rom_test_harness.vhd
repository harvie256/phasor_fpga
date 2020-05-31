----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Derryn Harvie
-- 
-- Create Date:    13:56:31 05/26/2020 
-- Design Name: 
-- Module Name:    wiring - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity qspi_rom_test_harness is
    Port ( i_clk_50MHz : in  STD_LOGIC;
           i_nreset : in  STD_LOGIC;
           o_spi_clk : out  STD_LOGIC;
           io_spi_IO : inout  STD_LOGIC_VECTOR (3 downto 0);
           o_spi_ncs : out  STD_LOGIC;
			  LA: out std_logic_vector(18 downto 0) -- Logic Analyser connection
			  );
end qspi_rom_test_harness;

architecture Behavioral of qspi_rom_test_harness is
	COMPONENT qspi_rom
	generic(WordRunLength: integer);
	PORT(
		i_clk : IN std_logic;
		i_nreset : IN std_logic;
		i_load : IN std_logic;
		i_address : IN std_logic_vector(23 downto 0);    
		io_spi_IO : INOUT std_logic_vector(3 downto 0);      
		o_spi_clk : OUT std_logic;
		o_spi_nCS : OUT std_logic;
		o_data : OUT std_logic_vector(15 downto 0);
		o_data_valid : OUT std_logic
		);
	END COMPONENT;

	component clk_mul
	port
	 (-- Clock in ports
	  CLK_IN_50MHz           : in     std_logic;
	  -- Clock out ports
	  CLK_OUT_100MHz          : out    std_logic;
	  -- Status and control signals
	  LOCKED            : out    std_logic
	 );
	end component;
	
	signal load : std_logic := '0';
	signal address : std_logic_vector(23 downto 0);
	signal data, data_output : std_logic_vector(15 downto 0);
	
	signal data_valid : std_logic;
	signal data_valid_delay : std_logic_vector(2 downto 0) := "000";
	
	signal nreset : std_logic := '1';
	
	signal sys_clk, pll_lock : std_logic;
		
begin


-- Output the received data on the Logic Analyser port
LA(15 downto 0) <= data_output;
LA(16) <= data_valid_delay(2);

clk_pll : clk_mul
  port map
   (-- Clock in ports
    CLK_IN_50MHz => i_clk_50MHz,
    -- Clock out ports
    CLK_OUT_100MHz => sys_clk,
    -- Status and control signals
    LOCKED => pll_lock);
	 

	Inst_qspi_rom: qspi_rom 
	generic map(WordRunLength => 64) -- pulling out the first 128 bytes from flash
	PORT MAP(
		i_clk => sys_clk,
		i_nreset => nreset,
		o_spi_clk => o_spi_clk,
		o_spi_nCS => o_spi_ncs,
		io_spi_IO => io_spi_IO,
		i_load => load,
		i_address => address,
		o_data => data,
		o_data_valid => data_valid
	);

-- Reset switch debounce.
process(sys_clk)
variable reset_debounce_counter : integer range 0 to 100000 := 0;
begin
	if rising_edge(sys_clk) then
		nreset <= pll_lock;
		if i_nreset = '0' then
			if reset_debounce_counter = 100000 then
				nreset <= '0';
			else
				reset_debounce_counter := reset_debounce_counter + 1;
			end if;
		else
			reset_debounce_counter := 0;
		end if;
	end if;
end process;

-- Data valid delay - this is just to allow my relatively slow logic analyser to fully
-- register the data lines changing before triggering the decoder on the new data word.
process(sys_clk)
begin
	if rising_edge(sys_clk) then
		data_valid_delay <= data_valid_delay(1 downto 0) & data_valid;
	
		if data_valid = '1' then
			data_output <= data;
		else
			data_output <= data_output;
		end if;
	end if;
end process;


-- Address generation and data verification
process(sys_clk)
variable data_load_counter : integer range 2000 downto 0 := 2000;
variable address_counter : integer range 1 downto 0 := 0;

variable byte_check : integer range 129 downto 1 := 128;

begin
	if rising_edge(sys_clk) then
		if data_load_counter = 0 then
			load <= '1';
			data_load_counter := 2000;
			byte_check := 128;
			if address_counter = 0 then
				address <= std_logic_vector(to_unsigned(0, address'length));
				address_counter := 1;
			else
				address <= std_logic_vector(to_unsigned(128, address'length));
				address_counter := 0;
			end if;
		else
			load <= '0';
			data_load_counter := data_load_counter -1;

			if data_valid = '1' then
				LA(17) <= '0';
				LA(18) <= '0';

				if to_integer(unsigned(data(15 downto 8))) /= byte_check then
					LA(17) <= '1';
				end if;
				
				if to_integer(unsigned(data(7 downto 0))) /= (byte_check-1) then
					LA(18) <= '1';
				end if;
				
				byte_check := byte_check -2;
			
			end if;
			
		end if;
	end if;
end process;


end Behavioral;

