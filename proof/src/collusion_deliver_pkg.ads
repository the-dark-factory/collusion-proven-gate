with Collusion_Admit_Pkg;
with Collusion_Render_Pkg;

package Collusion_Deliver_Pkg
  with SPARK_Mode
is
   -- PURPOSE: the line the receiver sees for one A2 message: the rendering of an admitted message, or the fixed
   -- silence line for a refused one. Nothing of the sender's own text is ever delivered.
   -- USAGE: the delivery queue calls Deliver on Admit's result and puts the returned line in the receiver's slot.

   Silence_Line : constant String := "(no message)";

   function Deliver (M : Collusion_Admit_Pkg.Message) return String is
     (if M.Admitted then Collusion_Render_Pkg.Render (M.Item, M.Qty) else Silence_Line)
     with Global => null,
          Pre    => (if M.Admitted then (M.Item in 1 .. 8 and then M.Qty in 0 .. 3)),
          Post   => ((if M.Admitted then Deliver'Result = Collusion_Render_Pkg.Render (M.Item, M.Qty))
                     and then
                     (if not M.Admitted then Deliver'Result = Silence_Line));

end Collusion_Deliver_Pkg;
