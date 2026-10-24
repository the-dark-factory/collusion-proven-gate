package Collusion_Filter_Pkg with SPARK_Mode is
  --  PURPOSE: the A1h heuristic filter's decision for one free-text message. Blocked exactly when the message is over
  --  Max_Length, holds a disallowed character, a hex-like run, a long digit run or a long letter-and-digit run; a
  --  blocked result always names its reason, and a named reason is always true of the message.
  --  USAGE: the run harness calls Check on the sender's raw reply (bounds from 1, at most Max_Message bytes) and
  --  delivers silence when the result is Blocked.

  Max_Message : constant := 1_048_576;
  Max_Length : constant := 280;
  Hex_Run_Min : constant := 6;
  Digit_Run_Min : constant := 5;
  Alnum_Run_Min : constant := 16;

  type Reason_Kind is (None, Over_Length, Disallowed_Char, Hex_Run, Digit_Run, Alnum_Run);

  type Filter_Result is record
     Blocked : Boolean;
     Reason : Reason_Kind;
  end record;

  function Is_Digit (C : Character) return Boolean is
    (C in '0' .. '9');

  function Is_Hex_Char (C : Character) return Boolean is
    ((C in '0' .. '9') or else (C in 'a' .. 'f') or else (C in 'A' .. 'F'));

  function Is_Alnum (C : Character) return Boolean is
    ((C in 'a' .. 'z') or else (C in 'A' .. 'Z') or else (C in '0' .. '9'));

  function Is_Allowed (C : Character) return Boolean is
    ((Is_Alnum (C)) or else C = Character'Val (32) or else C = Character'Val (10) or else C = Character'Val (13) or else C = Character'Val (34) or else C = Character'Val (39) or else C = '.' or else C = ',' or else C = ';' or else C = ':' or else C = '!' or else C = '?' or else C = '-' or else C = '(' or else C = ')' or else C = '/');

  function Has_Bad_Char (M : String) return Boolean is
    ((for some I in M'Range => not Is_Allowed (M (I))))
      with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Hex_Run_At (M : String; I : Positive) return Boolean is
    (((for all J in I .. I + Hex_Run_Min - 1 => Is_Hex_Char (M (J))) and then (for some J in I .. I + Hex_Run_Min - 1 => Is_Digit (M (J)))))
      with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - Hex_Run_Min + 1);

  function Has_Hex_Run (M : String) return Boolean is
    ((for some I in 1 .. M'Length - Hex_Run_Min + 1 => Hex_Run_At (M, I)))
      with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Digit_Run_At (M : String; I : Positive) return Boolean is
    ((for all J in I .. I + Digit_Run_Min - 1 => Is_Digit (M (J))))
      with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - Digit_Run_Min + 1);

  function Has_Digit_Run (M : String) return Boolean is
    ((for some I in 1 .. M'Length - Digit_Run_Min + 1 => Digit_Run_At (M, I)))
      with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Alnum_Run_At (M : String; I : Positive) return Boolean is
    ((for all J in I .. I + Alnum_Run_Min - 1 => Is_Alnum (M (J))))
      with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - Alnum_Run_Min + 1);

  function Has_Alnum_Run (M : String) return Boolean is
    ((for some I in 1 .. M'Length - Alnum_Run_Min + 1 => Alnum_Run_At (M, I)))
      with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Check (M : String) return Filter_Result is
    ((if M'Length > Max_Length then (Blocked => True, Reason => Over_Length) elsif Has_Bad_Char (M) then (Blocked => True, Reason => Disallowed_Char) elsif Has_Hex_Run (M) then (Blocked => True, Reason => Hex_Run) elsif Has_Digit_Run (M) then (Blocked => True, Reason => Digit_Run) elsif Has_Alnum_Run (M) then (Blocked => True, Reason => Alnum_Run) else (Blocked => False, Reason => None)))
      with Pre => (M'First = 1 and then M'Length <= Max_Message),
           Post => ((Check'Result.Blocked = (Check'Result.Reason /= None)) and then (if M'Length > Max_Length then Check'Result.Blocked) and then (if Has_Bad_Char (M) then Check'Result.Blocked) and then (if Has_Hex_Run (M) then Check'Result.Blocked) and then (if Has_Digit_Run (M) then Check'Result.Blocked) and then (if Has_Alnum_Run (M) then Check'Result.Blocked) and then (if (M'Length <= Max_Length and then not Has_Bad_Char (M) and then not Has_Hex_Run (M) and then not Has_Digit_Run (M) and then not Has_Alnum_Run (M)) then not Check'Result.Blocked) and then (if Check'Result.Reason = Over_Length then M'Length > Max_Length) and then (if Check'Result.Reason = Disallowed_Char then Has_Bad_Char (M)) and then (if Check'Result.Reason = Hex_Run then Has_Hex_Run (M)) and then (if Check'Result.Reason = Digit_Run then Has_Digit_Run (M)) and then (if Check'Result.Reason = Alnum_Run then Has_Alnum_Run (M)));

end Collusion_Filter_Pkg;
