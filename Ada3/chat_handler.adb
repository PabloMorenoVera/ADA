--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.


package body Chat_Handler is

   procedure Handler (From: in LLU.End_Point_Type;
                      To: in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type) is

      Plazo_Retransmision: Duration;
      Max_Delay: Natural;
      Max_Lenght: Natural := 10;

      procedure Enviar_Mensaje(EP_H_Creat: LLU.End_Point_Type;
                               Seq_N: in out T.Seq_N_T;
                               EP_H_Rsnd: LLU.End_Point_Type) is

         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;
         Tiempo: Ada.Calendar.Time;
         Destinations_Dests: T.Destinations_T;
         Sender_Buff: T.Value_T;
         Sender_Dest: T.Mess_Id_T;
         Neighbors_Array_Keys: Neighbors.Keys_Array_Type;


      begin

         --Consigo los vecinos.
         Neighbors_Array_Keys := Neighbors.Get_Keys(Lista_Vecinos);

         -- Establece el retardo máximo.
         Max_Delay:= Natural'Value(Ada.Command_Line.Argument(4));

         --Establece el Plazo de Retransmisión.
         Plazo_Retransmision := 2 * Duration(Max_Delay) / 1000;

         --Introduzco el P_Buffer_Handler en el Sender Buffering.
         Sender_Buff.EP_H_Creat := EP_H_Creat;
         Sender_Buff.Seq_N := Seq_N;
         Sender_Buff.P_Buffer := TP.P_Buffer_Handler;

         --Introduzco los campos del Sender_Dests.
         Sender_Dest.EP := EP_H_Creat;
         Sender_Dest.Seq := Seq_N;

         --Envio el mensaje.
         for i in 1..Neighbors.Map_Length(Lista_Vecinos) loop
            if Neighbors_Array_Keys(i) /= Null
            and Neighbors_Array_Keys(i) /= EP_H_Creat then

               Img.Get_IP_Port (Neighbors_Array_Keys(i), IP, Puerto);
               Debug.Put ("        send to: ", Pantalla.Verde);
               Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

               for j in 1..10 loop
                  if Neighbors_Array_Keys(j) /= EP_H_Rsnd then
                     --Introduzco los campos del Sender_Dests.
                     Destinations_Dests(j).Ep := Neighbors_Array_Keys(j);
                     Destinations_Dests(j).Retries := 0;
                  end if;
               end loop;

               --Envia el Mensaje.
               LLU.Send (Neighbors_Array_Keys(i), TP.P_Buffer_Handler);

               -- Introduzco el mensaje pendiente de ser asentido.
               Tiempo := Ada.Calendar.Clock + Plazo_Retransmision;

               -- Introduzco el mensaje a asentir.
               Sender_Buffering.Put(M     => Lista_Buffer,
                                    Key   => Tiempo,
                                    Value => Sender_Buff);

               --Llamo a Th para retransmitir.
               Timed_Handlers.Set_Timed_Handler (Tiempo,
                                                 UTH.Retransmitir_Mensaje'Access);

            end if;
         end loop;


         -- Introduzco el vecino del que espero el ACK.
         Sender_Dests.Put (M     => Lista_Dests,
                           Key   => Sender_Dest,
                           Value => Destinations_Dests);

         --Aumento el numero de secuencia.
         Seq_N := Seq_N+1;

      end Enviar_Mensaje;


      procedure Enviar_ACK (EP_H_Rsnd: LLU.End_Point_Type;
                            EP_H_Creat: LLU.End_Point_Type;
                            Seq_N: T.Seq_N_T) is

         Mensaje_ACK: TP.Message_Type;
         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;
         P_Buffer_Handler: T.Buffer_A_T;

      begin

         P_Buffer_Handler := new LLU.Buffer_Type(1024);

         Mensaje_ACK := TP.Ack;

         TP.Message_Type'Output(P_Buffer_Handler, Mensaje_ACK);
         LLU.End_Point_Type'Output(P_Buffer_Handler, To);
         LLU.End_Point_Type'Output(P_Buffer_Handler, EP_H_Creat);
         T.Seq_N_T'Output(P_Buffer_Handler, Seq_N);

         if not T.Prompt then
            Debug.Put ("Send ACK to: " , Pantalla.Azul);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Azul);
            Debug.Put_Line (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Azul);
         end if;

         --Envío el mensaje.
         LLU.Send(EP_H_Rsnd, P_Buffer_Handler);

      end Enviar_ACK;

      procedure Recibir_ACK (Mensaje: TP.Message_Type;
                             EP_H_Rsnd: LLU.End_Point_Type;
                             EP_H_Creat: LLU.End_Point_Type;
                             Seq_N: T.Seq_N_T) is

         Done: Boolean := False;
         Vecino_ACK: T.Mess_Id_T;
         Destino: T.Destinations_T;
         Vecinos_Asentidos: Boolean := True;
         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;

      begin

         --Introduzco los datos del vecino que tengo que borrar.
         Vecino_ACK.EP := EP_H_Creat;
         Vecino_ACK.Seq := Seq_N;

         if not T.Prompt then

            Debug.Put ("RCV ACK ", Pantalla.Gris_Oscuro);
            Debug.Put ("Borramos a ", Pantalla.Gris_Oscuro);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Gris_Oscuro);
            Debug.Put(T.Seq_N_T'Image(Seq_N), Pantalla.Gris_Oscuro);
            Debug.Put_Line (" de Sender_Dests", Pantalla.Gris_Oscuro);

         end if;

         -- Saco mi lista de vecinos que tengo que asentir.
         Sender_Dests.Get(M       => Lista_Dests,
                          Key     => Vecino_ACK,
                          Value   => Destino,
                          Success => Done);

         -- Borro el vecino del que me llega el ACK.
         for i in 1..10 loop
            if Destino(i).EP = EP_H_Rsnd then
               Destino(i).EP := Null;
               Destino(i).Retries := 0;

            end if;
         end loop;

         --Actualizo la lista.
         Sender_Dests.Put(M     => Lista_Dests,
                          Key   => Vecino_ACK,
                          Value => Destino);

         -- Compruebo si los vecinos están asentidos.
         for i in 1..10 loop
            if Destino(i).Ep /= Null then
               Vecinos_Asentidos := False;
            end if;
         end loop;

         if Vecinos_asentidos then
            --Borro el sender_dests(todos asentidos).
            Sender_Dests.Delete(M       => Lista_Dests,
                                Key     => Vecino_ACK,
                                Success => Done);

         end if;

      end Recibir_ACK;

      procedure Enviar_Reject (Mensaje: in out TP.Message_Type;
                               Nickname: ASU.Unbounded_String;
                               EP_R_Creat: LLU.End_Point_Type;
                               EP_H_Rsnd: LLU.End_Point_Type) is

         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;

      begin

         TP.P_Buffer_Handler := new LLU.Buffer_Type(1024);

         Mensaje := TP.Reject;

         TP.Message_Type'Output(TP.P_Buffer_Handler, Mensaje);
         LLU.End_Point_Type'Output(TP.P_Buffer_Handler, To);
         ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Nickname);

         LLU.Send(EP_R_Creat, TP.P_Buffer_Handler);

      end Enviar_Reject;

      procedure Ordenar_Mensaje (Seq_N: T.Seq_N_T;
                                 Valor: T.Seq_N_T;
                                 Mensaje_Adelantado: out Boolean;
                                 EP_H_Rsnd: LLU.End_Point_Type;
                                 EP_H_Creat: LLU.End_Point_Type) is

         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;
         Exito: Boolean;

      begin

         if Valor+1 < Seq_N then

            Debug.Put("Mensaje adelantado",Pantalla.Magenta);
            T.Seq_N_Adelantado := Seq_N;
            Mensaje_Adelantado := True;

         else

            Debug.Put ("   Añadimos a latest_messages ", Pantalla.Verde);
            Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);

            --Actualizo el Seq_N de la lista.
            Latest_Msgs.Put(M       => Lista_Mensajes,
                            Key     => EP_H_Creat,
                            Value   => Seq_N,
                            Success => Exito);

            --Envía el Acks al vecino que le ha enviado el mensaje.
            Enviar_ACK(EP_H_Rsnd, EP_H_Creat, Seq_N);


         end if;

      end Ordenar_Mensaje;

      procedure Reenviar_Mensajes (EP_H_Creat: LLU.End_Point_Type;
                                   Seq_N: in out T.Seq_N_T;
                                   EP_H_Rsnd: LLU.End_Point_Type;
                                   Nickname: ASU.Unbounded_String;
                                   Mensaje: in out TP.Message_Type;
                                   EP_R_Creat: LLU.End_Point_Type;
                                   Text: ASU.Unbounded_String;
                                   Confirm_Sent: Boolean) is

         Exito: Boolean;
         Valor: T.Seq_N_T;
         IP: ASU.Unbounded_String;
         Puerto: ASU.Unbounded_String;
         Mensaje_Adelantado: Boolean;
         Neighbors_Array_Keys: Neighbors.Keys_Array_Type;
         Latest_msgs_Array_Keys: Latest_Msgs.Keys_Array_Type;

      begin

         --Creamos el Buffer.
         TP.P_Buffer_Handler := new LLU.Buffer_Type(1024);

         Latest_Msgs.Get (M       => Lista_Mensajes,
                          Key     => EP_H_Creat,
                          Value   => Valor,
                          Success => Exito);

         if Exito and Valor < Seq_N then

            -- Miramos si el mensaje es el consecutivo.
            Ordenar_Mensaje(Seq_N, Valor, Mensaje_Adelantado, EP_H_Rsnd, EP_H_Creat);

            if Mensaje = TP.Confirm then
               if EP_H_Creat = EP_H_Rsnd then

                  Img.Get_IP_Port(EP_H_Creat, IP, Puerto);
                  Debug.Put_Line ("Añadimos a neighbors " & ASU.To_String(IP)
                                  & ":" & ASU.To_String(Puerto), Pantalla.Verde);

                  --Añado al nuevo vecino.
                  Neighbors.Put(M       => Lista_Vecinos,
                                Key     => EP_H_Creat,
                                Value   => Ada.Calendar.Clock,
                                Success => Exito);

               end if;

               ATI.Put_Line("");
               ATI.Put_Line(ASU.To_String(Nickname) & " ha entrado en el chat");

            end if;

            if not Mensaje_Adelantado then
               if Mensaje = TP.Logout then

                  if Confirm_Sent =  True then
                     ATI.Put_Line (ASU.To_String(Nickname) & " ha abandonado el chat");
                  end if;

                  --Borro del neighbors y del latest_msgs--

                  if not T.Prompt then
                     --Escribimos el mensaje.
                     Debug.Put ("   Borramos de neighbors a ", Pantalla.Verde);
                     Img.Get_IP_Port(EP_H_Creat, IP, Puerto);
                     Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                  end if;

                  Neighbors.Delete(M       => Lista_Vecinos,
                                   Key     => EP_H_Creat,
                                   Success => Exito);

                  if not T.Prompt then
                     --Escribimos el mensaje.
                     Debug.Put ("   Borramos de latest_msgs a ", Pantalla.Verde);
                     Img.Get_IP_Port(EP_H_Creat, IP, Puerto);
                     Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                  end if;

                  Latest_Msgs.Delete(M       => Lista_Mensajes,
                                     Key     => EP_H_Creat,
                                     Success => Exito);

               end if;

               --Reintroducimos el Buffer.
               TP.Message_Type'Output(TP.P_Buffer_Handler, Mensaje);
               LLU.End_Point_Type'Output(TP.P_Buffer_Handler, EP_H_Creat);
               T.Seq_N_T'Output(TP.P_Buffer_Handler, Seq_N);
               LLU.End_Point_Type'Output(TP.P_Buffer_Handler, To);

               if Mensaje = TP.Init then
                  if not T.Prompt then
                     ATI.Put_Line("");
                     Debug.Put("   FLOOD Init ", Pantalla.Amarillo);
                  end if;

                  --Itroduzco el EP_R_Creat.
                  LLU.End_Point_Type'Output(TP.P_Buffer_Handler, EP_R_Creat);
               end if;

               --Introduzco el Nick.
               ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Nickname);

               if Mensaje = TP.Confirm  and not T.Prompt then
                  --Escribimos los mensajes
                  ATI.Put_Line("");
                  Debug.Put ("   FLOOD Confirm ", Pantalla.Amarillo);

               elsif Mensaje = TP.Writer then

                  --Escribe el Texto que le llega
                  if Mensaje = TP.Writer then
                     if not T.Prompt then
                        Debug.Put_Line(ASU.To_String(Text), Pantalla.Verde);
                     end if;

                     ATI.Put_Line (ASU.To_String(Nickname) & ": " & ASU.To_String(Text));

                  elsif not T.Prompt then
                     Debug.Put_Line("", Pantalla.Verde);
                  end if;

                  if not T.Prompt then
                     --Escribimos el mensaje.
                     Debug.Put("   FLOOD Writer ", Pantalla.Amarillo);
                  end if;

                  --Introduzco el Texto.
                  ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Text);

               elsif Mensaje = TP.Logout then

                  if not T.Prompt then
                     --Escribimos el mensaje.
                     Debug.Put("   FLOOD Logout ", Pantalla.Amarillo);
                  end if;

                  --Introducimos el Confirm_Sent.
                  Boolean'Output(TP.P_Buffer_Handler, Confirm_Sent);
               end if;


               if not T.Prompt then
                  Img.Get_IP_Port (EP_H_Creat, IP, Puerto);

                  Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                  Debug.Put (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
                  Debug.Put (" ", Pantalla.Verde);
                  Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
                  Debug.Put (" " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                  Debug.Put(" ... " & ASU.To_String(Nickname), Pantalla.Verde);
                  Debug.Put_Line ("", Pantalla.Verde);
               end if;

               --Envio el mensaje.
               Enviar_Mensaje(EP_H_Creat, Seq_N, EP_H_Rsnd);

            else

               --Reintroducimos el Buffer.
               --Reenvio el mensaje
               TP.Message_Type'Output(TP.P_Buffer_Handler, Mensaje);
               LLU.End_Point_Type'Output(TP.P_Buffer_Handler, EP_H_Creat);
               T.Seq_N_T'Output(TP.P_Buffer_Handler, Seq_N);
               LLU.End_Point_Type'Output(TP.P_Buffer_Handler, To);
               ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Nickname);
               ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Text);

               if not T.Prompt then
                  Debug.Put_Line ("... Reenviando", Pantalla.Magenta);
               end if;

               -- Envio el mensaje.
               Enviar_Mensaje(EP_H_Creat, Seq_N, EP_H_Rsnd);

            end if;

         elsif Valor >= Seq_N  and Exito then
            if not T.Prompt then

               Debug.Put_Line("Mensaje anterior... Enviando ACK",Pantalla.Magenta);

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

               Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put (T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
               Debug.Put_Line (" ", Pantalla.Verde);

               Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);

            end if;

            --Envía el Acks al vecino que le ha enviado el mensaje.
            Enviar_ACK(EP_H_Rsnd, EP_H_Creat, Seq_N);

         end if;

         --Si el Usuario no está en el latest_msgs
         --lo introducimos.
         if Mensaje /= TP.Logout then
            if not Exito then

               if EP_H_Creat = EP_H_Rsnd then

                  Img.Get_IP_Port(EP_H_Creat, IP, Puerto);
                  Debug.Put_Line ("Añadimos a neighbors " & ASU.To_String(IP)
                                  & ":" & ASU.To_String(Puerto), Pantalla.Verde);

                  --Añado al nuevo vecino.
                  Neighbors.Put(M       => Lista_Vecinos,
                                Key     => EP_H_Creat,
                                Value   => Ada.Calendar.Clock,
                                Success => Exito);

               end if;

               --Envía el Acks al vecino que le ha enviado el mensaje.
               Enviar_ACK(EP_H_Rsnd, EP_H_Creat, Seq_N);

               if Mensaje = TP.Writer then
                  ATI.Put_Line("");
                  ATI.Put_Line (ASU.To_String(Nickname) & ": " & ASU.To_String(Text));
               end if;

               if not T.Prompt then
                  Debug.Put ("   Añadimos a latest_messages ", Pantalla.Verde);
                  Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
                  Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                  Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
               end if;

               --Introduzco el Usuario.
               Latest_Msgs.Put(M       => Lista_Mensajes,
                               Key     => EP_H_Creat,
                               Value   => Seq_N,
                               Success => Exito);


               if Nickname = ASU.To_Unbounded_String(Ada.Command_Line.Argument(2)) then

                  if not T.Prompt then
                     --Escribimos el mensaje.
                     Debug.Put ("Send Reject ", Pantalla.Amarillo);
                     Img.Get_IP_Port (To, IP, Puerto);
                     Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                     Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);
                  end if;

                  --Enviamos el reject
                  Enviar_Reject(Mensaje, Nickname, EP_R_Creat, EP_H_Rsnd);

               else

                  --Reenvio el mensaje
                  TP.Message_Type'Output(TP.P_Buffer_Handler, Mensaje);
                  LLU.End_Point_Type'Output(TP.P_Buffer_Handler, EP_H_Creat);
                  T.Seq_N_T'Output(TP.P_Buffer_Handler, Seq_N);
                  LLU.End_Point_Type'Output(TP.P_Buffer_Handler, To);


                  if Mensaje = TP.Init then
                     if not T.Prompt then
                        --Escribimos el mensaje.
                        Debug.Put("   FLOOD Init ", Pantalla.Amarillo);
                        Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
                        Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                        Debug.Put (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
                        Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
                        Debug.Put (" " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                        Debug.Put_Line(" ... " & ASU.To_String(Nickname), Pantalla.Verde);
                     end if;

                     LLU.End_Point_Type'Output(TP.P_Buffer_Handler, EP_R_Creat);
                  end if;

                  ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Nickname);

                  if Mensaje = TP.Writer then

                     if not T.Prompt then
                        Debug.Put("   FLOOD Writer ", Pantalla.Amarillo);
                        Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
                        Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                        Debug.Put (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
                        Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
                        Debug.Put (" " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
                        Debug.Put_Line(" ... " & ASU.To_String(Nickname), Pantalla.Verde);
                     end if;

                     ASU.Unbounded_String'Output(TP.P_Buffer_Handler, Text);

                  elsif Mensaje = TP.Logout then
                     Boolean'Output(TP.P_Buffer_Handler, Confirm_Sent);
                  end if;

                  --Envio el mensaje.
                  Enviar_Mensaje(EP_H_Creat, Seq_N, EP_H_Rsnd);

               end if;
            end if;

         else

            if not T.Prompt then
               Debug.Put("   NOFLOOD Logout ", Pantalla.Amarillo);
               Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put (T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
               Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
               Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put_Line (" " & ASU.To_String(Nickname), Pantalla.Verde);
            end if;

            --Envía el Acks al vecino que le ha enviado el mensaje.
            Enviar_ACK(EP_H_Rsnd, EP_H_Creat, Seq_N);

         end if;

      end Reenviar_Mensajes;


      Mensaje: TP.Message_Type;
      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      EP_R_Creat: LLU.End_Point_Type;
      Seq_N: T.Seq_N_T;
      Nickname: ASU.Unbounded_String;
      Text: ASU.Unbounded_String;
      Confirm_Sent: Boolean := False;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;

   begin
      --Saco el mensaje del Buffer.
      Mensaje := TP.Message_Type'Input(P_Buffer);

      if Mensaje /= TP.Ack then

         --Saco el resto de datos.
         EP_H_Creat := LLU.End_Point_Type'Input(P_Buffer);
         Seq_N := T.Seq_N_T'Input(P_Buffer);
         EP_H_Rsnd := LLU.End_Point_Type'Input(P_Buffer);

         if Mensaje = TP.Init then

            EP_R_Creat := LLU.End_Point_Type'Input(P_Buffer);
            if not T.Prompt then
               Debug.Put_Line("", Pantalla.Verde);
               Debug.Put ("RCV Init ", Pantalla.Amarillo);
            end if;
         end if;

         Nickname := ASU.Unbounded_String'Input(P_Buffer);

         if Mensaje = TP.Confirm and not T.prompt then
            Debug.Put_Line("", Pantalla.Verde);
            Debug.Put ("RCV Confirm ", Pantalla.Amarillo);

         elsif Mensaje = TP.Logout then

            Confirm_Sent := Boolean'Input(P_Buffer);

            if not T.Prompt then
               Debug.Put_Line("", Pantalla.Verde);
               Debug.Put ("RCV Logout ", Pantalla.Amarillo);
            end if;

         elsif Mensaje = TP.Writer then

            Text := ASU.Unbounded_String'Input(P_Buffer);

            if not T.Prompt then
               Debug.Put_Line("", Pantalla.Verde);
               Debug.Put ("RCV Writer ", Pantalla.Amarillo);
            end if;

         end if;


         if not T.Prompt then
            --Escribimos el mensaje.
            Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put (T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);
            Img.Get_IP_Port (EP_H_Rsnd, IP, Puerto);
            Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put (" " & ASU.To_String(Nickname) & " ", Pantalla.Verde);
            Debug.Put_Line(ASU.To_String(Text), Pantalla.Verde);
         end if;

         --Reenvia los mensajes que le llegan (Inundación).
         Reenviar_Mensajes (EP_H_Creat, Seq_N, EP_H_Rsnd, Nickname, Mensaje, EP_R_Creat, Text, Confirm_Sent);

      else

         --Saco los campos del buffer.
         EP_H_Rsnd := LLU.End_Point_Type'Input(P_Buffer);
         EP_H_Creat := LLU.End_Point_Type'Input(P_Buffer);
         Seq_N := T.Seq_N_T'Input(P_Buffer);

         --Recibe los AKCs
         Recibir_ACK (Mensaje, EP_H_Rsnd, EP_H_Creat, Seq_N);
      end if;

   end Handler;

end Chat_Handler;
