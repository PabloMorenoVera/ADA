
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Strings.Unbounded;
with Gnat.Calendar.Time_IO;
with Maps_G;
with Lower_Layer_UDP;
with Types;
with Debug;
with Pantalla;

package Image is
   package ASU renames Ada.Strings.Unbounded;
   package C_IO renames Gnat.Calendar.Time_IO;
   package LLU renames Lower_Layer_UDP;
   package T renames Types;

   use type ASU.Unbounded_String;
   use type T.Seq_N_T;
   use type LLU.End_Point_Type;

   function Image_3 (T: Ada.Calendar.Time) return String;

   function Image_2 (T: Ada.Calendar.Time) return String;

   procedure Get_IP_Port(Direccion: LLU.End_Point_Type;
                         IP: out ASU.Unbounded_String;
                         Port: out ASU.Unbounded_String);

   function Mess_Image (Mess: T.Mess_Id_T) return String;

   function Destination_Image (Destination: T.Destinations_T) return String;

   function Value_Image (Value: T.Value_T) return String;

end Image;
