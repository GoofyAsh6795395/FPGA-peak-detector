library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pack.all;

entity tb_dataConsume_signed_ext is
end entity;

architecture test of tb_dataConsume_signed_ext is

  component dataConsume is
    port (
      clk         : in  std_logic;
      reset       : in  std_logic; -- synchronous reset
      start       : in  std_logic; -- goes high to signal data transfer
      numWords_bcd: in  BCD_ARRAY_TYPE(2 downto 0);
      ctrlIn      : in  std_logic;
      ctrlOut     : out std_logic;
      data        : in  std_logic_vector(7 downto 0);
      dataReady   : out std_logic;
      byte        : out std_logic_vector(7 downto 0);
      seqDone     : out std_logic;
      maxIndex    : out BCD_ARRAY_TYPE(2 downto 0);
      dataResults : out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1) -- index 3 holds the peak
    );
  end component;

  -- Keep this TRUE to match the ordering used by the school's original TB:
  -- dataResults(6) is the earliest byte, dataResults(3) is the peak,
  -- dataResults(0) is the latest byte.
  -- Set to FALSE if your implementation follows 0..6 = oldest..newest.
  constant REVERSE_RESULTS_ORDER : boolean := true;

  constant CASE_COUNT  : integer := 10;
  constant MAX_WORDS   : integer := 8;
  constant GAP_CYCLES  : integer := 4;
  constant TIMEOUT_CYCLES_PER_CASE : integer := 200;

  type INT_ARRAY      is array (0 to CASE_COUNT-1) of integer;
  type TEST_SEQ_ARRAY is array (0 to CASE_COUNT-1) of CHAR_ARRAY_TYPE(0 to MAX_WORDS-1);

  -- Coverage goals:
  --   * n = 3,4,5 (<7) boundary cases
  --   * peak at first few / last few positions
  --   * a couple of longer cases
  -- All sequences avoid ties for the signed maximum.
  constant TEST_LEN : INT_ARRAY := (
    3,  -- peak at first element
    3,  -- peak at last element
    4,  -- peak at first element
    4,  -- peak at last element
    5,  -- peak in the middle
    5,  -- peak near the front
    5,  -- peak at the back
    7,  -- exact window width, peak at front edge
    8,  -- peak at very last element
    8   -- peak around the middle
  );

  constant TEST_SEQS : TEST_SEQ_ARRAY := (
    -- 0: n=3, peak at index 0
    (X"7F", X"00", X"01", X"00", X"00", X"00", X"00", X"00"),

    -- 1: n=3, peak at index 2
    (X"80", X"FF", X"40", X"00", X"00", X"00", X"00", X"00"),

    -- 2: n=4, peak at index 0
    (X"60", X"10", X"20", X"30", X"00", X"00", X"00", X"00"),

    -- 3: n=4, peak at index 3
    (X"80", X"F0", X"00", X"7E", X"00", X"00", X"00", X"00"),

    -- 4: n=5, peak at index 2
    (X"10", X"20", X"7F", X"30", X"40", X"00", X"00", X"00"),

    -- 5: n=5, peak at index 1
    (X"00", X"60", X"10", X"20", X"30", X"00", X"00", X"00"),

    -- 6: n=5, peak at index 4
    (X"80", X"F0", X"01", X"7E", X"7F", X"00", X"00", X"00"),

    -- 7: n=7, exact result width, peak at index 0
    (X"7E", X"01", X"02", X"03", X"04", X"05", X"06", X"00"),

    -- 8: n=8, peak at index 7
    (X"80", X"81", X"82", X"83", X"84", X"85", X"86", X"7F"),

    -- 9: n=8, peak at index 3
    (X"F0", X"10", X"20", X"7D", X"7C", X"00", X"FF", X"01")
  );

  function int_to_bcd3(val : integer) return BCD_ARRAY_TYPE is
    variable b : BCD_ARRAY_TYPE(2 downto 0);
    variable v : integer := val;
  begin
    assert (val >= 0 and val <= 999)
      report "int_to_bcd3 supports only 0..999, got " & integer'image(val)
      severity failure;
    b(2) := std_logic_vector(to_unsigned(v / 100, 4));
    v := v mod 100;
    b(1) := std_logic_vector(to_unsigned(v / 10, 4));
    b(0) := std_logic_vector(to_unsigned(v mod 10, 4));
    return b;
  end function;

  function slv8_to_sint(v : std_logic_vector(7 downto 0)) return integer is
  begin
    return to_integer(signed(v));
  end function;

  function calc_peak_index(seq : CHAR_ARRAY_TYPE(0 to MAX_WORDS-1); len : integer) return integer is
    variable best_idx : integer := 0;
    variable best_val : integer := -128;
    variable cur_val  : integer;
  begin
    for i in 0 to len-1 loop
      cur_val := slv8_to_sint(seq(i));
      if cur_val > best_val then
        best_val := cur_val;
        best_idx := i;
      end if;
    end loop;
    return best_idx;
  end function;

  function byte_to_hex(v : std_logic_vector(7 downto 0)) return string is
    constant HEX : string := "0123456789ABCDEF";
    variable s   : string(1 to 2);
    variable u   : unsigned(7 downto 0);
  begin
    u := unsigned(v);
    s(1) := HEX(to_integer(u(7 downto 4)) + 1);
    s(2) := HEX(to_integer(u(3 downto 0)) + 1);
    return s;
  end function;

  function result_slot_source_index(peak_idx : integer; slot : integer) return integer is
  begin
    if REVERSE_RESULTS_ORDER then
      return peak_idx + (3 - slot);
    else
      return peak_idx + (slot - 3);
    end if;
  end function;

  signal clk         : std_logic := '0';
  signal reset       : std_logic := '1';
  signal start       : std_logic := '0';
  signal ctrl_req    : std_logic; -- from dataConsume to mock generator
  signal ctrl_rsp    : std_logic := '0'; -- from mock generator to dataConsume
  signal readData    : std_logic_vector(7 downto 0) := X"DD";
  signal dataReady   : std_logic;
  signal curByte     : std_logic_vector(7 downto 0);
  signal seqDone     : std_logic;
  signal numWords    : BCD_ARRAY_TYPE(2 downto 0) := (others => (others => '0'));
  signal maxIndex    : BCD_ARRAY_TYPE(2 downto 0);
  signal dataResults : CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);

  signal tbCount        : integer := 0;
  signal active_case    : integer range 0 to CASE_COUNT-1 := 0;
  signal gen_index      : integer range 0 to MAX_WORDS := 0;
  signal prev_ctrl_req  : std_logic := '0';
  signal seen_data_cnt  : integer range 0 to MAX_WORDS := 0;
  signal prev_start     : std_logic := '0';
  signal done_all       : std_logic := '0';

begin
  clk <= not clk after 10 ns when done_all = '0' else clk;

  ---------------------------------------------------------------------------
  -- Simple mock data generator.
  -- Behaviour intentionally mirrors the provided dataGen:
  -- when dataConsume toggles ctrlOut, one cycle later the generator toggles
  -- ctrlIn and presents the next byte from the current test sequence.
  ---------------------------------------------------------------------------
  mock_generator : process(clk)
    variable req_toggled : std_logic;
  begin
    if rising_edge(clk) then
      if reset = '1' or start = '0' then
        prev_ctrl_req <= ctrl_req;
        ctrl_rsp      <= '0';
        readData      <= X"DD";
        gen_index     <= 0;
      else
        req_toggled := ctrl_req xor prev_ctrl_req;
        prev_ctrl_req <= ctrl_req;

        if req_toggled = '1' then
          ctrl_rsp <= not ctrl_rsp;
          if gen_index < TEST_LEN(active_case) then
            readData  <= TEST_SEQS(active_case)(gen_index);
            gen_index <= gen_index + 1;
          else
            -- Defensive: if DUT requests beyond numWords, keep returning a marker.
            readData <= X"DD";
          end if;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Cycle counter and streamed-byte checker.
  -- This also verifies that dataReady/byte emit exactly the requested sequence.
  ---------------------------------------------------------------------------
  monitor_stream : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tbCount       <= 0;
        seen_data_cnt <= 0;
        prev_start    <= '0';
      else
        tbCount <= tbCount + 1;
        prev_start <= start;

        if start = '1' and prev_start = '0' then
          seen_data_cnt <= 0;
        elsif start = '0' then
          seen_data_cnt <= 0;
        elsif dataReady = '1' then
          assert seen_data_cnt < TEST_LEN(active_case)
            report "Case " & integer'image(active_case) &
                   ": dataReady asserted more times than numWords"
            severity error;

          assert curByte = TEST_SEQS(active_case)(seen_data_cnt)
            report "Case " & integer'image(active_case) &
                   ": streamed byte mismatch at position " & integer'image(seen_data_cnt) &
                   ". Expected 0x" & byte_to_hex(TEST_SEQS(active_case)(seen_data_cnt)) &
                   ", got 0x" & byte_to_hex(curByte)
            severity error;

          seen_data_cnt <= seen_data_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Main stimulus/checker process.
  ---------------------------------------------------------------------------
  stimulus : process
    variable peak_idx : integer;
    variable src_idx  : integer;
    variable timeout_target : integer;
  begin
    -- synchronous reset for a couple of clocks
    reset <= '1';
    start <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';
    wait until rising_edge(clk);

    for tc in 0 to CASE_COUNT-1 loop
      active_case <= tc;
      numWords    <= int_to_bcd3(TEST_LEN(tc));
      start       <= '1';
      timeout_target := tbCount + TIMEOUT_CYCLES_PER_CASE;

      -- Wait for completion, but fail cleanly if DUT hangs.
      while seqDone /= '1' loop
        wait until rising_edge(clk);
        assert tbCount < timeout_target
          report "Timeout waiting for seqDone in case " & integer'image(tc)
          severity failure;
      end loop;
      wait for 0 ns; -- allow same-edge monitor counters / DUT outputs to update

      peak_idx := calc_peak_index(TEST_SEQS(tc), TEST_LEN(tc));

      -- dataReady should have emitted exactly numWords bytes by completion.
      assert seen_data_cnt = TEST_LEN(tc)
        report "Case " & integer'image(tc) &
               ": dataReady count mismatch. Expected " & integer'image(TEST_LEN(tc)) &
               ", got " & integer'image(seen_data_cnt)
        severity error;

      -- Check peak index.
      assert maxIndex = int_to_bcd3(peak_idx)
        report "Case " & integer'image(tc) &
               ": maxIndex mismatch. Expected " & integer'image(peak_idx) &
               ", got digits {" & integer'image(to_integer(unsigned(maxIndex(2)))) &
               integer'image(to_integer(unsigned(maxIndex(1)))) &
               integer'image(to_integer(unsigned(maxIndex(0)))) & "}"
        severity error;

      -- Check only the valid result slots. Slots outside the available data are don't-care.
      for slot in 0 to RESULT_BYTE_NUM-1 loop
        src_idx := result_slot_source_index(peak_idx, slot);
        if (src_idx >= 0) and (src_idx < TEST_LEN(tc)) then
          assert dataResults(slot) = TEST_SEQS(tc)(src_idx)
            report "Case " & integer'image(tc) &
                   ": dataResults(" & integer'image(slot) & ") mismatch. Expected source index " &
                   integer'image(src_idx) & " = 0x" & byte_to_hex(TEST_SEQS(tc)(src_idx)) &
                   ", got 0x" & byte_to_hex(dataResults(slot))
            severity error;
        end if;
      end loop;

      -- seqDone should be a one-cycle pulse.
      wait until rising_edge(clk);
      assert seqDone = '0'
        report "Case " & integer'image(tc) & ": seqDone should be a one-cycle pulse"
        severity error;

      -- Gap before the next case so the mock generator can reset cleanly.
      start <= '0';
      for k in 1 to GAP_CYCLES loop
        wait until rising_edge(clk);
      end loop;

      report "PASS case " & integer'image(tc) &
             " len=" & integer'image(TEST_LEN(tc)) &
             " peakIndex=" & integer'image(peak_idx)
             severity note;
    end loop;

    done_all <= '1';
    report "All extended signed dataConsume tests completed." severity note;
    wait;
  end process;

  dut : dataConsume
    port map (
      clk          => clk,
      reset        => reset,
      start        => start,
      numWords_bcd => numWords,
      ctrlIn       => ctrl_rsp,
      ctrlOut      => ctrl_req,
      data         => readData,
      dataReady    => dataReady,
      byte         => curByte,
      seqDone      => seqDone,
      maxIndex     => maxIndex,
      dataResults  => dataResults
    );

end architecture;
