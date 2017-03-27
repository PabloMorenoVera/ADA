--PAblo Moreno Vera
--Doble Grado Teleco + ADE.

package body Image is

   function Image_3 (T: Ada.Calendar.Time) return String is
   begin
      return C_IO.Image(T, "%T.%i");
   end Image_3;


   function Image_2 (T: Ada.Calendar.Time) return String is
   begin
      return C_IO.Image(T, "%c");
   end Image_2;

   procedure Get_IP_Port (Direccion: LLU.End_Point_Type;
                          IP: out ASU.Unbounded_String;
                          Port: out ASU.Unbounded_String) is

      IP_Completa: ASU.Unbounded_String;
      Posicion: Natural;

   begin

      IP_Completa := ASU.To_Unbounded_String(LLU.Image(Direccion));
      Posicion := ASU.Index (IP_Completa, ":")+1;

      IP_Completa := ASU.Tail (IP_Completa, ASU.Length (IP_Completa) - Posicion) ;
      IP := (ASU.Head (IP_Completa, ASU.Index (IP_Completa, ",") - 1));
      Posicion:= ASU.Index (IP_Completa, ":")+2;
      Port := ASU.Tail (IP_Completa, ASU.Length (IP_Completa) - Posicion) ;


   end Get_IP_Port;

end Image;
