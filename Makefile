# Replay every proof in this repository with GNATprove.
#   make prove     - run GNATprove on all cores, then check the summary
#   make check     - check an existing proof run without re-proving
#   make headline  - recompute the report's headline numbers from results/
#   make clean     - remove prover output

GNATPROVE ?= gnatprove
JOBS      ?= 4
OUT       := proof/obj/gnatprove/gnatprove.out

.PHONY: prove check headline clean

prove:
	cd proof && $(GNATPROVE) -P proof.gpr --level=2 --report=all -j$(JOBS) > obj-prove.log 2>&1 || { tail -20 obj-prove.log; exit 1; }
	@$(MAKE) --no-print-directory check

# Passes only when the Total row has nothing Justified and nothing Unproved.
check:
	@test -f $(OUT) || { echo "no proof output: run make prove"; exit 1; }
	@sed -n '/^SPARK Analysis results/,/^Total/p' $(OUT)
	@awk '/^Total/ { if ($$(NF-1) == "." && $$NF == ".") ok = 1 } END { exit !ok }' $(OUT) \
	  && echo "OK: all checks proved (0 justified, 0 unproved)" \
	  || { echo "FAIL: justified or unproved checks, see $(OUT)"; exit 1; }

# Prints each run's chart.tsv values side by side, then the cap arithmetic.
headline:
	@printf '%-8s %-34s %-16s %-11s %4s %7s %6s %6s %6s\n' part run colluder defence n above exact useful blocked
	@tail -n +2 results/RUNS_INDEX.tsv | while IFS="$$(printf '\t')" read run part coll def plan src; do \
	  awk -v p=$$part -v r=$$run -v c=$$coll -v d=$$def -F'\t' \
	    '{v[$$4]=$$5} END {printf "%-8s %-34s %-16s %-11s %4s %7.3f %6.3f %6.3f %6s\n", p, r, c, d, v["episodes_scored"], v["digits_above_chance"], v["exact_recovery"], v["usefulness"], v["a1_block_rate"]}' \
	    results/runs/$$part/$$run/chart.tsv; done
	@awk 'BEGIN { l = log(33)/log(2); printf "\nlog2 33 = %.3f bits per message; 4 messages = %.1f bits per episode (secret 24 bits)\n", l, 4*l; \
	  printf "33^4 = %d transcripts; 33^4 / 2^24 = %.2f%% best case for a whole secret\n", 33^4, 100*33^4/2^24; \
	  printf "log2 24 = %.3f bits (order freedom at full usefulness, DF 1456) = %.2f hex digits\n", log(24)/log(2), log(24)/log(2)/4 }'

clean:
	rm -rf proof/obj proof/obj-prove.log
