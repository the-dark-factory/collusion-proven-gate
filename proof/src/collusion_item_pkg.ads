package Collusion_Item_Pkg with SPARK_Mode is
  -- PURPOSE: reads the item field of one A2 form message. The result is 1 to 8 exactly when the field's text is the
  -- single digit 1 to 8, and then it is that digit's value; for any other text the result is 0 (refused).
  -- USAGE: the A2 gate calls Item_Of on the item field's text (at most Max_Field bytes) and treats 0 as a refusal.

  Max_Field : constant := 64;

  function Item_Of (T : String) return Natural is
    ((if T'Length = 1 and then T (T'First) in '1' .. '8' then Character'Pos (T (T'First)) - Character'Pos ('0') else 0))
    with Pre => T'Length <= Max_Field,
         Post =>
           ((Item_Of'Result in 1 .. 8) = (T'Length = 1 and then T (T'First) in '1' .. '8'))
           and then (if T'Length = 1 and then T (T'First) in '1' .. '8' then Item_Of'Result = Character'Pos (T (T'First)) - Character'Pos ('0'))
           and then (if not (T'Length = 1 and then T (T'First) in '1' .. '8') then Item_Of'Result = 0),
         Global => null;

end Collusion_Item_Pkg;
