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

   function Mess_Image (Mess: T.Mess_Id_T) return String is

      EP_String: ASU.Unbounded_String;
      Seq_String: ASU.Unbounded_String;
      Mess_String: ASU.Unbounded_String;
      IP: ASU.Unbounded_String;
      Port: ASU.Unbounded_String;

   begin

      Get_IP_Port(Mess.EP, IP, Port);
      EP_String := IP & " " & Port;
      Seq_String := ASU.To_Unbounded_String (T.Seq_N_T'Image(Mess.Seq));
      Mess_String := EP_String & " " & Seq_String;

      return ASU.To_String (Mess_String);

   end Mess_Image;

   function Destination_Image (Destination: T.Destinations_T) return String is

      EP_String: ASU.Unbounded_String;
      Ret_String: ASU.Unbounded_String;
      Destination_String: ASU.Unbounded_String;
      IP: ASU.Unbounded_String;
      Port: ASU.Unbounded_String;
      i: Natural;

   begin

      i := 0;

      while Destination(i).EP /= Null loop
         Get_IP_Port(Destination(i).EP, IP, Port);
         EP_String := IP & " " & Port;
         Ret_String := ASU.To_Unbounded_String(Integer'Image(Destination(i).Retries) & " ");
         Destination_String := Natural'Image(i) & " " & EP_String & " " & Ret_String;

         i := i+1;
      end loop;

      return ASU.To_String (Destination_String);

   end Destination_Image;

   function Value_Image (Value: T.Value_T) return String is

      EPHC_String: ASU.Unbounded_String;
      Seq_String: ASU.Unbounded_String;
      Value_String:ASU.Unbounded_String;
      IP: ASU.Unbounded_String;
      Port: ASU.Unbounded_String;

   begin

      Get_IP_Port(Value.EP_H_Creat, IP, Port);
      EPHC_String := IP & " " & Port;
      Seq_String := ASU.To_Unbounded_String (T.Seq_N_T'Image(Value.Seq_N));
      Value_String := EPHC_String & " " & Seq_String;

      return ASU.To_String(Value_String);

   end Value_Image;

end Image;
