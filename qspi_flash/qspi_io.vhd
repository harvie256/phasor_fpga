----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Derryn Harvie
-- 
-- Create Date:    14:14:38 05/29/2020 
-- Design Name: 
-- Module Name:    qspi_io - Behavioral 
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

entity qspi_io is
    Port ( i_sys_clk : in  STD_LOGIC; -- Input clock
           i_spi_CS_enable : in  STD_LOGIC; -- Active high signal will start nCS on the next falling DDR edge
           i_spi_clk_enable : in  STD_LOGIC; -- Active high signal will start clock
           i_spi_data_direction : in  STD_LOGIC; -- 3-state enable input, high=input, low=output
           i_spi_data_out : in  STD_LOGIC_VECTOR (3 downto 0); -- Data to be transmitted
			  o_spi_data_in : out  STD_LOGIC_VECTOR (3 downto 0); -- Data clocked in through input registers
           o_spi_clk_pin : out  STD_LOGIC;
           o_spi_cs_pin : out  STD_LOGIC;
           io_spi_data_pin : inout  STD_LOGIC_VECTOR (3 downto 0));
end qspi_io;

architecture Behavioral of qspi_io is
	signal sys_clk, n_sys_clk : std_logic;
	
	signal spi_nCS_line : std_logic_vector(1 downto 0);
	signal spi_clk_line : std_logic;
	signal io0,io1,io2,io3 : std_logic_vector(1 downto 0);
	
	signal io_internal_buffer_input : std_logic_vector(3 downto 0); -- connection between ODDR2 primative and IOBUF primative, internal to IOB
	signal io_internal_T_input : std_logic_vector(3 downto 0); -- connection between ODDR2 primative and IOBUF tristate connection, internal to IOB

	signal io_input_buffer_to_DDR : std_logic_vector(3 downto 0); -- connection between the IOBUF primative and the IDDR2 primative
	

begin

	sys_clk <= i_sys_clk;
	n_sys_clk <= not i_sys_clk;

-- Chip Select driver
	nCS_process: process(sys_clk)
	begin
		if rising_edge(sys_clk) then
			if i_spi_CS_enable = '1' then
				spi_nCS_line <= spi_nCS_line(0) & '0';
			else
				spi_nCS_line <= "11";
			end if;
		end if;
	end process;

	ODDR2_spi_nCS : ODDR2
	generic map(
		DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
		INIT => '0', -- Sets initial state of the Q output to '0' or '1'
		SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
	port map (
		Q => o_spi_cs_pin, -- 1-bit output data
		C0 => sys_clk, -- 1-bit clock input
		C1 => n_sys_clk, -- 1-bit clock input
		CE => '1',  -- 1-bit clock enable input
		D0 => spi_nCS_line(0),   -- 1-bit data input (associated with C0)
		D1 => spi_nCS_line(1),   -- 1-bit data input (associated with C1)
		R => '0',    -- 1-bit reset input
		S => '0'     -- 1-bit set input
	);

-- SPI Clock driver
	spi_clk_process: process(sys_clk)
	begin
		if rising_edge(sys_clk) then
			if i_spi_clk_enable = '1' then
				spi_clk_line <= '1';
			else
				spi_clk_line <= '0';
			end if;
		end if;
	end process;

   ODDR2_spi_clk : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => o_spi_clk_pin, -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => '0',   -- 1-bit data input (associated with C0)
      D1 => spi_clk_line,   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

-- Data Line Driver
	spi_data_process: process(sys_clk)
	begin
		if rising_edge(sys_clk) then
			io0 <= io0(0) & i_spi_data_out(0);
			io1 <= io1(0) & i_spi_data_out(1);
			io2 <= io2(0) & i_spi_data_out(2);
			io3 <= io3(0) & i_spi_data_out(3);
		end if;
	end process;

-- Output Data DDR registers
   ODDR2_io0 : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_buffer_input(0), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => io0(0),   -- 1-bit data input (associated with C0)
      D1 => io0(1),   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   ODDR2_io1 : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_buffer_input(1), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => io1(0),   -- 1-bit data input (associated with C0)
      D1 => io1(1),   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   ODDR2_io2 : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_buffer_input(2), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => io2(0),   -- 1-bit data input (associated with C0)
      D1 => io2(1),   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
   ODDR2_io3 : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_buffer_input(3), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => io3(0),   -- 1-bit data input (associated with C0)
      D1 => io3(1),   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

-- Tristate DDR registers
	ODDR2_io0_T : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_T_input(0), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => i_spi_data_direction,   -- 1-bit data input (associated with C0)
      D1 => i_spi_data_direction,   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	ODDR2_io1_T : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_T_input(1), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => i_spi_data_direction,   -- 1-bit data input (associated with C0)
      D1 => i_spi_data_direction,   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	ODDR2_io2_T : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_T_input(2), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => i_spi_data_direction,   -- 1-bit data input (associated with C0)
      D1 => i_spi_data_direction,   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	ODDR2_io3_T : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => io_internal_T_input(3), -- 1-bit output data
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D0 => i_spi_data_direction,   -- 1-bit data input (associated with C0)
      D1 => i_spi_data_direction,   -- 1-bit data input (associated with C1)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

-- Input DDR registers
   IDDR2_inst_io0 : IDDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT_Q0 => '0', -- Sets initial state of the Q0 output to '0' or '1'
      INIT_Q1 => '0', -- Sets initial state of the Q1 output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q0 => o_spi_data_in(0), -- 1-bit output captured with C0 clock
      Q1 => open, -- 1-bit output captured with C1 clock
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D => io_input_buffer_to_DDR(0),   -- 1-bit data input 
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   IDDR2_inst_io1 : IDDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT_Q0 => '0', -- Sets initial state of the Q0 output to '0' or '1'
      INIT_Q1 => '0', -- Sets initial state of the Q1 output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q0 => o_spi_data_in(1), -- 1-bit output captured with C0 clock
      Q1 => open, -- 1-bit output captured with C1 clock
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D => io_input_buffer_to_DDR(1),   -- 1-bit data input 
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	IDDR2_inst_io2 : IDDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT_Q0 => '0', -- Sets initial state of the Q0 output to '0' or '1'
      INIT_Q1 => '0', -- Sets initial state of the Q1 output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q0 => o_spi_data_in(2), -- 1-bit output captured with C0 clock
      Q1 => open, -- 1-bit output captured with C1 clock
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D => io_input_buffer_to_DDR(2),   -- 1-bit data input 
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	IDDR2_inst_io3 : IDDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT_Q0 => '0', -- Sets initial state of the Q0 output to '0' or '1'
      INIT_Q1 => '0', -- Sets initial state of the Q1 output to '0' or '1'
      SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q0 => o_spi_data_in(3), -- 1-bit output captured with C0 clock
      Q1 => open, -- 1-bit output captured with C1 clock
      C0 => sys_clk, -- 1-bit clock input
      C1 => n_sys_clk, -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D => io_input_buffer_to_DDR(3),   -- 1-bit data input 
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

-- Tristate buffers
   IOBUF_io0 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => io_input_buffer_to_DDR(0),     -- Buffer output
      IO => io_spi_data_pin(0),   -- Buffer inout port (connect directly to top-level port)
      I => io_internal_buffer_input(0), -- Buffer input
      T => io_internal_T_input(0)      -- 3-state enable input, high=input, low=output 
   );

   IOBUF_io1 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => io_input_buffer_to_DDR(1),     -- Buffer output
      IO => io_spi_data_pin(1),   -- Buffer inout port (connect directly to top-level port)
      I => io_internal_buffer_input(1), -- Buffer input
      T => io_internal_T_input(1)      -- 3-state enable input, high=input, low=output 
   );

   IOBUF_io2 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => io_input_buffer_to_DDR(2),     -- Buffer output
      IO => io_spi_data_pin(2),   -- Buffer inout port (connect directly to top-level port)
      I => io_internal_buffer_input(2), -- Buffer input
      T => io_internal_T_input(2)      -- 3-state enable input, high=input, low=output 
   );
	
   IOBUF_io3 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => io_input_buffer_to_DDR(3),     -- Buffer output
      IO => io_spi_data_pin(3),   -- Buffer inout port (connect directly to top-level port)
      I => io_internal_buffer_input(3), -- Buffer input
      T => io_internal_T_input(3)      -- 3-state enable input, high=input, low=output 
   );

end Behavioral;

