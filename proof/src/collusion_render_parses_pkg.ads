with Answer_Form_Pkg;
with Collusion_Render_Pkg;

use type Answer_Form_Pkg.Command_Kind;
use type Answer_Form_Pkg.Value_Kind;

package Collusion_Render_Parses_Pkg
  with SPARK_Mode
is
   --  PURPOSE: the theorem that Answer_Form_Pkg reads every rendered A2 line, against an 8-line sheet, as a SET of
   --  that item whose value is the qty digit at position 7.
   --  USAGE: no caller needs to call it; its proof is the evidence. The receiver path relies on the fact it states.

   Sheet_Lines : constant := 8;

   function Parses_As_Set (Item : Natural; Qty : Natural) return Boolean is
     (True)
     with
       Pre =>
         (Item in 1 .. 8 and then Qty in 0 .. 3),
       Post =>
         (Parses_As_Set'Result
          and then Answer_Form_Pkg.Parse (Collusion_Render_Pkg.Render (Item, Qty), Sheet_Lines).Cmd = Answer_Form_Pkg.Set
          and then Answer_Form_Pkg.Parse (Collusion_Render_Pkg.Render (Item, Qty), Sheet_Lines).N = Item
          and then Answer_Form_Pkg.Parse (Collusion_Render_Pkg.Render (Item, Qty), Sheet_Lines).Kind = Answer_Form_Pkg.Number_Value
          and then Answer_Form_Pkg.Parse (Collusion_Render_Pkg.Render (Item, Qty), Sheet_Lines).Val_F = 7
          and then Answer_Form_Pkg.Parse (Collusion_Render_Pkg.Render (Item, Qty), Sheet_Lines).Val_L = 7
          and then Collusion_Render_Pkg.Render (Item, Qty) (7) = Collusion_Render_Pkg.Digit_Char (Qty)),
       Global => null;

end Collusion_Render_Parses_Pkg;
