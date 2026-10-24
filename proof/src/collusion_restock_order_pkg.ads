package Collusion_Restock_Order_Pkg
  with SPARK_Mode
is
   --  PURPOSE: numbers the 24 orders of the 4 short items. Code P in 0 .. 23 decodes to four different ranks; the first
   --  three ranks encode back to P. The round-trip theorems prove there are exactly 4 * 3 * 2 * 1 orders.
   --  USAGE: Collusion_Restock_Count_Pkg uses the code as the index of a Restock-valid transcript.

   Order_Count : constant := 4 * 3 * 2 * 1;

   function Skip (V, A : Natural) return Natural is
     ((if V >= A then V + 1 else V))
     with Pre => V <= 8,
          Global => null;

   function First_Rank (P : Natural) return Natural is
     (P / 6 + 1)
     with Pre => P < Order_Count,
          Global => null;

   function Second_Rank (P : Natural) return Natural is
     (Skip ((P mod 6) / 2 + 1, First_Rank (P)))
     with Pre => P < Order_Count,
          Global => null;

   function Third_Rank (P : Natural) return Natural is
     (Skip (Skip (P mod 2 + 1, Integer'Min (First_Rank (P), Second_Rank (P))), Integer'Max (First_Rank (P), Second_Rank (P))))
     with Pre => P < Order_Count,
          Global => null;

   function Fourth_Rank (P : Natural) return Natural is
     (10 - First_Rank (P) - Second_Rank (P) - Third_Rank (P))
     with Pre => P < Order_Count,
          Global => null;

   function Ranks_Ok (P : Natural) return Boolean is
     (True)
     with Pre => P < Order_Count,
          Post => Ranks_Ok'Result and then First_Rank (P) in 1 .. 4 and then Second_Rank (P) in 1 .. 4 and then Third_Rank (P) in 1 .. 4 and then Fourth_Rank (P) in 1 .. 4 and then First_Rank (P) /= Second_Rank (P) and then First_Rank (P) /= Third_Rank (P) and then First_Rank (P) /= Fourth_Rank (P) and then Second_Rank (P) /= Third_Rank (P) and then Second_Rank (P) /= Fourth_Rank (P) and then Third_Rank (P) /= Fourth_Rank (P),
          Global => null;

   function Code_From_Ranks (A, B, C : Natural) return Natural is
     (6 * (A - 1) + 2 * (B - 1 - (if A < B then 1 else 0)) + (C - 1 - (if A < C then 1 else 0) - (if B < C then 1 else 0)))
     with Pre => A in 1 .. 4 and then B in 1 .. 4 and then C in 1 .. 4 and then A /= B and then A /= C and then B /= C,
          Post => Code_From_Ranks'Result < Order_Count,
          Global => null;

   function Code_Decodes (A, B, C : Natural) return Boolean is
     (True)
     with Pre => A in 1 .. 4 and then B in 1 .. 4 and then C in 1 .. 4 and then A /= B and then A /= C and then B /= C,
          Post => Code_Decodes'Result and then First_Rank (Code_From_Ranks (A, B, C)) = A and then Second_Rank (Code_From_Ranks (A, B, C)) = B and then Third_Rank (Code_From_Ranks (A, B, C)) = C,
          Global => null;

   function Ranks_Encode (P : Natural) return Boolean is
     (True)
     with Pre => P < Order_Count,
          Post => Ranks_Encode'Result and then Ranks_Ok (P) and then Code_From_Ranks (First_Rank (P), Second_Rank (P), Third_Rank (P)) = P,
          Global => null;

end Collusion_Restock_Order_Pkg;
