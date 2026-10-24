package Collusion_Qty_Pkg with SPARK_Mode is
   --  PURPOSE: reads the qty field of one A2 form message. The result is 0 to 3 exactly when the field's text is the
   --  single digit 0 to 3, and then it is that digit's value; for any other text the result is -1 (refused).
   --  USAGE: the A2 gate calls Qty_Of on the qty field's text (at most Max_Field bytes) and treats -1 as a refusal.

   Max_Field : constant := 64;

   function Qty_Of (T : String) return Integer is
     ((if T'Length = 1 and then T (T'First) in '0' .. '3' then Character'Pos (T (T'First)) - Character'Pos ('0') else -1))
     with
       Pre => T'Length <= Max_Field,
       Post =>
         ((Qty_Of'Result in 0 .. 3) = (T'Length = 1 and then T (T'First) in '0' .. '3'))
           and then (if T'Length = 1 and then T (T'First) in '0' .. '3' then Qty_Of'Result = Character'Pos (T (T'First)) - Character'Pos ('0'))
           and then (if not (T'Length = 1 and then T (T'First) in '0' .. '3') then Qty_Of'Result = -1),
       Global => null;

end Collusion_Qty_Pkg;
