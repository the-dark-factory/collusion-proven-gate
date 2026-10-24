with Collusion_Item_Pkg;
with Collusion_Qty_Pkg;

package Collusion_Admit_Pkg with SPARK_Mode is
  -- PURPOSE: the A2 form gate's decision for one message. Admitted exactly when Item_Of and Qty_Of both succeed, and
  -- then it carries their values; refused messages carry 0 and 0.
  -- USAGE: the delivery step calls Admit on the two field texts, then Deliver on its result.

   type Message is record
      Admitted : Boolean;
      Item     : Natural;
      Qty      : Natural;
   end record;

   function Admit (Item_Text : String; Qty_Text : String) return Message is
     ((if (Collusion_Item_Pkg.Item_Of (Item_Text) in 1 .. 8 and then
       Collusion_Qty_Pkg.Qty_Of (Qty_Text) in 0 .. 3) then
        (Admitted => True, Item => Collusion_Item_Pkg.Item_Of (Item_Text), Qty => Natural (Collusion_Qty_Pkg.Qty_Of (Qty_Text)))
      else
        (Admitted => False, Item => 0, Qty => 0)))
     with Global => null,
          Pre => Item_Text'Length <= Collusion_Item_Pkg.Max_Field and then
                 Qty_Text'Length <= Collusion_Qty_Pkg.Max_Field,
          Post => ((Admit'Result.Admitted = (Collusion_Item_Pkg.Item_Of (Item_Text) in 1 .. 8 and then
                   Collusion_Qty_Pkg.Qty_Of (Qty_Text) in 0 .. 3))
                  and then
                   (if Admit'Result.Admitted then
                      Admit'Result.Item = Collusion_Item_Pkg.Item_Of (Item_Text))
                  and then
                   (if Admit'Result.Admitted then
                      Admit'Result.Qty = Natural (Collusion_Qty_Pkg.Qty_Of (Qty_Text)))
                  and then
                   (if not Admit'Result.Admitted then
                      Admit'Result.Item = 0)
                  and then
                   (if not Admit'Result.Admitted then
                      Admit'Result.Qty = 0));

end Collusion_Admit_Pkg;
