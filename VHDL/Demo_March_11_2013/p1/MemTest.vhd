use std.textio.all;

entity MemTest is
end entity MemTest;

architecture Behave of MemTest is

    -- utility function: to increment an address
    function Increment(x: bit_vector) return bit_vector is
        alias lx: bit_vector(1 to x'length) is x;
        variable ret_var: bit_vector(1 to x'length);
        variable carry: bit;
    begin
        carry := '1';
        for I in x'length downto 1 loop
            ret_var(I) := lx(I) xor carry;
            carry := carry and lx(I);
        end loop;
        return(ret_var);
    end Increment;

    signal addr, addr2, data_in, data_out_df, data_out_saf, data_out_psf,data_out_cf : bit_vector(7 downto 0);	
    signal read_en, write_en: bit;
 
    component MemBlock 
        generic(has_decoder_fault, has_stuck_at_fault, has_psf, has_cf: boolean := false);
        port(addr, data_in: in bit_vector(7 downto 0);
            read_en, write_en: in bit;
            data_out: out bit_vector(7 downto 0));
    end component;

    constant zero8: bit_vector(7 downto 0) := (others => '0');



    -- utility procedures

    -- Write addr/data pair into memory using write_en
    procedure Write(signal addr: out bit_vector(7 downto 0);
        signal data: out bit_vector(7 downto 0);
        signal write_en: out bit;
        addr_var: in bit_vector(7 downto 0);
        data_var: in bit_vector(7 downto 0)) is
        begin
            addr <= addr_var;
            data <= data_var;

            wait for 1 ns;	
            write_en <= '1';

            wait for 1 ns;
            write_en <= '0';

            wait for 1 ns;
        end procedure;

        -- Read data from memory using read_en, addr.
        -- NOTE: data must be present on data_out signal on
        --       completion of procedure.
        procedure Read(signal addr: out bit_vector(7 downto 0);
            signal read_en: out bit; addr_var: bit_vector(7 downto 0)) is
            begin
                addr <= addr_var;
                wait for 1 ns;
                read_en <= '1';
                wait for 1 ns;
                read_en <= '0';
            end procedure;


        begin


            -- four memory blocks, each of which has one type of fault in it.


            -- this has a decoder-fault
            mb_df: MemBlock generic map(has_decoder_fault => true, has_stuck_at_fault => false, 
                has_psf => false, has_cf => false)
            port map(addr => addr, data_in => data_in, 
                data_out => data_out_df, read_en => read_en,
                write_en => write_en);

            -- this has stuck-at-faults in the array
            mb_saf: MemBlock generic map(has_decoder_fault => false, has_stuck_at_fault => true, 
                has_psf => false, has_cf => false)
            port map(addr => addr, data_in => data_in, 
                data_out => data_out_saf, read_en => read_en,
                write_en => write_en);

            -- this has a pattern-sensitive-fault in the array.  The neighbourhood for the
            -- fault is adjacent bits in the same column of the array.
            mb_psf: MemBlock generic map(has_decoder_fault => false, has_stuck_at_fault => false, 
                has_psf => true, has_cf => false)
            port map(addr => addr, data_in => data_in, 
                data_out => data_out_psf, read_en => read_en,
                write_en => write_en);

            -- this has some coupling faults in the array
            mb_cf: MemBlock generic map(has_decoder_fault => false, has_stuck_at_fault => false, 
                has_psf => false, has_cf => true)
            port map(addr => addr, data_in => data_in, 
                data_out => data_out_cf, read_en => read_en,
                write_en => write_en);

            -------------  test process ------------------------------------------------
            process
            variable curr_addr, next_addr, temp_n_addr, temp_nn_addr, temp_data, next_data: bit_vector(7 downto 0);
            variable err_flag : boolean := false;
            variable err_add, l_psf, l_df, l_saf, l_cf : line;
        begin

            -----------------------------------------------------------
            --        TEST SEQUENCE STARTS HERE 
            -----------------------------------------------------------
            read_en <= '0'; write_en <= '0';

            wait for 1 ns;
            curr_addr := (others => '0');

            while true loop

                -----------------------------------------------------
                --  This test will test the stuck at 1/0 faults.
                -----------------------------------------------------    

                temp_data := (others => '0');	
                next_data := (others => '1');

                -- test for s-a-1 faults.
                Write(addr, data_in, write_en, curr_addr, temp_data);
                Read(addr, read_en, curr_addr);

                -- assert yourself.
                assert (data_out_saf = temp_data) report
                "Data mismatch in memory with stuck-at-1-fault" severity ERROR;

                -- log this error.
                if data_out_saf /= temp_data then 
                    write(l_saf, String'("A: "));
                    write(l_saf, curr_addr);
                    write(l_saf, String'(" D: "));
                    write(l_saf, temp_data);
                    write(l_saf, String'(" saf1: "));
                    write(l_saf, data_out_saf);
                    writeline(output, l_saf);
                end if;

                Write(addr, data_in, write_en, curr_addr, next_data);
                Read(addr, read_en, curr_addr);

                -- assert yourself.
                assert (data_out_saf = next_data) report
                "Data mismatch in memory with stuck-at-0-fault" severity ERROR;

                -- log this error.
                if data_out_saf /= next_data then 
                    write(l_saf, String'("A: "));
                    write(l_saf, curr_addr);
                    write(l_saf, String'(" D: "));
                    write(l_saf, next_data);
                    write(l_saf, String'(" saf0: "));
                    write(l_saf, data_out_saf);
                    writeline(output, l_saf);
                -- NOTE : Must reset this cell while doing cf testing. Else
                --    problem might occur in first and last cells. 
                end if;
               --            while true loop
                temp_data := (others => '0');
                next_data := (others => '1');

                temp_n_addr := Increment(curr_addr);
                -- reset the cell we are going to test.
                Write(addr, data_in, write_en, temp_n_addr, temp_data);

                -- give an up-transition at left location and read data. If there isa
                -- coupling faults. This should change the value of cell from 0 to 1

                Write(addr, data_in, write_en, curr_addr, temp_data);
                Write(addr, data_in, write_en, curr_addr, next_data);
                Read(addr, read_en, temp_n_addr); -- read the next address. 

                -- Assert yourserf if you got it right.
                assert (data_out_cf = temp_data) report
                "Data mismatch in memory with coupling l_at_0_u faults" severity ERROR; 

                -- log this error.
                if data_out_cf /= temp_data then
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 0lu "));
                    write(l_cf, data_out_cf);
                    writeline(output, l_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, temp_data);
                end if;

                -- give a low transition at left location and read data. If there is a
                -- coupling fault then this should change the value of cell from 0 to 1 
                Write(addr, data_in, write_en, curr_addr, temp_data); 
                Read(addr, read_en, temp_n_addr); -- read the next address.

                -- Assert yourserf if you got it right.
                assert (data_out_cf = temp_data) report
                "Data mismatch in memory with coupling l_at_0_d faults" severity ERROR; 

                -- log this error.
                if data_out_cf /= temp_data then 
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 0ld "));
                    write(l_cf, data_out_cf);
                    writeline(output, l_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, temp_data);
                end if;


                -- REPEAT IT FROM RIGHT SIDE
                temp_nn_addr := Increment(temp_n_addr);
                -- give an up-transition at right location and read data. If there isa
                -- coupling faults. This should change the value of cell from 0 to 1
                Write(addr, data_in, write_en, temp_nn_addr, next_data);
                Read(addr, read_en, temp_n_addr); -- read the next address. 
                assert (data_out_cf = temp_data) report
                "Data mismatch in memory with coupling r_at_0_u faults" severity ERROR; 
                -- log this error.
                if data_out_cf /= temp_data then 
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 0ru "));
                    write(l_cf, data_out_cf);
                    writeline(output, l_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, temp_data);
                end if;

                -- give a low transition at right location and read data. If there is a
                -- coupling fault then this should change the value of cell from 0 to 1 
                Write(addr, data_in, write_en, temp_nn_addr, temp_data); 
                Read(addr, read_en, temp_n_addr); -- read the next address. 
                -- Assert yourserf if you are right.
                assert (data_out_cf = temp_data) report
                "Data mismatch in memory with coupling r_at_0_d faults" severity ERROR;   
                -- log this error.
                if data_out_cf /= temp_data then 
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 0rd "));
                    write(l_cf, data_out_cf);
                    writeline(output, l_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, temp_data);
                end if; 

                temp_data := "00000000";
                next_data := "11111111";
                temp_n_addr := Increment(curr_addr);
                temp_nn_addr := Increment(temp_n_addr);

                -- Following line will write 1 in next adress.
                Write(addr, data_in, write_en, temp_n_addr, next_data);

                -- Give an up transition at left location and read for fault.
                Write(addr, data_in, write_en, curr_addr, next_data);
                Read(addr, read_en, temp_n_addr);
                -- assert it.
                assert (data_out_cf = next_data) report
                "Data mismatch in memory with coupling l_at_1_u faults" severity ERROR;

                -- log this error.
                if data_out_cf /= next_data then
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 1lu "));
                    write(l_cf, data_out_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, next_data);
                end if;

                -- Give a down transition at left location. And read for faults.
                Write(addr, data_in, write_en, curr_addr, temp_data);
                Read(addr, read_en, temp_n_addr); 

                -- Assert yourserf if you are right.
                assert (data_out_cf = next_data) report
                "Data mismatch in memory with coupling l_at_1_d faults" severity ERROR;

                -- log this error.
                if data_out_cf /= next_data then
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 1lu "));
                    write(l_cf, data_out_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, next_data);
                end if;

                -- Give an up transition at right location.
                Write(addr, data_in, write_en, temp_nn_addr, next_data);
                Read(addr, read_en, temp_n_addr); 

                -- Assert yourserf if you are right.
                assert (data_out_cf = next_data) report
                "Data mismatch in memory with coupling r_at_1_u faults" severity ERROR;

                -- log this error.
                if data_out_cf /= next_data then
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 1ru "));
                    write(l_cf, data_out_cf);
                    writeline(output, l_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, next_data);
                end if;

                -- Give a down transition at right location.
                Write(addr, data_in, write_en, temp_nn_addr, temp_data);
                Read(addr, read_en, temp_n_addr); 

                -- Assert yourserf if you are right.
                assert (data_out_cf = next_data) report
                "Data mismatch in memory with coupling r_at_1_d faults" severity ERROR;

                -- log this error.
                if data_out_cf /= next_data then
                    write(l_cf, String'("A: "));
                    write(l_cf, temp_n_addr);
                    write(l_cf, String'(" 1rd "));
                    write(l_cf, data_out_cf);
                    -- reset the memory cell.
                    Write(addr, data_in, write_en, temp_n_addr, next_data);
                end if;

                ----------------------------------------------
                -- Test pattern for Pattern Sensitive Faults. 
                ----------------------------------------------
                temp_data := (others => '0');
                next_data := (others => '1');

                temp_n_addr := Increment(curr_addr);
                temp_nn_addr := Increment(temp_n_addr);

                -- reset the cell we are going to test.
                Write(addr, data_in, write_en, temp_n_addr, temp_data);

                ------- case 1 
                -- Write 1 in left and 0 in right and check for PSF.
                Write(addr, data_in, write_en, curr_addr, next_data);
                Write(addr, data_in, write_en, temp_nn_addr, temp_data);
                -- Now write 1 in the cell and read the same value.
                Write(addr, data_in, write_en, temp_n_addr, next_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = next_data) report
                "Data can not be written due to l1r0 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= next_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l1r0 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -- write 0 in the cell and check for the PSF. 
                Write(addr, data_in, write_en, temp_n_addr, temp_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = temp_data) report
                "Data can not be written due to l1r0 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= temp_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l1r0 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -------- case 2
                -- Write 1 in left and 1 in right and check for PSF
                Write(addr, data_in, write_en, curr_addr, next_data);
                Write(addr, data_in, write_en, temp_nn_addr, next_data);
                -- Now write 1 in the cell and read the same value.
                Write(addr, data_in, write_en, temp_n_addr, next_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = next_data) report
                "Data can not be written due to l1r1 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= next_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l1r1 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -- write 0 in the cell and check for the PSF. 
                Write(addr, data_in, write_en, temp_n_addr, temp_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = temp_data) report
                "Data can not be written due to l1r1 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= temp_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l1r1 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;
                -------- case 3
                -- Write 0 in left and 1 in right and check for PSF
                Write(addr, data_in, write_en, curr_addr, temp_data);
                Write(addr, data_in, write_en, temp_nn_addr, next_data);
                -- Now write 1 in the cell and read the same value.
                Write(addr, data_in, write_en, temp_n_addr, next_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = next_data) report
                "Data can not be written due to l0r1 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= next_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l1r1 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -- write 0 in the cell and check for the PSF. 
                Write(addr, data_in, write_en, temp_n_addr, temp_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = temp_data) report
                "Data can not be written due to l0r1 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= temp_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l0r1 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -------- case 4
                -- Write 0 in left and 0 in right and check for PSF
                Write(addr, data_in, write_en, curr_addr, temp_data);
                Write(addr, data_in, write_en, temp_nn_addr, temp_data);
                -- Now write 1 in the cell and read the same value.
                Write(addr, data_in, write_en, temp_n_addr, next_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = next_data) report
                "Data can not be written due to l0r0 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= next_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l0r0 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -- write 0 in the cell and check for the PSF. 
                Write(addr, data_in, write_en, temp_n_addr, temp_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_psf = temp_data) report
                "Data can not be written due to l0r0 PSF." severity ERROR;
                -- log this error.
                if data_out_psf /= temp_data then
                    write(l_psf, String'("A "));
                    write(l_psf, temp_n_addr);
                    write(l_psf, String'(" l0r0 "));
                    write(l_psf, data_out_psf);
                    writeline(output, l_psf);
                end if;

                -------------------------------------
                -- Decoder fault.
                ------------------------------------
                -- NOTE : Ideally one should write 0 to a cell and write 1 to
                -- all the cells which are 1 hamming distance away to cover all
                -- the stuck-at-fautls in decoder. Here, we check immediate left
                -- and right cell for fautls.
                Write(addr, data_in, write_en, temp_n_addr, next_data);
                -- write all 1 in left and right cell.
                Write(addr, data_in, write_en, curr_addr, temp_data);
                Write(addr, data_in, write_en, temp_nn_addr, temp_data);
                Read(addr, read_en, temp_n_addr);
                assert (data_out_df = next_data) report
                "Decoder fault - value written into some adjacent cell." severity ERROR;

                -- log this error
                if data_out_df /= next_data then
                    write(l_df, String'("To "));
                    write(l_df, temp_n_addr);
                    write(l_df, String'(" From "));
                    write(l_df, curr_addr);
                    write(l_df, String'(" DF "));
                    write(l_df, data_out_df);
                    writeline(output, l_df);
                -- reset cells for next test.
                    Write(addr, data_in, write_en, temp_n_addr, temp_data);
                    Write(addr, data_in, write_en, temp_nn_addr, temp_data);
                    -- to make sure this does not interfere with other test.
                    Write(addr, data_in, write_en, curr_addr, temp_data);

                end if;

                next_addr := temp_n_addr;
                -- if all addresses have been reached, exit
                if(next_addr = "11111111") then
                    exit;
                end if;
                curr_addr := next_addr; 

            end loop;

            assert false report "Test completed." severity NOTE;
            wait;

        end process;

    end Behave;
