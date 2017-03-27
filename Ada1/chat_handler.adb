--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.


package body Chat_Handler is

   procedure Handler (From: in LLU.End_Point_Type;
                      To: in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

      Mensaje: TP.Message_Type;
      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      EP_R_Creat: LLU.End_Point_Type;
      Seq_N: Seq_N_T;
      Nickname: ASU.Unbounded_String;
      Confirm_Sent: Boolean := False;
      Text: ASU.Unbounded_String;
      Neighbors_Array_Keys: Neighbors.Keys_Array_Type;
      Latest_msgs_Array_Keys: Latest_Msgs.Keys_Array_Type;
      Max_Lenght: Natural := 10;
      IP: ASU.Unbounded_String;
      Port: ASU.Unbounded_String;
      Success: Boolean;

      procedure Enviar_Reject (Mensaje: in out TP.Message_Type;
                               Nickname: ASU.Unbounded_String;
                               EP_R_Creat: LLU.End_Point_Type) is

         Buffer: aliased LLU.Buffer_Type(1024);


      begin
         Mensaje := TP.Reject;
         LLU.Reset(Buffer);

         TP.Message_Type'Output(Buffer'Access, Mensaje);
         LLU.End_Point_Type'Output(Buffer'Access, To);
         ASU.Unbounded_String'Output(Buffer'Access, Nickname);

         LLU.Send(EP_R_Creat, Buffer'Access);

      end Enviar_Reject;




      procedure Reenviar_Mensajes (EP_H_Creat: LLU.End_Point_Type;
                                   Seq_N: Seq_N_T;
                                   EP_H_Rsnd: LLU.End_Point_Type;
                                   Nickname: ASU.Unbounded_String;
                                   Mensaje: in out TP.Message_Type;
                                   EP_R_Creat: LLU.End_Point_Type;
                                   Text: ASU.Unbounded_String;
                                   Confirm_Sent: Boolean) is

         Buffer: aliased LLU.Buffer_Type(1024);
         Exito: Boolean;
         Valor: Seq_N_T;
         IP: ASU.Unbounded_String;

      begin

         Latest_Msgs.Get (M       => Lista_Mensajes,
                          Key     => EP_H_Creat,
                          Value   => Valor,
                          Success => Exito);

         if Exito and Valor < Seq_N then

            if Mensaje = TP.Confirm then
               Neighbors.Put(M       => Lista_Vecinos,
                             Key     => EP_H_Creat,
                             Value   => Ada.Calendar.Clock,
                             Success => Exito);

               ATI.Put_Line(ASU.To_String(Nickname) & " ha entrado en el chat");
            end if;

            --Mira los End Pointd de su lista de mensjes.
            Latest_msgs_Array_Keys := Latest_msgs.Get_Keys(Lista_Mensajes);


            if Mensaje /= TP.Logout then
               Debug.Put ("   Añadimos a latest_messages ", Pantalla.Verde);
               Img.Get_IP_Port (EP_H_Creat, IP, Port);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
               Debug.Put_Line(Seq_N_T'Image(Seq_N), Pantalla.Verde);

               --Actualizo el Seq_N de la lista.
               Latest_Msgs.Put(M       => Lista_Mensajes,
                               Key     => EP_H_Creat,
                               Value   => Seq_N,
                               Success => Exito);
            else

               if Confirm_Sent =  True then
                  ATI.Put_Line (ASU.To_String(Nickname) & " ha abandonado el chat");
               end if;

               --Borro del neighbors y del latest_msgs

               --Escribimos el mensaje.
               Debug.Put ("   Borramos de neighbors a ", Pantalla.Verde);
               Img.Get_IP_Port(EP_H_Creat, IP, Port);
               Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);

               Neighbors.Delete(M       => Lista_Vecinos,
                                Key     => EP_H_Creat,
                                Success => Success);


               --Escribimos el mensaje.
               Debug.Put ("   Borramos de latest_msgs a ", Pantalla.Verde);
               Img.Get_IP_Port(EP_H_Creat, IP, Port);
               Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);

               Latest_Msgs.Delete(M       => Lista_Mensajes,
                                  Key     => EP_H_Creat,
                                  Success => Success);

            end if;

            --Reintroducimos el Buffer.

            --Reseteamos el Buffer.
            LLU.Reset(Buffer);

            --Reenvio el mensaje
            TP.Message_Type'Output(Buffer'Access, Mensaje);
            LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
            Seq_N_T'Output(Buffer'Access, Seq_N);
            LLU.End_Point_Type'Output(Buffer'Access, To);


            if Mensaje = TP.Init then
               Debug.Put("   FLOOD Init ", Pantalla.Amarillo);

               --Itroduzco el EP_R_Creat.
               LLU.End_Point_Type'Output(Buffer'Access, EP_R_Creat);
            end if;

            --Introduzco el Nick.
            ASU.Unbounded_String'Output(Buffer'Access, Nickname);

            if Mensaje = TP.Confirm then
               --Escribimos los mensajes
               Debug.Put ("   FLOOD Confirm ", Pantalla.Amarillo);

            elsif Mensaje = TP.Writer then
               --Escribimos el mensaje.
               Debug.Put("   FLOOD Writer ", Pantalla.Amarillo);

               --Introduzco el Texto.
               ASU.Unbounded_String'Output(Buffer'Access, Text);

            elsif Mensaje = TP.Logout then

               --Escribimos el mensaje.
               Debug.Put("   FLOOD Logout ", Pantalla.Amarillo);

               --Introducimos el Confirm_Sent.
               Boolean'Output(Buffer'Access, Confirm_Sent);

            end if;

            Img.Get_IP_Port (EP_H_Creat, IP, Port);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put (" " & Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Port);
            Debug.Put (" " & ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put(" ... " & ASU.To_String(Nickname), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);

            --Escribe el Texto que le llega
            if Mensaje = TP.Writer then
               Debug.Put_Line(ASU.To_String(Text), Pantalla.Verde);

               ATI.Put_Line (ASU.To_String(Nickname) & ": " & ASU.To_String(Text));
            else
               Debug.Put_Line("", Pantalla.Verde);
            end if;

            --Enviamos el Buffer.
            for i in 1..Max_Lenght loop
               if Latest_msgs_Array_Keys(i) /= null and
                 Latest_msgs_Array_Keys(i) /= EP_H_Rsnd  and
                 Latest_msgs_Array_Keys(i) /= EP_H_Creat then

                  --Escribimos los mensajes.
                  Debug.Put ("      send to: ", Pantalla.Verde);
                  Img.Get_IP_Port (Latest_msgs_Array_Keys(i), IP, Port);
                  Debug.Put_Line (ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);

                  LLU.Send(Latest_msgs_Array_Keys(i), Buffer'Access);
               end if;
            end loop;

         elsif Valor >= Seq_N  and Exito then


            -- Por aqui deberia hacer un actualizar 'lm' para los reenvios que me llegan
            -- de vecinos lejanos. Porque no me guarda en lm los mensajes que no sean de mi vecino.

            --Escribimos los mensajes.
            if Mensaje = TP.Init then
               Debug.Put("   NOFLOOD Init ", Pantalla.Amarillo);
            elsif Mensaje = TP.Writer then
               Debug.Put("   NOFLOOD Writer ", Pantalla.Amarillo);
            elsif Mensaje = TP.Logout then
               Debug.Put("   NOFLOOD Logout ", Pantalla.Amarillo);
            elsif Mensaje = TP.Confirm then
               Debug.Put("   NOFLOOD Confirm ", Pantalla.Amarillo);
            end if;

            Img.Get_IP_Port (EP_H_Creat, IP, Port);

            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put (Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Debug.Put_Line (" ", Pantalla.Verde);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Port);
            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);

         end if;


         --Si el Usuario no está en el latest_msgs
         --lo introducimos.
         if Mensaje /= TP.Logout then
            if not Exito then

               --Introduzco el Usuario.
               Latest_Msgs.Put(M       => Lista_Mensajes,
                               Key     => EP_H_Creat,
                               Value   => Seq_N,
                               Success => Exito);


               if Nickname = ASU.To_Unbounded_String(Ada.Command_Line.Argument(2)) then

                  --Escribimos el mensaje.
                  Debug.Put ("Send Reject ", Pantalla.Amarillo);
                  Img.Get_IP_Port (To, IP, Port);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
                  Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);

                  --Enviamos el reject
                  Enviar_Reject(Mensaje, Nickname, EP_R_Creat);

               else


                  Neighbors.Put(M       => Lista_Vecinos,
                                Key     => EP_H_Creat,
                                Value   => Ada.Calendar.Clock,
                                Success => Exito);
               end if;


               LLU.Reset(Buffer);

               --Reenvio el mensaje
               TP.Message_Type'Output(Buffer'Access, Mensaje);
               LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
               Seq_N_T'Output(Buffer'Access, Seq_N);
               LLU.End_Point_Type'Output(Buffer'Access, To);

               if Mensaje = TP.Init then
                  --Escribimos el mensaje.
                  Debug.Put("   FLOOD Init ", Pantalla.Amarillo);
                  Img.Get_IP_Port (EP_H_Creat, IP, Port);
                  Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
                  Debug.Put (" " & Seq_N_T'Image(Seq_N), Pantalla.Verde);
                  Img.Get_IP_Port (EP_H_Rsnd, IP, Port);
                  Debug.Put (" " & ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
                  Debug.Put_Line(" ... " & ASU.To_String(Nickname), Pantalla.Verde);


                  LLU.End_Point_Type'Output(Buffer'Access, EP_R_Creat);
               end if;

               ASU.Unbounded_String'Output(Buffer'Access, Nickname);

               if Mensaje = TP.Writer then
                  ASU.Unbounded_String'Output(Buffer'Access, Text);
               elsif Mensaje = TP.Logout then
                  Boolean'Output(Buffer'Access, Confirm_Sent);
               end if;

               --Mira los End Pointd de su lista de mensjes.
               Latest_msgs_Array_Keys := Latest_msgs.Get_Keys(Lista_Mensajes);

               for i in 1..Max_Lenght loop
                  if Latest_msgs_Array_Keys(i) /= null and
                    Latest_msgs_Array_Keys(i) /= EP_H_Rsnd  and
                    Latest_msgs_Array_Keys(i) /= EP_H_Creat then

                     --Escribimos el mensaje.
                     Debug.Put ("      send to: ", Pantalla.Verde);
                     Img.Get_IP_Port (Latest_msgs_Array_Keys(i), IP, Port);
                     Debug.Put_Line (ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);

                     LLU.Send(Latest_msgs_Array_Keys(i), Buffer'Access);
                  end if;
               end loop;

            end if;

         else
            Debug.Put("   NOFLOOD Logout ", Pantalla.Amarillo);
            Img.Get_IP_Port (EP_H_Creat, IP, Port);
            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put (Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Port);
            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
            Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);

         end if;


         --Mira los End Pointd de su lista de mensjes.
         Latest_msgs_Array_Keys := Latest_msgs.Get_Keys(Lista_Mensajes);

         Latest_Msgs.Get (M       => Lista_Mensajes,
                          Key     => EP_H_Creat,
                          Value   => Valor,
                          Success => Exito);

      end Reenviar_Mensajes;


   begin

      --Saco los datos del Buffer.
      Mensaje := TP.Message_Type'Input(P_Buffer);
      EP_H_Creat := LLU.End_Point_Type'Input(P_Buffer);
      Seq_N := Seq_N_T'Input(P_Buffer);
      EP_H_Rsnd := LLU.End_Point_Type'Input(P_Buffer);

      if Mensaje = TP.Init then
         EP_R_Creat := LLU.End_Point_Type'Input(P_Buffer);

         Debug.Put_Line("", Pantalla.Verde);
         Debug.Put ("RCV Init ", Pantalla.Amarillo);
      end if;

      Nickname := ASU.Unbounded_String'Input(P_Buffer);

      if Mensaje = TP.Confirm then
         Debug.Put_Line("", Pantalla.Verde);
         Debug.Put ("RCV Confirm ", Pantalla.Amarillo);

      elsif Mensaje = TP.Logout then
         Confirm_Sent := Boolean'Input(P_Buffer);

         Debug.Put_Line("", Pantalla.Verde);
         Debug.Put ("RCV Logout ", Pantalla.Amarillo);

      elsif Mensaje = TP.Writer then
         Text := ASU.Unbounded_String'Input(P_Buffer);

         Debug.Put_Line("", Pantalla.Verde);
         Debug.Put ("RCV Writer ", Pantalla.Amarillo);
      end if;

      --Escribimos el mensaje.

      Img.Get_IP_Port (EP_H_Creat, IP, Port);
      Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
      Debug.Put (Seq_N_T'Image(Seq_N), Pantalla.Verde);
      Debug.Put (" ", Pantalla.Verde);
      Img.Get_IP_Port (EP_H_Rsnd, IP, Port);
      Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Port), Pantalla.Verde);
      Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);

      --Reenvia los init que le llegan(Inundación).
      Reenviar_Mensajes (EP_H_Creat, Seq_N, EP_H_Rsnd, Nickname, Mensaje, EP_R_Creat, Text, Confirm_Sent);

   end Handler;

end Chat_Handler;
