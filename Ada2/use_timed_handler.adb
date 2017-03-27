--Pablo Moreno Vera
--Doble Grado Teleco + Ade.

with Lower_Layer_UDP;
with Chat_Handler;
with Types;
with Timed_Handlers;
with Debug;
with Pantalla;
with Image;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Ada.Text_IO;

Package body Use_Timed_Handler  is

   package LLU renames Lower_Layer_UDP;
   package CH renames Chat_Handler;
   package T renames Types;
   package Img renames Image;
   package ASU renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;

   use type LLU.End_Point_Type;
   use type Ada.Calendar.Time;

   procedure Retransmitir_Mensaje (Time: in Ada.Calendar.Time) is

      Valor: T.Value_T;
      Exito: Boolean;
      Num_Mensaje: T.Mess_Id_T;
      Ret_Vecinos: T.Destinations_T;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;
      Plazo_Retransmision: Duration;
      Enviado: Boolean := False;
      Nuevo_Tiempo: Ada.Calendar.Time;


   begin

      Exito := False;
      Plazo_Retransmision := 2 * Duration(Natural'Value(Ada.Command_Line.Argument(4))) / 1000;

      -- Busco el mensaje en el buffer.
      CH.Sender_Buffering.Get(M       => CH.Lista_Buffer,
                              Key     => Time,
                              Value   => Valor,
                              Success => Exito);

      if Exito then

         Num_Mensaje.EP := Valor.EP_H_Creat;
         Num_Mensaje.Seq := Valor.Seq_N;

         --Busco los vecinos que tengo que retransmitir.
         CH.Sender_Dests.Get(M       => CH.Lista_Dests,
                             Key     => Num_Mensaje,
                             Value   => Ret_Vecinos,
                             Success => Exito);

         if Exito then

            if not T.Prompt then
               Debug.Put("Retransmission... ", Pantalla.Magenta);
               Img.Get_IP_Port (Num_Mensaje.Ep, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Magenta);
               Debug.Put_Line(T.Seq_N_T'Image(Num_Mensaje.Seq), Pantalla.Magenta);
            end if;

            for i in 1..10 loop
               if Ret_Vecinos(i).EP /= Null and Ret_Vecinos(i).Retries < 10 then

                  LLU.Send (Ret_Vecinos(i).Ep, Valor.P_Buffer);

                  if not T.Prompt then
                     --Reenvio a los vecinos.
                     Debug.Put("    send to ", Pantalla.Magenta);
                     Img.Get_IP_Port (Ret_Vecinos(i).Ep, IP, Puerto);
                     Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Magenta);
                     Debug.Put_Line(" " & Integer'Image(Ret_Vecinos(i).Retries), Pantalla.Magenta);
                  end if;

                  Ret_Vecinos(i).Retries := Ret_Vecinos(i).Retries + 1;

                  Enviado := True;

                  CH.Sender_Buffering.Delete(M       => CH.Lista_Buffer,
                                             Key     => Time,
                                             Success => Exito);

                  Nuevo_Tiempo := Ada.Calendar.Clock + Plazo_Retransmision;


                  CH.Sender_Buffering.Put(M     => CH.Lista_Buffer,
                                          Key   => Nuevo_Tiempo,
                                          Value => Valor);

                  --Llamo a Th para retransmitir.
                  Timed_Handlers.Set_Timed_Handler (Nuevo_Tiempo,
                                                    Retransmitir_Mensaje'Access);

               end if;
            end loop;

            if Enviado then

               if not T.Prompt then
                  Img.Get_IP_Port (Num_Mensaje.Ep, IP, Puerto);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Gris_Oscuro);
                  Debug.Put(T.Seq_N_T'Image(Num_Mensaje.Seq), Pantalla.Gris_Oscuro);
                  Debug.Put_Line(" Update Sender_Dests", Pantalla.Gris_Oscuro);
               end if;

            -- Actualizo el sender_dests
            CH.Sender_Dests.Put(M     => CH.Lista_Dests,
                                Key   => Num_Mensaje,
                                Value => Ret_Vecinos);

            else

               if not T.Prompt then
                  Img.Get_IP_Port (Num_Mensaje.Ep, IP, Puerto);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Gris_Oscuro);
                  Debug.Put(T.Seq_N_T'Image(Num_Mensaje.Seq), Pantalla.Gris_Oscuro);
                  Debug.Put_Line(" Deleted from Sender_Dests", Pantalla.Gris_Oscuro);
               end if;

               -- Borro del Sender_Dests.
               CH.Sender_Dests.Delete(M       => CH.Lista_Dests,
                                      Key     => Num_Mensaje,
                                      Success => Exito);

               if not T.Prompt then
                  Debug.Put("Deleted Buffer: ", Pantalla.Azul_Claro);
                  Debug.Put(Img.Image_3(Time) & " ", Pantalla.Azul_Claro);
                  Img.Get_IP_Port (Valor.EP_H_Creat, IP, Puerto);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Azul_Claro);
                  Debug.Put_Line(T.Seq_N_T'Image(Valor.Seq_N), Pantalla.Azul_Claro);
               end if;

               --Borro el Sender_Buffering.
               CH.Sender_Buffering.Delete(M       => CH.Lista_Buffer,
                                          Key     => Time,
                                          Success => Exito);

            end if;

         else

            if not T.Prompt then
               Debug.Put("Deleted Buffer: ", Pantalla.Azul_Claro);
               Debug.Put(Img.Image_3(Time) & " ", Pantalla.Azul_Claro);
               Img.Get_IP_Port (Valor.EP_H_Creat, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Azul_Claro);
               Debug.Put_Line(T.Seq_N_T'Image(Valor.Seq_N), Pantalla.Azul_Claro);
            end if;

            --Borro el Sender_Buffering.
            CH.Sender_Buffering.Delete(M       => CH.Lista_Buffer,
                                       Key     => Time,
                                       Success => Exito);

         end if;
      end if;

   end Retransmitir_Mensaje;

end Use_Timed_Handler;
