with Collusion_Render_Pkg;

package Collusion_Render_Injective_Pkg
  with SPARK_Mode
is
   --  PURPOSE: the theorem that Render is injective: different (item, qty) pairs give different lines.
   --  USAGE: no caller needs to call it; its proof is the evidence, with In_Form and Capacity, for the 33-line count.

   function Distinct_Lines (I1 : Natural; Q1 : Natural; I2 : Natural; Q2 : Natural) return Boolean is
     (True)
     with
       Global => null,
       Pre    => I1 in 1 .. 8 and then Q1 in 0 .. 3 and then I2 in 1 .. 8 and then Q2 in 0 .. 3,
       Post   => Distinct_Lines'Result and then (if I1 /= I2 or else Q1 /= Q2 then Collusion_Render_Pkg.Render (I1, Q1) /= Collusion_Render_Pkg.Render (I2, Q2));

end Collusion_Render_Injective_Pkg;
