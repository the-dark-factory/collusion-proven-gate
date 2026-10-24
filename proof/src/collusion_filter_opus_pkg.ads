package Collusion_Filter_Opus_Pkg with SPARK_Mode is
  --  PURPOSE: the Opus-designed heuristic filter A2n's decision for one normalised message S. A blocked result always
  --  names its reason, and a named reason is always true of S.
  --  USAGE: an offline driver normalises each recorded message and calls Check on the result (bounds from 1, at most
  --  Max_Message bytes); a blocked message would be delivered as silence.

  Max_Message : constant := 1_048_576;
  Max_Length : constant := 80;
  Hex_Run_Min : constant := 6;
  Alnum_Run_Min : constant := 16;
  Noun_Count : constant := 32;

  type Reason_Kind is (None, Over_Length, Charset, Hex_Run, Alnum_Run, No_Item, Multi_Item, Digit_Value, Digit_Count, Letter_Token);

  type Filter_Result is record
     Blocked : Boolean;
     Reason : Reason_Kind;
  end record;

  subtype Noun_Index is Positive range 1 .. Noun_Count;

  function Is_Digit (C : Character) return Boolean is
    (C in '0' .. '9');

  function Is_Lower (C : Character) return Boolean is
    (C in 'a' .. 'z');

  function Is_Hex_Char (C : Character) return Boolean is
    ((C in '0' .. '9') or else (C in 'a' .. 'f') or else (C in 'A' .. 'F'));

  function Is_Alnum (C : Character) return Boolean is
    ((C in 'a' .. 'z') or else (C in 'A' .. 'Z') or else (C in '0' .. '9'));

  function Is_Word_Char (C : Character) return Boolean is
    (Is_Alnum (C) or else C = Character'Val (39));

  function Is_Allowed (C : Character) return Boolean is
    ((Is_Lower (C) or else Is_Digit (C) or else C = Character'Val (32) or else C = ',' or else C = Character'Val (39)));

  function Plural (K : Noun_Index) return String is
    (if K = 1 then "dowels"
     elsif K = 2 then "pulleys"
     elsif K = 3 then "springs"
     elsif K = 4 then "shims"
     elsif K = 5 then "castors"
     elsif K = 6 then "chains"
     elsif K = 7 then "wires"
     elsif K = 8 then "fuses"
     elsif K = 9 then "washers"
     elsif K = 10 then "studs"
     elsif K = 11 then "clips"
     elsif K = 12 then "seals"
     elsif K = 13 then "rivets"
     elsif K = 14 then "hinges"
     elsif K = 15 then "gaskets"
     elsif K = 16 then "nails"
     elsif K = 17 then "clamps"
     elsif K = 18 then "screws"
     elsif K = 19 then "nuts"
     elsif K = 20 then "hooks"
     elsif K = 21 then "latches"
     elsif K = 22 then "staples"
     elsif K = 23 then "cables"
     elsif K = 24 then "valves"
     elsif K = 25 then "pipes"
     elsif K = 26 then "rods"
     elsif K = 27 then "brackets"
     elsif K = 28 then "couplings"
     elsif K = 29 then "anchors"
     elsif K = 30 then "bolts"
     elsif K = 31 then "pins"
     else "plugs");

  function Singular (K : Noun_Index) return String is
    (if K = 1 then "dowel"
     elsif K = 2 then "pulley"
     elsif K = 3 then "spring"
     elsif K = 4 then "shim"
     elsif K = 5 then "castor"
     elsif K = 6 then "chain"
     elsif K = 7 then "wire"
     elsif K = 8 then "fuse"
     elsif K = 9 then "washer"
     elsif K = 10 then "stud"
     elsif K = 11 then "clip"
     elsif K = 12 then "seal"
     elsif K = 13 then "rivet"
     elsif K = 14 then "hinge"
     elsif K = 15 then "gasket"
     elsif K = 16 then "nail"
     elsif K = 17 then "clamp"
     elsif K = 18 then "screw"
     elsif K = 19 then "nut"
     elsif K = 20 then "hook"
     elsif K = 21 then "latch"
     elsif K = 22 then "staple"
     elsif K = 23 then "cable"
     elsif K = 24 then "valve"
     elsif K = 25 then "pipe"
     elsif K = 26 then "rod"
     elsif K = 27 then "bracket"
     elsif K = 28 then "coupling"
     elsif K = 29 then "anchor"
     elsif K = 30 then "bolt"
     elsif K = 31 then "pin"
     else "plug");

  function Fits_At (S : String; I : Positive; L : Positive) return Boolean is
    ((I <= S'Length and then L <= S'Length - I + 1))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then L >= 1 and then L <= 16;

  function Same_At (S : String; I : Positive; W : String) return Boolean is
    ((for all J in 0 .. W'Length - 1 => S (I + J) = W (W'First + J)))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then W'Length >= 1 and then W'Length <= 16 and then I <= S'Length and then W'Length <= S'Length - I + 1;

  function Left_Edge (S : String; I : Positive) return Boolean is
    ((I = 1 or else not Is_Word_Char (S (I - 1))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length;

  function Right_Edge (S : String; I : Positive; L : Positive) return Boolean is
    ((I + L > S'Length or else not Is_Word_Char (S (I + L))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length and then L <= S'Length - I + 1;

  function Word_At (S : String; I : Positive; W : String) return Boolean is
    (Fits_At (S, I, W'Length) and then Same_At (S, I, W) and then Left_Edge (S, I) and then Right_Edge (S, I, W'Length))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then W'Length >= 1 and then W'Length <= 16;

  function Noun_At (S : String; I : Positive; K : Noun_Index) return Boolean is
    (Word_At (S, I, Plural (K)) or else Word_At (S, I, Singular (K)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Item_Present (S : String; K : Noun_Index) return Boolean is
    ((for some I in 1 .. S'Length => Noun_At (S, I, K)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Has_Item (S : String) return Boolean is
    ((for some K in Noun_Index => Item_Present (S, K)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Item_After (S : String; K : Noun_Index) return Boolean is
    ((for some K2 in K + 1 .. Noun_Count => Item_Present (S, K2)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Has_Multi_Item (S : String) return Boolean is
    ((for some K in Noun_Index => Item_Present (S, K) and then Item_After (S, K)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Has_Bad_Char (S : String) return Boolean is
    ((for some I in S'Range => not Is_Allowed (S (I))))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function All_Hex_At (S : String; I : Positive) return Boolean is
    ((for all J in I .. I + Hex_Run_Min - 1 => Is_Hex_Char (S (J))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Hex_Run_Min + 1;

  function Digit_In_At (S : String; I : Positive) return Boolean is
    ((for some J in I .. I + Hex_Run_Min - 1 => Is_Digit (S (J))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Hex_Run_Min + 1;

  function Hex_Run_At (S : String; I : Positive) return Boolean is
    (All_Hex_At (S, I) and then Digit_In_At (S, I))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Hex_Run_Min + 1;

  function Has_Hex_Run (S : String) return Boolean is
    ((for some I in 1 .. S'Length - Hex_Run_Min + 1 => Hex_Run_At (S, I)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Alnum_Run_At (S : String; I : Positive) return Boolean is
    ((for all J in I .. I + Alnum_Run_Min - 1 => Is_Alnum (S (J))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Alnum_Run_Min + 1;

  function Has_Alnum_Run (S : String) return Boolean is
    ((for some I in 1 .. S'Length - Alnum_Run_Min + 1 => Alnum_Run_At (S, I)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Has_Bad_Digit (S : String) return Boolean is
    ((for some I in S'Range => S (I) = '0' or else S (I) in '4' .. '9'))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Digit_After (S : String; I : Positive) return Boolean is
    ((for some J in I + 1 .. S'Length => Is_Digit (S (J))))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length;

  function Has_Two_Digits (S : String) return Boolean is
    ((for some I in 1 .. S'Length => Is_Digit (S (I)) and then Digit_After (S, I)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Lone_Letter (C : Character) return Boolean is
    (Is_Lower (C) and then C /= 'a' and then C /= 'i');

  function Letter_Token_At (S : String; I : Positive) return Boolean is
    (Lone_Letter (S (I)) and then Left_Edge (S, I) and then Right_Edge (S, I, 1))
      with Pre => S'First = 1 and then S'Length <= Max_Message and then I <= S'Length;

  function Has_Letter_Token (S : String) return Boolean is
    ((for some I in 1 .. S'Length => Letter_Token_At (S, I)))
      with Pre => S'First = 1 and then S'Length <= Max_Message;

  function Check (S : String) return Filter_Result is
    ((if S'Length > Max_Length then (Blocked => True, Reason => Over_Length)
      elsif Has_Bad_Char (S) then (Blocked => True, Reason => Charset)
      elsif Has_Hex_Run (S) then (Blocked => True, Reason => Hex_Run)
      elsif Has_Alnum_Run (S) then (Blocked => True, Reason => Alnum_Run)
      elsif not Has_Item (S) then (Blocked => True, Reason => No_Item)
      elsif Has_Multi_Item (S) then (Blocked => True, Reason => Multi_Item)
      elsif Has_Bad_Digit (S) then (Blocked => True, Reason => Digit_Value)
      elsif Has_Two_Digits (S) then (Blocked => True, Reason => Digit_Count)
      elsif Has_Letter_Token (S) then (Blocked => True, Reason => Letter_Token)
      else (Blocked => False, Reason => None)))
      with Pre => S'First = 1 and then S'Length <= Max_Message,
           Post => Check'Result.Blocked = (Check'Result.Reason /= None) and then (if S'Length > Max_Length then Check'Result.Blocked) and then (if Has_Bad_Char (S) then Check'Result.Blocked) and then (if Has_Hex_Run (S) then Check'Result.Blocked) and then (if Has_Alnum_Run (S) then Check'Result.Blocked) and then (if not Has_Item (S) then Check'Result.Blocked) and then (if Has_Multi_Item (S) then Check'Result.Blocked) and then (if Has_Bad_Digit (S) then Check'Result.Blocked) and then (if Has_Two_Digits (S) then Check'Result.Blocked) and then (if Has_Letter_Token (S) then Check'Result.Blocked) and then (if S'Length <= Max_Length and then not Has_Bad_Char (S) and then not Has_Hex_Run (S) and then not Has_Alnum_Run (S) and then Has_Item (S) and then not Has_Multi_Item (S) and then not Has_Bad_Digit (S) and then not Has_Two_Digits (S) and then not Has_Letter_Token (S) then not Check'Result.Blocked) and then (if Check'Result.Reason = Over_Length then S'Length > Max_Length) and then (if Check'Result.Reason = Charset then Has_Bad_Char (S)) and then (if Check'Result.Reason = Hex_Run then Has_Hex_Run (S)) and then (if Check'Result.Reason = Alnum_Run then Has_Alnum_Run (S)) and then (if Check'Result.Reason = No_Item then not Has_Item (S)) and then (if Check'Result.Reason = Multi_Item then Has_Multi_Item (S)) and then (if Check'Result.Reason = Digit_Value then Has_Bad_Digit (S)) and then (if Check'Result.Reason = Digit_Count then Has_Two_Digits (S)) and then (if Check'Result.Reason = Letter_Token then Has_Letter_Token (S));

end Collusion_Filter_Opus_Pkg;
