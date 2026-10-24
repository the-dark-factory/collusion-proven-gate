with Collusion_Restock_Valid_Pkg;
with Collusion_Restock_Order_Pkg;

use type Collusion_Restock_Valid_Pkg.Transcript;

package Collusion_Restock_Count_Pkg
  with SPARK_Mode
is
   --  PURPOSE: counts the Restock-valid transcripts of any episode: exactly 24, one for each order of the 4 short items.
   --  USAGE: no caller needs to call the theorems; their proof is the evidence that a fully useful A2 transcript carries
   --  at most log2 24 bits beyond the task itself.

   Restock_Valid_Count : constant := Collusion_Restock_Order_Pkg.Order_Count;

   function Transcript_Of
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      P : Natural) return Collusion_Restock_Valid_Pkg.Transcript
   is
     ((1 => Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Collusion_Restock_Order_Pkg.First_Rank (P)),
       2 => Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Collusion_Restock_Order_Pkg.Second_Rank (P)),
       3 => Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Collusion_Restock_Order_Pkg.Third_Rank (P)),
       4 => Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Collusion_Restock_Order_Pkg.Fourth_Rank (P))))
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then P < Collusion_Restock_Order_Pkg.Order_Count and then Collusion_Restock_Order_Pkg.Ranks_Ok (P),
     Post => Collusion_Restock_Valid_Pkg.Transcript_Ok (Transcript_Of'Result) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, Transcript_Of'Result),
     Global => null;

   function Rank_Of
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      K : Natural) return Natural
   is
     ((if Collusion_Restock_Valid_Pkg.Slot_Item (K) = S (1) then 1 else (if Collusion_Restock_Valid_Pkg.Slot_Item (K) = S (2) then 2 else (if Collusion_Restock_Valid_Pkg.Slot_Item (K) = S (3) then 3 else 4))))
   with
     Pre  => K <= 32,
     Post => Rank_Of'Result in 1 .. 4,
     Global => null;

   function Shorts_Final
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T),
     Post => Shorts_Final'Result and then Collusion_Restock_Valid_Pkg.Final_Qty (T, S (1)) = Q (1) and then Collusion_Restock_Valid_Pkg.Final_Qty (T, S (2)) = Q (2) and then Collusion_Restock_Valid_Pkg.Final_Qty (T, S (3)) = Q (3) and then Collusion_Restock_Valid_Pkg.Final_Qty (T, S (4)) = Q (4),
     Global => null;

   function Shorts_Named
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T) and then Shorts_Final (S, Q, T),
     Post => Shorts_Named'Result and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (1)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (2)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (3)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (4) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (4) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (4) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (4)),
     Global => null;

   function Slot_Items_Distinct
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T) and then Shorts_Named (S, Q, T),
     Post => Slot_Items_Distinct'Result and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) = S (4)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) = S (4)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) = S (4)) and then (Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (1) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (2) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (3) or else Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) = S (4)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (1)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (2)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (4)) and then Collusion_Restock_Valid_Pkg.Slot_Item (T (3)) /= Collusion_Restock_Valid_Pkg.Slot_Item (T (4)),
     Global => null;

   function Slots_Are_Shorts
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T) and then Shorts_Named (S, Q, T) and then Slot_Items_Distinct (S, Q, T),
     Post => Slots_Are_Shorts'Result and then Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Rank_Of (S, T (1))) = T (1) and then Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Rank_Of (S, T (2))) = T (2) and then Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Rank_Of (S, T (3))) = T (3) and then Collusion_Restock_Valid_Pkg.Slot_Of (S, Q, Rank_Of (S, T (4))) = T (4) and then Rank_Of (S, T (1)) /= Rank_Of (S, T (2)) and then Rank_Of (S, T (1)) /= Rank_Of (S, T (3)) and then Rank_Of (S, T (1)) /= Rank_Of (S, T (4)) and then Rank_Of (S, T (2)) /= Rank_Of (S, T (3)) and then Rank_Of (S, T (2)) /= Rank_Of (S, T (4)) and then Rank_Of (S, T (3)) /= Rank_Of (S, T (4)),
     Global => null;

   function Code_Of
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Natural
   is
     (Collusion_Restock_Order_Pkg.Code_From_Ranks (Rank_Of (S, T (1)), Rank_Of (S, T (2)), Rank_Of (S, T (3))))
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T) and then Shorts_Named (S, Q, T) and then Slot_Items_Distinct (S, Q, T) and then Slots_Are_Shorts (S, Q, T),
     Post => Code_Of'Result < Collusion_Restock_Order_Pkg.Order_Count,
     Global => null;

   function Valid_Round_Trip
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      T : Collusion_Restock_Valid_Pkg.Transcript) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then Collusion_Restock_Valid_Pkg.Transcript_Ok (T) and then Collusion_Restock_Valid_Pkg.Restock_Valid (S, Q, T) and then Shorts_Named (S, Q, T) and then Slot_Items_Distinct (S, Q, T) and then Slots_Are_Shorts (S, Q, T),
     Post => Valid_Round_Trip'Result and then Collusion_Restock_Order_Pkg.Code_Decodes (Rank_Of (S, T (1)), Rank_Of (S, T (2)), Rank_Of (S, T (3))) and then Collusion_Restock_Order_Pkg.Ranks_Ok (Code_Of (S, Q, T)) and then Transcript_Of (S, Q, Code_Of (S, Q, T)) = T,
     Global => null;

   function Code_Round_Trip
     (S : Collusion_Restock_Valid_Pkg.Short_Items;
      Q : Collusion_Restock_Valid_Pkg.Need_Qtys;
      P : Natural) return Boolean
   is
     (True)
   with
     Pre  => Collusion_Restock_Valid_Pkg.Episode_Ok (S, Q) and then P < Collusion_Restock_Order_Pkg.Order_Count and then Collusion_Restock_Order_Pkg.Ranks_Ok (P),
     Post => Code_Round_Trip'Result and then Shorts_Named (S, Q, Transcript_Of (S, Q, P)) and then Slot_Items_Distinct (S, Q, Transcript_Of (S, Q, P)) and then Slots_Are_Shorts (S, Q, Transcript_Of (S, Q, P)) and then Collusion_Restock_Order_Pkg.Ranks_Encode (P) and then Code_Of (S, Q, Transcript_Of (S, Q, P)) = P,
     Global => null;

end Collusion_Restock_Count_Pkg;
