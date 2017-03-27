--Pablo Moreno Vera.
--Doble Grado Teleco + Ade.

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with chat_messages;

package body Handlers is

   package ASU renames Ada.Strings.Unbounded;
   package CM renames chat_messages;
   package ATI renames Ada.Text_IO;

   procedure Client_EP_Handler (From: in LLU.End_Point_Type;
                             To: in LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type) is

      Mensaje: CM.Message_Type;
      Nick: ASU.Unbounded_String;
      Comentario: ASU.Unbounded_String;

   begin
      Mensaje := CM.Message_Type'Input(P_Buffer);
      Nick := ASU.Unbounded_String'Input(P_Buffer);
      Comentario := ASU.Unbounded_String'Input(P_Buffer);

      ATI.New_Line;
      ATI.Put_Line (ASU.To_String(Nick) & ": " & ASU.To_String(Comentario));
      ATI.Put (">> ");

   end Client_EP_Handler;

end Handlers;

