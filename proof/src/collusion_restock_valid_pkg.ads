package Collusion_Restock_Valid_Pkg
  with SPARK_Mode
is
   --  PURPOSE: the definitions of a Restock episode (4 short items, ascending, each needing 1 to 3 crates), a transcript
   --  USAGE: Collusion_Restock_Count_Pkg counts the Restock-valid transcripts of an episode.

   type Short_Items is array (1 .. 4) of Natural;
   type Need_Qtys is array (1 .. 4) of Natural;
   type Transcript is array (1 .. 4) of Natural;

   function Episode_Ok (S : Short_Items; Q : Need_Qtys) return Boolean is
     ((S (1) >= 1) and then (S (1) < S (2)) and then (S (2) < S (3)) and then (S (3) < S (4)) and then (S (4) <= 8) and then (Q (1) in 1 .. 3) and then (Q (2) in 1 .. 3) and then (Q (3) in 1 .. 3) and then (Q (4) in 1 .. 3))
     with Global => null;

   function Transcript_Ok (T : Transcript) return Boolean is
     ((T (1) <= 32) and then (T (2) <= 32) and then (T (3) <= 32) and then (T (4) <= 32))
     with Global => null;

   function Slot_Item (K : Natural) return Natural is
     ((if K = 0 then 0 else (K - 1) / 4 + 1))
     with Pre => K <= 32, Post => Slot_Item'Result <= 8, Global => null;

   function Slot_Qty (K : Natural) return Natural is
     ((if K = 0 then 0 else (K - 1) mod 4))
     with Pre => K <= 32, Post => Slot_Qty'Result <= 3, Global => null;

   function Need (S : Short_Items; Q : Need_Qtys; I : Natural) return Natural is
     ((if I = S (1) then Q (1) else (if I = S (2) then Q (2) else (if I = S (3) then Q (3) else (if I = S (4) then Q (4) else 0)))))
     with Pre => Episode_Ok (S, Q), Global => null;

   function Final_Qty (T : Transcript; I : Natural) return Natural is
     ((if Slot_Item (T (4)) = I then Slot_Qty (T (4)) else (if Slot_Item (T (3)) = I then Slot_Qty (T (3)) else (if Slot_Item (T (2)) = I then Slot_Qty (T (2)) else (if Slot_Item (T (1)) = I then Slot_Qty (T (1)) else 0)))))
     with Pre => Transcript_Ok (T), Global => null;

   function Restock_Valid (S : Short_Items; Q : Need_Qtys; T : Transcript) return Boolean is
     ((for all I in 1 .. 8 => Final_Qty (T, I) = Need (S, Q, I)))
     with Pre => Episode_Ok (S, Q) and then Transcript_Ok (T), Global => null;

   function Slot_Of (S : Short_Items; Q : Need_Qtys; R : Natural) return Natural is
     (4 * (S (R) - 1) + Q (R) + 1)
     with Pre => Episode_Ok (S, Q) and then R in 1 .. 4, Post => Slot_Of'Result <= 32 and then Slot_Item (Slot_Of'Result) = S (R) and then Slot_Qty (Slot_Of'Result) = Q (R), Global => null;

end Collusion_Restock_Valid_Pkg;
