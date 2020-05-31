--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:31:28 05/25/2020
-- Design Name:   
-- Module Name:   /home/ise/ise_projects/qspi_rom/top_test.vhd
-- Project Name:  qspi_rom
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY top_test IS
END top_test;
 
ARCHITECTURE behavior OF top_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         i_clk : IN  std_logic;
         i_nreset : IN  std_logic;
         o_spi_clk : OUT  std_logic;
         o_spi_nCS : OUT  std_logic;
         io_spi_IO : INOUT  std_logic_vector(3 downto 0);
         i_load : IN  std_logic;
         i_address : IN  std_logic_vector(23 downto 0);
         o_data : OUT  std_logic_vector(31 downto 0);
         o_data_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal i_clk : std_logic := '0';
   signal i_nreset : std_logic := '0';
   signal i_load : std_logic := '0';
   signal i_address : std_logic_vector(23 downto 0) := (others => '0');

	--BiDirs
   signal io_spi_IO : std_logic_vector(3 downto 0);

 	--Outputs
   signal o_spi_clk : std_logic;
   signal o_spi_nCS : std_logic;
   signal o_data : std_logic_vector(31 downto 0);
   signal o_data_valid : std_logic;

   -- Clock period definitions
   constant i_clk_period : time := 10 ns;
   constant o_spi_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          i_clk => i_clk,
          i_nreset => i_nreset,
          o_spi_clk => o_spi_clk,
          o_spi_nCS => o_spi_nCS,
          io_spi_IO => io_spi_IO,
          i_load => i_load,
          i_address => i_address,
          o_data => o_data,
          o_data_valid => o_data_valid
        );

   -- Clock process definitions
   i_clk_process :process
   begin
		i_clk <= '0';
		wait for i_clk_period/2;
		i_clk <= '1';
		wait for i_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		i_nreset <= '0';
		i_load <= '0';
		i_address <= x"123456";
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		i_nreset <= '1';
		
      wait for i_clk_period*100;
		
		i_load <= '1';
      wait for i_clk_period;
		i_load <= '0';

      wait;
   end process;

END;
