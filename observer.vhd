library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
library altera_mf;
use altera_mf.all;
entity observer is
port
(
    in_clk : in std_logic;
    in_reset : in std_logic;
    in_execute : in std_logic;

    in_data_a : in std_logic_vector(31 downto 0);
    in_data_b : in std_logic_vector(31 downto 0);

    out_busy : out std_logic;
    out_data : out std_logic_vector(31 downto 0)
);
end observer;

architecture rtl of observer is

component altfp_mult
port 
(
    clock	: in std_logic;
    dataa	: in std_logic_vector(31 downto 0);
    datab	: in std_logic_vector(31 downto 0);
    result	: out std_logic_vector(31 downto 0)
);
end component;

type state_observer is (IDLE, LOAD_DATA, WAIT_MULT, LOAD_RESULT, COMPLETE);
signal current_state : state_observer;

signal wait_counter : std_logic_vector(5 downto 0);
signal reg_a : std_logic_vector(31 downto 0);
signal reg_b : std_logic_vector(31 downto 0);
signal reg_result : std_logic_vector(31 downto 0);

begin
    altfp_mult_inst : altfp_mult
    port map
    (
        clock => in_clk,
        dataa => reg_a,
        datab => reg_b,
        result => reg_result
    );

    process(in_clk)begin
        if(rising_edge(in_clk)) then
            if(in_reset = '1') then
                reg_a <= (others => '0');
                reg_b <= (others => '0');
                out_data <= (others => '0');
                wait_counter <= (others => '0');
                out_busy <= '0';
            else
                case current_state is
                    when IDLE => 
                        if(in_execute = '1') then
                            current_state <= LOAD_DATA;
                            out_busy <= '1';
                        end if;
                    when LOAD_DATA => 
                        reg_a <= in_data_a;
                        reg_b <= in_data_b;
                        wait_counter <= (others => '0');
                        current_state <= WAIT_MULT;
                    when WAIT_MULT => 
                        if(wait_counter = "100000") then
                            current_state <= LOAD_RESULT;
                        end if;
                        wait_counter <= wait_counter + "000001";
                    when LOAD_RESULT => 
                        out_data <= reg_result;
                        out_busy <= '0';
                        current_state <= COMPLETE;
                    when COMPLETE => 
                        if(in_execute = '0') then
                            current_state <= IDLE;
                        end if;
                end case;
            end if;
        end if; 
    end process;
end rtl;