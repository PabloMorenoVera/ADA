--Pablo Moreno Vera

with Ada.Text_IO;
with Ada.Calendar;
with Ada.Strings.Unbounded;
with Gnat.Calendar.Time_IO;
with Maps_G;
with Lower_Layer_UDP;

package Image is
   package ASU renames Ada.Strings.Unbounded;
   package C_IO renames Gnat.Calendar.Time_IO;
   package LLU renames Lower_Layer_UDP;


   function Image_3 (T: Ada.Calendar.Time) return String;

   function Image_2 (T: Ada.Calendar.Time) return String;

   procedure Get_IP_Port(Direccion: LLU.End_Point_Type;
                         IP: out ASU.Unbounded_String;
                         Port: out ASU.Unbounded_String);

end Image;

