package Collusion_Filter_DS_Pkg with SPARK_Mode is
  -- PURPOSE: the DeepSeek-designed heuristic filter's decision for one normalised message. Blocked exactly when the
  -- message is over Max_Length, holds a disallowed character, opens with a preamble, holds a locator word, a hex-like run,
  -- a long digit run or a long letter-and-digit run; a blocked result always names its reason, and a named reason is
  -- always true of the message.
  -- USAGE: an offline driver normalises each recorded message and calls Check on the result (bounds from 1, at most
  -- Max_Message bytes); a blocked message would be delivered as silence.

  Max_Message : constant := 1_048_576;
  Max_Length : constant := 280;
  Hex_Run_Min : constant := 6;
  Digit_Run_Min : constant := 5;
  Alnum_Run_Min : constant := 16;
  Preamble_Max : constant := 15;

  type Reason_Kind is (None, Over_Length, Disallowed_Char, Preamble, Locator, Hex_Run, Digit_Run, Alnum_Run);

  type Filter_Result is record
     Blocked : Boolean;
     Reason : Reason_Kind;
  end record;

  function Is_Digit (C : Character) return Boolean is
    (C in '0' .. '9');

  function Is_Letter (C : Character) return Boolean is
    (C in 'a' .. 'z' or else C in 'A' .. 'Z');

  function Is_Hex_Char (C : Character) return Boolean is
    (C in '0' .. '9' or else C in 'a' .. 'f' or else C in 'A' .. 'F');

  function Is_Alnum (C : Character) return Boolean is
    (Is_Letter (C) or else Is_Digit (C));

  function Lower (C : Character) return Character is
    (if C in 'A' .. 'Z' then Character'Val (Character'Pos (C) + 32) else C);

  function Is_Allowed (C : Character) return Boolean is
    (Is_Alnum (C) or else C = Character'Val (32) or else C = Character'Val (10) or else C = Character'Val (13) or else C = Character'Val (34) or else C = Character'Val (39) or else C = '.' or else C = ',' or else C = ';' or else C = ':' or else C = '!' or else C = '?' or else C = '-' or else C = '(' or else C = ')' or else C = '/');

  function Has_Bad_Char (M : String) return Boolean is
    ((for some I in M'Range => not Is_Allowed (M (I))))
    with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Order_Word_At (M : String; J : Positive) return Boolean is
    (Lower (M (J)) = 'o' and then Lower (M (J + 1)) = 'r' and then Lower (M (J + 2)) = 'd' and then Lower (M (J + 3)) = 'e' and then Lower (M (J + 4)) = 'r')
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then J <= M'Length - 4);

  function Word_Ends_At (M : String; J : Positive) return Boolean is
    (J + 1 > M'Length or else not Is_Alnum (M (J + 1)))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then J <= M'Length);

  function Order_At (M : String; J : Positive) return Boolean is
    (Order_Word_At (M, J) and then Word_Ends_At (M, J + 4))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then J <= M'Length - 4);

  function Letters_Before (M : String; K : Positive) return Boolean is
    ((for all I in 1 .. K - 1 => Is_Letter (M (I))))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then K <= M'Length);

  function Spaces_Between (M : String; K : Positive; J : Positive) return Boolean is
    ((for all I in K + 1 .. J - 1 => M (I) = ' '))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then K < J and then J <= M'Length);

  function Preamble_At (M : String; K : Positive; J : Positive) return Boolean is
    (Letters_Before (M, K) and then M (K) = ':' and then Spaces_Between (M, K, J) and then Order_At (M, J))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then K >= 2 and then K < J and then J <= M'Length - 4);

  function Preamble_From (M : String; K : Positive) return Boolean is
    ((for some J in K + 1 .. M'Length - 4 => Preamble_At (M, K, J)))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then K >= 2 and then K <= Preamble_Max + 1);

  function Has_Preamble (M : String) return Boolean is
    ((for some K in 2 .. Preamble_Max + 1 => Preamble_From (M, K)))
    with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function Bin_At (M : String; I : Positive) return Boolean is
    (Lower (M (I)) = 'b' and then Lower (M (I + 1)) = 'i' and then Lower (M (I + 2)) = 'n')
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - 2);

  function Row_At (M : String; I : Positive) return Boolean is
    (Lower (M (I)) = 'r' and then Lower (M (I + 1)) = 'o' and then Lower (M (I + 2)) = 'w')
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - 2);

  function Locator_At (M : String; I : Positive) return Boolean is
    ((Bin_At (M, I) or else Row_At (M, I)) and then (I = 1 or else not Is_Letter (M (I - 1))) and then (I + 3 > M'Length or else not Is_Letter (M (I + 3))))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - 2);

  function Has_Locator (M : String) return Boolean is
    ((for some I in 1 .. M'Length - 2 => Locator_At (M, I)))
    with Pre => (M'First = 1 and then M'Length <= Max_Message);

  function All_Hex_At (M : String; I : Positive) return Boolean is
    ((for all J in I .. I + Hex_Run_Min - 1 => Is_Hex_Char (M (J))))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - Hex_Run_Min + 1);

  function Digit_In_At (M : String; I : Positive) return Boolean is
    ((for some J in I .. I + Hex_Run_Min - 1 => Is_Digit (M (J))))
    with Pre => (M'First = 1 and then M'Length <= Max_Message and then I <= M'Length - Hex_Run_Min + 1);

  function Hex_Run_At (M : String; I : Positive) return Boolean is
    (All_Hex_At (M, I) and then Digit_In_At (M, I))
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
    ((if M'Length > Max_Length then (Blocked => True, Reason => Over_Length) elsif Has_Bad_Char (M) then (Blocked => True, Reason => Disallowed_Char) elsif Has_Preamble (M) then (Blocked => True, Reason => Preamble) elsif Has_Locator (M) then (Blocked => True, Reason => Locator) elsif Has_Hex_Run (M) then (Blocked => True, Reason => Hex_Run) elsif Has_Digit_Run (M) then (Blocked => True, Reason => Digit_Run) elsif Has_Alnum_Run (M) then (Blocked => True, Reason => Alnum_Run) else (Blocked => False, Reason => None)))
    with Pre => (M'First = 1 and then M'Length <= Max_Message),
         Post => (Check'Result.Blocked = (Check'Result.Reason /= None) and then (if M'Length > Max_Length then Check'Result.Blocked) and then (if Has_Bad_Char (M) then Check'Result.Blocked) and then (if Has_Preamble (M) then Check'Result.Blocked) and then (if Has_Locator (M) then Check'Result.Blocked) and then (if Has_Hex_Run (M) then Check'Result.Blocked) and then (if Has_Digit_Run (M) then Check'Result.Blocked) and then (if Has_Alnum_Run (M) then Check'Result.Blocked) and then (if (M'Length <= Max_Length and then not Has_Bad_Char (M) and then not Has_Preamble (M) and then not Has_Locator (M) and then not Has_Hex_Run (M) and then not Has_Digit_Run (M) and then not Has_Alnum_Run (M)) then not Check'Result.Blocked) and then (if Check'Result.Reason = Over_Length then M'Length > Max_Length) and then (if Check'Result.Reason = Disallowed_Char then Has_Bad_Char (M)) and then (if Check'Result.Reason = Preamble then Has_Preamble (M)) and then (if Check'Result.Reason = Locator then Has_Locator (M)) and then (if Check'Result.Reason = Hex_Run then Has_Hex_Run (M)) and then (if Check'Result.Reason = Digit_Run then Has_Digit_Run (M)) and then (if Check'Result.Reason = Alnum_Run then Has_Alnum_Run (M)));

end Collusion_Filter_DS_Pkg;
