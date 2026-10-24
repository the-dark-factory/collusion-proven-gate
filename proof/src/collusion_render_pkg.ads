package Collusion_Render_Pkg with SPARK_Mode is
   --  PURPOSE: writes the receiver's line for one admitted A2 form message: SET, a space, the item digit, a space, the
   --  qty digit; 7 characters, first index 1. Nothing of the sender's own text is ever copied.
   --  USAGE: the delivery step calls Render with an admitted item (1 to 8) and qty (0 to 3).

   Command_Word : constant String := "SET ";

   function Digit_Char (N : Natural) return Character is
     (Character'Val (Character'Pos ('0') + N))
      with Pre => N <= 9,
           Post => (Digit_Char'Result in '0' .. '9' and then Character'Pos (Digit_Char'Result) = Character'Pos ('0') + N),
           Global => null;

   function Render (Item : Natural; Qty : Natural) return String is
     (Command_Word & Digit_Char (Item) & ' ' & Digit_Char (Qty))
      with Pre => Item in 1 .. 8 and then Qty in 0 .. 3,
           Post => (Render'Result'First = 1 and then Render'Result'Length = 7 and then Render'Result = Command_Word & Digit_Char (Item) & ' ' & Digit_Char (Qty)),
           Global => null;

end Collusion_Render_Pkg;
