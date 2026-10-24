package Answer_Form_Pkg with SPARK_Mode, Pure is
   --  The JSON-blind model: the OUT view. The model never
   --  writes JSON; its reply ends with ONE command line from a closed grammar:
   --    PICK n | SET n <value> | REMOVE n | APPEND n <value> | ADD n <key> <value>
   --  Parse reads that line and gives exactly one command or one named
   --  refusal (no_command, unknown_command, line_out_of_range, bad_value); it
   --  is total over any line. A <value> is bare: text, a JSON number, true,
   --  false or null; text that would read as a number or keyword is written
   --  with the prefix text: (text:12). kind_mismatch is decided where the
   --  document is seen (Json_Patch_Pkg), never here.

   Max_Line  : constant := 1_024;
   Max_Lines : constant := 256;
   Max_Key   : constant := 64;
   Max_Num   : constant := 64;

   type Command_Kind is (Pick, Set, Remove, Append, Add, Refused);
   type Refusal is (None, No_Command, Unknown_Command, Line_Out_Of_Range, Bad_Value, Kind_Mismatch);
   type Value_Kind is (No_Value, Text_Value, Number_Value, True_Value, False_Value, Null_Value);

   type Form is record
      Cmd   : Command_Kind;
      Why   : Refusal;
      N     : Natural;
      Key_F : Natural;
      Key_L : Natural;
      Val_F : Natural;
      Val_L : Natural;
      Kind  : Value_Kind;
   end record;

   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');
   function Is_Upper (C : Character) return Boolean is (C in 'A' .. 'Z');
   function Is_Blank (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.CR);
   function Is_Key_Char (C : Character) return Boolean is
     (C in 'a' .. 'z' or else C in 'A' .. 'Z' or else C in '0' .. '9' or else C = '_' or else C = '-');

   --  a member name the view can show and a path can carry: 1 .. 64 of a-z A-Z 0-9 _ -
   function Is_Plain_Key (S : String) return Boolean is
     (S'Length in 1 .. Max_Key and then (for all I in S'Range => Is_Key_Char (S (I))));

   --  the last index of the run of digits that starts at I (I - 1 when there is none)
   function Digits_To (S : String; I : Positive) return Natural is
     (if I > S'Last then I - 1
      elsif Is_Digit (S (I)) then Digits_To (S, I + 1)
      else I - 1)
     with Pre  => S'Last < Integer'Last and then I >= S'First and then I - 1 <= S'Last,
          Post => Digits_To'Result in I - 1 .. S'Last
                  and then (for all K in I .. Digits_To'Result => Is_Digit (S (K)))
                  and then (if Digits_To'Result < S'Last then not Is_Digit (S (Digits_To'Result + 1))),
          Subprogram_Variant => (Decreases => S'Last - I + 1);

   --  the last index of the run of upper-case letters that starts at I (I - 1 when none)
   function Upper_To (S : String; I : Positive) return Natural is
     (if I > S'Last then I - 1
      elsif Is_Upper (S (I)) then Upper_To (S, I + 1)
      else I - 1)
     with Pre  => S'Last < Integer'Last and then I >= S'First and then I - 1 <= S'Last,
          Post => Upper_To'Result in I - 1 .. S'Last
                  and then (for all K in I .. Upper_To'Result => Is_Upper (S (K))),
          Subprogram_Variant => (Decreases => S'Last - I + 1);

   --  the last index of the run of non-blank bytes that starts at I (I - 1 when none)
   function Word_To (S : String; I : Positive) return Natural is
     (if I > S'Last then I - 1
      elsif not Is_Blank (S (I)) then Word_To (S, I + 1)
      else I - 1)
     with Pre  => S'Last < Integer'Last and then I >= S'First and then I - 1 <= S'Last,
          Post => Word_To'Result in I - 1 .. S'Last
                  and then (for all K in I .. Word_To'Result => not Is_Blank (S (K)))
                  and then (if Word_To'Result < S'Last then Is_Blank (S (Word_To'Result + 1))),
          Subprogram_Variant => (Decreases => S'Last - I + 1);

   --  the first index at or after I that is not a blank (S'Last + 1 when none)
   function Skip_Blanks (S : String; I : Positive) return Positive is
     (if I > S'Last then I
      elsif Is_Blank (S (I)) then Skip_Blanks (S, I + 1)
      else I)
     with Pre  => S'Last < Integer'Last and then I >= S'First and then I - 1 <= S'Last,
          Post => Skip_Blanks'Result in I .. S'Last + 1
                  and then (for all K in I .. Skip_Blanks'Result - 1 => Is_Blank (S (K)))
                  and then (if Skip_Blanks'Result <= S'Last then not Is_Blank (S (Skip_Blanks'Result))),
          Subprogram_Variant => (Decreases => S'Last - I + 1);

   --  the last index at or before J that is not a blank (F - 1 when none from F)
   function Back_Blanks (S : String; F : Positive; J : Natural) return Natural is
     (if J < F then J
      elsif Is_Blank (S (J)) then Back_Blanks (S, F, J - 1)
      else J)
     with Pre  => S'Last < Integer'Last and then F >= S'First and then J <= S'Last and then F - 1 <= J,
          Post => Back_Blanks'Result in F - 1 .. J
                  and then (for all K in Back_Blanks'Result + 1 .. J => Is_Blank (S (K)))
                  and then (if Back_Blanks'Result >= F then not Is_Blank (S (Back_Blanks'Result))),
          Subprogram_Variant => (Decreases => J);

   --  a JSON number, exactly: -? (0 | [1-9][0-9]*) (. [0-9]+)? ([eE] [+-]? [0-9]+)?, at most 64 bytes
   function Exp_Ok (S : String; P : Positive) return Boolean is
     (P <= S'Last
      and then (declare
                  D : constant Positive := (if S (P) = '+' or else S (P) = '-' then P + 1 else P);
                begin
                  D <= S'Last and then Digits_To (S, D) = S'Last))
     with Pre => S'Length in 1 .. Max_Num and then S'Last < Integer'Last - 2 and then P >= S'First
                 and then P - 1 <= S'Last;

   function Frac_Ok (S : String; E : Positive) return Boolean is
     (if E = S'Last then True
      elsif S (E + 1) = '.' then
        (E + 2 <= S'Last
         and then Digits_To (S, E + 2) >= E + 2
         and then (declare
                     F : constant Natural := Digits_To (S, E + 2);
                   begin
                     F = S'Last
                     or else ((S (F + 1) = 'e' or else S (F + 1) = 'E') and then Exp_Ok (S, F + 2))))
      elsif S (E + 1) = 'e' or else S (E + 1) = 'E' then Exp_Ok (S, E + 2)
      else False)
     with Pre => S'Length in 1 .. Max_Num and then S'Last < Integer'Last - 2 and then E in S'Range;

   function Is_Json_Number (S : String) return Boolean is
     (S'Length in 1 .. Max_Num
      and then (declare
                  A : constant Positive := (if S (S'First) = '-' then S'First + 1 else S'First);
                begin
                  A <= S'Last
                  and then Is_Digit (S (A))
                  and then (if S (A) = '0' then Frac_Ok (S, A) else Frac_Ok (S, Digits_To (S, A)))))
     with Pre => S'Last < Integer'Last - 2;

   --  a bare value's kind: text: prefix -> text; true, false, null; a JSON number; else text
   function Kind_Of (V : String) return Value_Kind is
     (if V'Length >= 5 and then V (V'First .. V'First + 4) = "text:" then Text_Value
      elsif V = "true" then True_Value
      elsif V = "false" then False_Value
      elsif V = "null" then Null_Value
      elsif Is_Json_Number (V) then Number_Value
      else Text_Value)
     with Pre  => V'Length >= 1 and then V'Last < Integer'Last - 2,
          Post => Kind_Of'Result /= No_Value
                  and then (Kind_Of'Result = True_Value) = (V = "true")
                  and then (Kind_Of'Result = False_Value) = (V = "false")
                  and then (Kind_Of'Result = Null_Value) = (V = "null")
                  and then (if Kind_Of'Result = Number_Value then Is_Json_Number (V));

   --  one digit's value
   function Digit_Val (C : Character) return Natural is
     (Character'Pos (C) - Character'Pos ('0'))
     with Pre  => Is_Digit (C),
          Post => Digit_Val'Result <= 9;

   --  the value of the one to three digits S (F .. E)
   function Number_Of (S : String; F, E : Positive) return Natural is
     (if E = F then Digit_Val (S (F))
      elsif E = F + 1 then 10 * Digit_Val (S (F)) + Digit_Val (S (E))
      else 100 * Digit_Val (S (F)) + 10 * Digit_Val (S (F + 1)) + Digit_Val (S (E)))
     with Pre  => F in S'Range and then E in S'Range and then E >= F and then E - F <= 2
                  and then (for all K in F .. E => Is_Digit (S (K))),
          Post => Number_Of'Result <= 999;

   --  the command word's kind (Refused when the word is not one of the five)
   function Word_Kind (W : String) return Command_Kind is
     (if W = "PICK" then Pick
      elsif W = "SET" then Set
      elsif W = "REMOVE" then Remove
      elsif W = "APPEND" then Append
      elsif W = "ADD" then Add
      else Refused);

   function Refuse (Why : Refusal) return Form is
     ((Cmd => Refused, Why => Why, N => 0, Key_F => 0, Key_L => 0, Val_F => 0, Val_L => 0, Kind => No_Value))
     with Pre => Why /= None;

   --  lower case of an ASCII letter; every other byte as it is
   function Lower (C : Character) return Character is
     (if C in 'A' .. 'Z' then Character'Val (Character'Pos (C) + 32) else C);

   --  V equals the lower-case word W when letters are compared without case
   function Same_Word (V : String; W : String) return Boolean is
     (V'Length = W'Length
      and then (for all I in V'Range => Lower (V (I)) = W (W'First + (I - V'First))))
     with Pre => W'Length >= 1 and then V'Last < Integer'Last;

   --  a plain value that would be a GUESS to read as text: it begins like a number (a digit, or a
   --  minus sign and a digit) but is not a JSON number, or it is true, false or null in other letter
   --  cases. It is refused (bad_value), never guessed; the model writes text: in front for such text.
   function Unclear (V : String) return Boolean is
     (Kind_Of (V) = Text_Value
      and then not (V'Length >= 5 and then V (V'First .. V'First + 4) = "text:")
      and then (Is_Digit (V (V'First))
                or else (V (V'First) = '-' and then V'Length >= 2 and then Is_Digit (V (V'First + 1)))
                or else Same_Word (V, "true") or else Same_Word (V, "false") or else Same_Word (V, "null")))
     with Pre => V'Length >= 1 and then V'Last < Integer'Last - 2;

   --  the value from VS to TL: its kind, and the text itself (after a text: prefix); refused when unclear
   function Valued (L : String; C : Command_Kind; N : Positive; KF, KL : Natural; VS, TL : Positive) return Form is
     (if Unclear (L (VS .. TL)) then Refuse (Bad_Value)
      else
        (declare
           K : constant Value_Kind := Kind_Of (L (VS .. TL));
           F : constant Positive := (if K = Text_Value and then TL - VS + 1 >= 5 and then L (VS .. VS + 4) = "text:"
                                     then VS + 5 else VS);
         begin
           (Cmd => C, Why => None, N => N, Key_F => KF, Key_L => KL, Val_F => F, Val_L => TL, Kind => K)))
     with Pre  => L'First = 1 and then L'Length <= Max_Line and then VS <= TL and then TL <= L'Last
                  and then C in Set | Append | Add,
          Post => (Valued'Result.Cmd = Refused) = Unclear (L (VS .. TL))
                  and then (if Valued'Result.Cmd = Refused then Valued'Result.Why = Bad_Value
                                                               and then Valued'Result.Kind = No_Value)
                  and then (if Valued'Result.Cmd /= Refused then
                              Valued'Result.Cmd = C and then Valued'Result.Why = None
                              and then Valued'Result.Kind /= No_Value
                              and then Valued'Result.Val_F in VS .. TL + 1
                              and then Valued'Result.Val_L = TL
                              and then (if Valued'Result.Kind = Number_Value
                                        then Is_Json_Number (L (Valued'Result.Val_F .. Valued'Result.Val_L)))
                              and then (if Valued'Result.Kind = True_Value
                                        then L (Valued'Result.Val_F .. Valued'Result.Val_L) = "true")
                              and then (if Valued'Result.Kind = False_Value
                                        then L (Valued'Result.Val_F .. Valued'Result.Val_L) = "false")
                              and then (if Valued'Result.Kind = Null_Value
                                        then L (Valued'Result.Val_F .. Valued'Result.Val_L) = "null")
                              and then (if Valued'Result.Kind /= Text_Value then Valued'Result.Val_F = VS));

   --  after the line number ND (a command C on line N): what follows, up to TL
   function After_Number (L : String; C : Command_Kind; N : Positive; ND, TL : Positive) return Form is
     (if C = Pick or else C = Remove then
        (if ND = TL then (Cmd => C, Why => None, N => N, Key_F => 0, Key_L => 0, Val_F => 0, Val_L => 0, Kind => No_Value)
         else Refuse (Bad_Value))
      elsif ND = TL then Refuse (Bad_Value)
      elsif C = Set or else C = Append then Valued (L, C, N, 0, 0, Skip_Blanks (L, ND + 1), TL)
      else
        (declare
           KS : constant Positive := Skip_Blanks (L, ND + 1);
           KE : constant Natural := Word_To (L, KS);
         begin
           (if KE >= TL or else not Is_Plain_Key (L (KS .. KE)) then Refuse (Bad_Value)
            else Valued (L, C, N, KS, KE, Skip_Blanks (L, KE + 1), TL))))
     with Pre  => L'First = 1 and then L'Length <= Max_Line and then ND <= TL and then TL <= L'Last
                  and then not Is_Blank (L (TL)) and then (if ND < TL then Is_Blank (L (ND + 1)))
                  and then C /= Refused,
          Post => (After_Number'Result.Cmd = Refused) = (After_Number'Result.Why /= None)
                  and then (if After_Number'Result.Cmd /= Refused then After_Number'Result.Cmd = C
                            and then After_Number'Result.N = N)
                  and then (if After_Number'Result.Cmd in Pick | Remove then After_Number'Result.Kind = No_Value)
                  and then (if After_Number'Result.Cmd in Set | Append | Add then
                              After_Number'Result.Kind /= No_Value
                              and then After_Number'Result.Val_F in ND + 1 .. TL + 1
                              and then After_Number'Result.Val_L = TL)
                  and then (if After_Number'Result.Cmd = Add then
                              After_Number'Result.Key_F in ND + 1 .. TL
                              and then After_Number'Result.Key_L in After_Number'Result.Key_F .. TL - 1
                              and then After_Number'Result.Val_F > After_Number'Result.Key_L + 1
                              and then Is_Plain_Key (L (After_Number'Result.Key_F .. After_Number'Result.Key_L)))
                  and then (if After_Number'Result.Cmd /= Refused and then After_Number'Result.Kind = Number_Value
                            then Is_Json_Number (L (After_Number'Result.Val_F .. After_Number'Result.Val_L)));

   --  the command line L (the reply's last non-blank line) against a view of Line_Count lines
   function Parse (L : String; Line_Count : Natural) return Form is
     (declare
        TF : constant Positive := Skip_Blanks (L, 1);
        TL : constant Natural := Back_Blanks (L, 1, L'Last);
      begin
        (if TF > L'Last or else TL < TF then Refuse (No_Command)
         else
           (declare
              WE : constant Natural := Upper_To (L, TF);
            begin
              (if WE < TF or else (WE < TL and then not Is_Blank (L (WE + 1)))
               then Refuse (No_Command)
               elsif Word_Kind (L (TF .. WE)) = Refused then Refuse (Unknown_Command)
               elsif WE = TL then Refuse (Line_Out_Of_Range)
               else
                 (declare
                    NS : constant Positive := Skip_Blanks (L, WE + 1);
                    ND : constant Natural := Digits_To (L, NS);
                  begin
                    (if ND < NS or else ND - NS + 1 > 3 or else L (NS) = '0'
                       or else (ND < TL and then not Is_Blank (L (ND + 1)))
                     then Refuse (Line_Out_Of_Range)
                     else
                       (declare
                          N : constant Natural := Number_Of (L, NS, ND);
                        begin
                          (if N not in 1 .. Line_Count then Refuse (Line_Out_Of_Range)
                           else After_Number (L, Word_Kind (L (TF .. WE)), N, ND, TL)))))))))
     with Pre  => L'First = 1 and then L'Last in 0 .. Max_Line and then Line_Count <= Max_Lines,
          Post => (Parse'Result.Cmd = Refused) = (Parse'Result.Why /= None)
                  and then Parse'Result.Why /= Kind_Mismatch
                  and then (if Parse'Result.Cmd /= Refused then Parse'Result.N in 1 .. Line_Count)
                  and then (if Parse'Result.Cmd in Pick | Remove then Parse'Result.Kind = No_Value)
                  and then (if Parse'Result.Cmd in Set | Append | Add then
                              Parse'Result.Kind /= No_Value
                              and then Parse'Result.Val_F in 1 .. L'Last + 1
                              and then Parse'Result.Val_L in Parse'Result.Val_F - 1 .. L'Last)
                  and then (if Parse'Result.Cmd = Add then
                              Parse'Result.Key_F in 1 .. L'Last
                              and then Parse'Result.Key_L in Parse'Result.Key_F .. L'Last
                              and then Is_Plain_Key (L (Parse'Result.Key_F .. Parse'Result.Key_L)))
                  and then (if Parse'Result.Cmd /= Refused and then Parse'Result.Kind = Number_Value
                            then Is_Json_Number (L (Parse'Result.Val_F .. Parse'Result.Val_L)));

   --  the refusal's name, as the repair text and the events carry it
   function Refusal_Word (Why : Refusal) return String is
     (case Why is
         when None              => "none",
         when No_Command        => "no_command",
         when Unknown_Command   => "unknown_command",
         when Line_Out_Of_Range => "line_out_of_range",
         when Bad_Value         => "bad_value",
         when Kind_Mismatch     => "kind_mismatch");

   --  the refusal in plain words, for the repair round (never a guess at what was meant)
   function Refusal_Plain (Why : Refusal) return String is
     (case Why is
         when None              => "",
         when No_Command        =>
           "your reply did not end with a command line (PICK, SET, REMOVE, APPEND or ADD)",
         when Unknown_Command   =>
           "the last line starts with a word that is not one of PICK, SET, REMOVE, APPEND, ADD",
         when Line_Out_Of_Range =>
           "the line number is missing or is not one of the numbered lines shown",
         when Bad_Value         =>
           "the value or key is missing, not allowed, or something follows the command",
         when Kind_Mismatch     =>
           "that command does not fit that line (APPEND needs a list line, ADD an object line)")
     with Post => (Refusal_Plain'Result'Length > 0) = (Why /= None);

end Answer_Form_Pkg;
