library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.all;

entity cmdProc is
	port(
		clk:		in std_logic;
		reset:        in std_logic;
		rxnow:        in std_logic;
		rxData:            in std_logic_vector (7 downto 0);
		txData:            out std_logic_vector (7 downto 0);
		rxdone:        out std_logic;
		ovErr:        in std_logic;
		framErr:    in std_logic;
		txnow:        out std_logic;
		txdone:        in std_logic;
		start: out std_logic;
		numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
		dataReady: in std_logic;
		byte: in std_logic_vector(7 downto 0);
		maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
		dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
		seqDone: in std_logic
	);
end entity;

architecture comb of cmdProc is
	component cmdProc_internal is
		rxData: in STD_LOGIC_VECTOR (7 downto 0);
		rxnow: in STD_LOGIC;
		done: out STD_LOGIC;
		ovErr: in STD_LOGIC;
		framErr: in STD_LOGIC;
		
		--To Data Processor
		start: out STD_LOGIC;
		numWords_bcd: out STD_LOGIC_VECTOR(11 downto 0);
		dataReady: in STD_LOGIC;
		byte: in STD_LOGIC_VECTOR (7 downto 0);
		maxIndex: in STD_LOGIC_VECTOR(11 downto 0);
		dataResults: in STD_LOGIC_VECTOR (55 downto 0);
		seqDone: in STD_LOGIC;

		--To Tx.
		txData: out STD_LOGIC_VECTOR(7 downto 0);
		txnow: out STD_LOGIC;
		txdone: in STD_LOGIC;
		
		clk: in STD_LOGIC;
		reset: in STD_LOGIC
	end component;
	
	signal numWords_packed: STD_LOGIC_VECTOR(11 downto 0);
	signal maxIndex_packed: STD_LOGIC_VECTOR(11 downto 0);
	signal dataResults_packed: STD_LOGIC_VECTOR(55 downto 0);

begin
	numWords_packed(3 downto 0) <= numWords_bcd(0);
	numWords_packed(7 downto 4) <= numWords_bcd(1);
	numWords_packed(11 downto 8) <= numWords_bcd(2);

	maxIndex_packed(3 downto 0) <= maxIndex(0);
	maxIndex_packed(7 downto 4) <= maxIndex(1);
	maxIndex_packed(11 downto 8) <= maxIndex(2);

	dataResults_packed(55 downto 48) <= dataResults(0);
	dataResults_packed(47 downto 40) <= dataResults(1);
	dataResults_packed(39 downto 32) <= dataResults(2);
	dataResults_packed(31 downto 24) <= dataResults(3);
	dataResults_packed(23 downto 16) <= dataResults(4);
	dataResults_packed(15 downto 8) <= dataResults(5);
	dataResults_packed(7 downto 0) <= dataResults(6);

	wrap_up: cmdProc_internal port map(
		rxData: rxData,
		rxnow => rxnow,
		done => done,
		ovErr => ovErr,
		framErr => framErr,

		start => start,
		numWords_bcd => numWords_packed,
		dataReady => dataReady,
		byte => byte,
		maxIndex => maxIndex_packed,
		dataResults => dataResults_packed,
		seqDone => seqDone,

		txData => txData,
		txnow => txNow,
		txdone => txdone,
		
		clk => clk,
		reset => reset
	);
end architecture;

--Log
--
--Firstly drafted on 09/03/2026
--
--This file aims to map my internal design with the submitted wrapped one, the latter one meets all expectations from university.