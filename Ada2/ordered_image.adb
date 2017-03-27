--PAblo Moreno Vera
--Doble Grado Teleco + ADE.

package body Ordered_Image is

   function Sender_Dests_Iguales (Mess1: Types.Mess_Id_T;
                                  Mess2: Types.Mess_Id_T) return Boolean is

   begin
      if LLU.Image(Mess1.EP) = LLU.Image(Mess2.EP) then
         if Mess1.Seq = Mess2.Seq then
            Return True;
         else
            Return False;
         end if;
      else
         Return False;
      end if;

   end Sender_Dests_Iguales;

   function Sender_Dests_Menor (Mess1: Types.Mess_Id_T;
                                Mess2: Types.Mess_Id_T) return Boolean is

   begin
      if LLU.Image(Mess1.EP) < LLU.Image(Mess2.EP) then
         Return True;
      elsif LLU.Image(Mess1.EP) = LLU.Image(Mess2.EP) then
         if Mess1.Seq < Mess2.Seq then
            Return True;
         else
            Return False;
         end if;
      else
         Return False;
      end if;

   end Sender_Dests_Menor;

   function Sender_Dests_Mayor (Mess1: Types.Mess_Id_T;
                                Mess2: Types.Mess_Id_T) return Boolean is

   begin
      if LLU.Image(Mess1.EP) > LLU.Image(Mess2.EP) then
         Return True;
      elsif LLU.Image(Mess1.EP) = LLU.Image(Mess2.EP) then
         if Mess1.Seq > Mess2.Seq then
            Return True;
         else
            Return False;
         end if;
      else
         Return False;
      end if;

   end Sender_Dests_Mayor;

   function Sender_Buffering_Iguales (T1: Ada.Calendar.Time;
                                      T2: Ada.Calendar.Time) return Boolean is

   begin
      return T1=T2;
   end Sender_Buffering_Iguales;

   function Sender_Buffering_Menor (T1: Ada.Calendar.Time;
                                    T2: Ada.Calendar.Time) return Boolean is

   begin
      return T1<T2;
   end Sender_Buffering_Menor;

   function Sender_Buffering_Mayor (T1: Ada.Calendar.Time;
                                    T2: Ada.Calendar.Time) return Boolean is

   begin
      return T1>T2;
   end Sender_Buffering_Mayor;

end Ordered_Image;
