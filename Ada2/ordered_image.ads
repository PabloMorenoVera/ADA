--PAblo Moreno Vera
--Doble Grado Teleco + ADE.

with Ada.Calendar;
with Lower_Layer_UDP;
with Types;


package Ordered_Image is

   package LLU renames Lower_Layer_UDP;
   package T renames Types;

   use type T.Seq_N_T;
   use type Ada.Calendar.Time;

   function Sender_Dests_Iguales (Mess1: Types.Mess_Id_T; Mess2: Types.Mess_Id_T) return Boolean;
   function Sender_Dests_Menor (Mess1: Types.Mess_Id_T; Mess2: Types.Mess_Id_T) return Boolean;
   function Sender_Dests_Mayor (Mess1: Types.Mess_Id_T; Mess2: Types.Mess_Id_T) return Boolean;
   function Sender_Buffering_Iguales (T1: Ada.Calendar.Time; T2: Ada.Calendar.Time) return Boolean;
   function Sender_Buffering_Menor (T1: Ada.Calendar.Time; T2: Ada.Calendar.Time) return Boolean;
   function Sender_Buffering_Mayor (T1: Ada.Calendar.Time; T2: Ada.Calendar.Time) return Boolean;

end Ordered_Image;
