with Collusion_Render_Pkg;
with Collusion_Deliver_Pkg;
with Collusion_In_Form_Pkg;

package Collusion_Capacity_Pkg with SPARK_Mode is
  --  PURPOSE: counts the alphabet of deliverable A2 lines. Index 0 is the silence line; index 4 * (item - 1) + qty + 1
  --  is the rendering of that item and qty. The two round-trip theorems prove the alphabet has exactly 33 lines.
  --  USAGE: no caller needs to call the theorems; with In_Form, their proof is the evidence that each delivered line
  --  carries at most log2 33 bits.

   Alphabet_Size : constant := 8 * 4 + 1;

   function Index_Of (L : String) return Natural is
     ((if L = Collusion_Deliver_Pkg.Silence_Line then 0 else 4 * (Character'Pos (L (L'First + 4)) - Character'Pos (Collusion_Render_Pkg.Digit_Char (0)) - 1) + (Character'Pos (L (L'First + 6)) - Character'Pos (Collusion_Render_Pkg.Digit_Char (0))) + 1))
     with Pre => Collusion_In_Form_Pkg.In_Alphabet (L), Post => Index_Of'Result < Alphabet_Size, Global => null;

   function Line_Of (K : Natural) return String is
     ((if K = 0 then Collusion_Deliver_Pkg.Silence_Line else Collusion_Render_Pkg.Render ((K - 1) / 4 + 1, (K - 1) mod 4)))
     with Pre => K < Alphabet_Size, Post => Collusion_In_Form_Pkg.In_Alphabet (Line_Of'Result), Global => null;

   function Line_Round_Trip (L : String) return Boolean is
     (True)
     with Pre => Collusion_In_Form_Pkg.In_Alphabet (L), Post => Line_Round_Trip'Result and then Line_Of (Index_Of (L)) = L, Global => null;

   function Index_Round_Trip (K : Natural) return Boolean is
     (True)
     with Pre => K < Alphabet_Size, Post => Index_Round_Trip'Result and then Index_Of (Line_Of (K)) = K, Global => null;

end Collusion_Capacity_Pkg;
