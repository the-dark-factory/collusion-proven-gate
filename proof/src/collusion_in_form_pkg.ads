with Collusion_Item_Pkg;
with Collusion_Admit_Pkg;
with Collusion_Render_Pkg;
with Collusion_Deliver_Pkg;

package Collusion_In_Form_Pkg with SPARK_Mode is
  -- PURPOSE: the alphabet of deliverable A2 lines (silence, or a rendering of item 1..8 and qty 0..3) and the theorem
  -- that every delivered line is in it, including end to end from the raw field texts.
  -- USAGE: no caller needs to call the theorems; their proof is the evidence that nothing outside the form is
  -- ever delivered. Capacity (sprint work) counts the alphabet.

   function In_Alphabet (L : String) return Boolean is
     (L = Collusion_Deliver_Pkg.Silence_Line or else (for some I in 1 .. 8 => (for some Q in 0 .. 3 => L = Collusion_Render_Pkg.Render (I, Q))))
     with Global => null;

   function Delivered_In_Form (M : Collusion_Admit_Pkg.Message) return Boolean is
     (True)
     with Pre => (if M.Admitted then M.Item in 1 .. 8 and then M.Qty in 0 .. 3), Post => Delivered_In_Form'Result and then (Collusion_Deliver_Pkg.Deliver (M) = Collusion_Deliver_Pkg.Silence_Line or else (M.Item in 1 .. 8 and then M.Qty in 0 .. 3 and then Collusion_Deliver_Pkg.Deliver (M) = Collusion_Render_Pkg.Render (M.Item, M.Qty))) and then In_Alphabet (Collusion_Deliver_Pkg.Deliver (M)), Global => null;

   function Gate_In_Form (Item_Text : String; Qty_Text : String) return Boolean is
     (True)
     with Pre => Item_Text'Length <= Collusion_Item_Pkg.Max_Field and then Qty_Text'Length <= Collusion_Item_Pkg.Max_Field, Post => Gate_In_Form'Result and then Delivered_In_Form (Collusion_Admit_Pkg.Admit (Item_Text, Qty_Text)) and then In_Alphabet (Collusion_Deliver_Pkg.Deliver (Collusion_Admit_Pkg.Admit (Item_Text, Qty_Text))), Global => null;

end Collusion_In_Form_Pkg;
