AS = ca65
LD = ld65

MD5 := 71f1524e93c99ac48347d7390476eb1a

ute5.rom:	ute5.bin
	cat $^ $^ > $@
	@HASH="$$(md5 -q $@)"; \
	if [ "$$HASH" != "$(MD5)" ]; then echo "MD5 mismatch"; exit 1; fi

ute5.bin:	ute5.o
	$(LD) --target bbc -o $@ $^

ute5.o:		ute5.s
	$(AS) -l $(^:.s=.lst) $^

clean:
	$(RM) -f ute5.rom ute5.bin ute5.o ute5.lst
