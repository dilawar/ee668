entity MemBlock is 
	generic(has_decoder_fault, has_stuck_at_fault, has_psf, has_cf: boolean := false);
	port(addr, data_in: in bit_vector(7 downto 0);
			read_en, write_en: in bit;
			data_out: out bit_vector(7 downto 0));
end entity;

architecture Behave of MemBlock is
  	type MemArray is array (natural range <>) of bit_vector(7 downto 0);
    	-- procedure that models the update of the memory array,
	-- given an incoming word (data_in) and a row index (I)
	procedure Update_Mem(signal mem_array: inout MemArray;I: in integer; data_in: in bit_vector(7 downto 0)) is
		variable cword: bit_vector(7 downto 0);
		variable uI, dI: integer;
		variable aflag : boolean; -- set true when write is over.
	begin

		aflag := false;

		-- PSF
		if(I = 128 and has_psf) then 
 			uI := 129;
			dI := 127;	
			cword := mem_array(I);
			for J in 7 downto 0 loop
				-- here is the PSF
				if not ( mem_array(uI)(J) = '1' and mem_array(dI)(J) = '1') then
					mem_array(I)(J) <= data_in(J);
				end if; 
			end loop;
			aflag := true;
		end if;

		if(I=127 and has_cf) then
			if(mem_array(127)(0) = '0' and data_in(0) = '1') then
				mem_array(128)(0) <= '1';
			end if;
			mem_array(127) <= data_in;
			aflag := true;
		end if;

		if(I=129 and has_cf) then
			if(mem_array(129)(0) = '0' and data_in(0) = '1') then
				mem_array(128)(0) <= '0';
			end if;
			mem_array(129) <= data_in;
			aflag := true;
		end if;

		if(not aflag) then
			mem_array(I) <= data_in;
		end if;

		if(has_stuck_at_fault) then
			mem_array(129)(0) <= '1';
			mem_array(128)(0) <= '0';
		end if;

	end procedure;
	

  -- converts bit vector to a natural number
  function To_Natural(x: bit_vector) return natural is
	variable ret_var : natural := 0;
	alias lx: bit_vector(x'length downto 1) is x;
  begin
	for I in 1 to lx'length loop
		if(lx(I) = '1') then
			ret_var := ret_var + (2**(I-1));
		end if;
	end loop;
 	return(ret_var);	
  end To_Natural;

  -- output of the decoder
  signal decode_sig: bit_vector(255 downto 0);

  -- memory array
  signal mem_array: MemArray(0 to 255);

begin
  
   -- decoder process
   process(addr)
   begin
	decode_sig <= (others => '0');
	for I in 0 to 255 loop
		if(I=To_Natural(addr)) then
			decode_sig(I) <= '1';
			if(I=128 and has_decoder_fault) then
				decode_sig(I+1) <= '1';
			end if;
		end if;
	end loop;

   end process;

   -- memory array access process
   process(addr, data_in, read_en, write_en)
	variable data_out_var: bit_vector(7 downto 0);	
   begin
	data_out_var := (others => '0');
	for I in 0 to 255 loop
	    if decode_sig(I) = '1' then
		if(read_en = '1') then
			data_out_var := data_out_var or mem_array(I); -- Wired OR
		elsif write_en = '1' then
			Update_Mem(mem_array,I,data_in);
		end if;	
	    end if;
	end loop;
	data_out <= data_out_var;
   end process;

end Behave;
