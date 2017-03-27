--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Calendar;
with Ada.Unchecked_Deallocation;

with Tipo_Mensajes;
with chat_handler;
with Debug;
with Pantalla;
with Image;
with Types;
with Timed_Handlers;
with Use_Timed_Handler;


procedure Chat_Peer_2 is
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;
   package TP renames Tipo_Mensajes;
   package CH renames chat_handler;
   package AC renames Ada.Calendar;
   package Img renames Image;
   package T renames Types;
   package TH renames Timed_Handlers;
   package UTH renames Use_Timed_Handler;

   use type TP.Message_Type;
   use type T.Seq_N_T;
   use type CH.Neighbors.Keys_Array_Type;
   use type LLU.End_Point_Type;
   use type Ada.Calendar.Time;


   Max_Lenght: Integer:= 10;
   Plazo_Retransmision: Duration;

   Usage_Error: exception;

   procedure Free is new Ada.Unchecked_Deallocation (LLU.Buffer_Type, T.Buffer_A_T);

   procedure Enviar_Mensaje (Seq_N: in out T.Seq_N_T;
                             EP_H: LLU.End_Point_Type) is

      Neighbors_Array_Keys: CH.Neighbors.Keys_Array_Type;
      Destinations_Dests: T.Destinations_T;
      Sender_Buff: T.Value_T;
      Sender_Dest: T.Mess_Id_T;
      Tiempo: Ada.Calendar.Time;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;

   begin

      --Consigo los vecinos.
      Neighbors_Array_Keys := CH.Neighbors.Get_Keys(CH.Lista_Vecinos);

      --Introduzco el P_Buffer_Main en el Sender Buffering.
      Sender_Buff.EP_H_Creat := EP_H;
      Sender_Buff.Seq_N := Seq_N;
      Sender_Buff.P_Buffer := TP.P_Buffer_Main;

      --Introduzco los campos del Sender_Dests.
      Sender_Dest.EP := EP_H;
      Sender_Dest.Seq := Seq_N;


      --Envio el mensaje.
      for i in 1..Max_Lenght loop
         if Neighbors_Array_Keys(i) /= Null then

            if not T.Prompt then
               Img.Get_IP_Port (Neighbors_Array_Keys(i), IP, Puerto);
               Debug.Put ("        send to: ", Pantalla.Verde);
               Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            end if;

            --Envia el init.
            LLU.Send (Neighbors_Array_Keys(i), TP.P_Buffer_Main);

            --Introduzco los campos del Sender_Dests.
            Destinations_Dests(i).Ep := Neighbors_Array_Keys(i);
            Destinations_Dests(i).Retries := 0;

            -- Introduzco el mensaje pendiente de ser asentido.
            Tiempo := Ada.Calendar.Clock + Plazo_Retransmision;

            -- Introduzco el mensaja que tengo que asentir.
            CH.Sender_Buffering.Put(M     => CH.Lista_Buffer,
                                    Key   => Tiempo,
                                    Value => Sender_Buff);

            --Llamo a Th para retransmitir.
            Timed_Handlers.Set_Timed_Handler (Tiempo,
                                              UTH.Retransmitir_Mensaje'Access);

         end if;
      end loop;

      -- Introduzco el vecino del que espero el ACK.
      CH.Sender_Dests.Put (M     => CH.Lista_Dests,
                           Key   => Sender_Dest,
                           Value => Destinations_Dests);


      --Aumento el numero de secuencia.
      Seq_N := Seq_N+1;

   end Enviar_Mensaje;


   procedure Crear_Handler (EP_H:in out LLU.End_Point_Type; Port: Integer)is


   begin
      -- Construye un End_Point libre cualquiera
      --y se ata a él para recibir los mensajes.
      EP_H := LLU.Build (LLU.To_IP(LLU.Get_Host_Name), Port);
      LLU.Bind (EP_H, CH.Handler'Access);
   end Crear_Handler;

   procedure Enviar_Init(Mensaje: out TP.message_Type;
                         Nickname: ASU.Unbounded_String;
                         Seq_N: in out T.Seq_N_T;
                         Vecino1:LLU.End_Point_Type;
                         Vecino2: LLU.End_Point_Type;
                         EP_H: LLU.End_Point_Type;
                         EP_R: LLU.End_Point_Type) is

      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      EP_R_Creat: LLU.End_Point_Type;
      Encontrado: Boolean;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;
      Seq_0: T.Seq_N_T := 0;

   begin

      TP.P_Buffer_Main := new LLU.Buffer_Type(1024);

      --Inicializa el Mensaje a Init.
      Mensaje := TP.Init;
      --Asigna el Nodo primario.
      EP_H_Creat := EP_H;
      --Asigna el Nodo que reenvia.
      EP_H_Rsnd :=EP_H;
      --Asigna el Nodo primario al que se le enviará el "Reject".
      EP_R_Creat := EP_R;

      -- Introduce el los datos en el Buffer.
      TP.Message_Type'Output(TP.P_Buffer_Main, Mensaje);
      LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Creat);
      T.Seq_N_T'Output(TP.P_Buffer_Main, Seq_N);
      LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Rsnd);
      LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_R_Creat);
      ASU.Unbounded_String'Output(TP.P_Buffer_Main, Nickname);

      --Introduzco en el Neighbors y en Last_Msgs el/los nuevo/s vecino/s.
      CH.Neighbors.Put(M       => CH.Lista_Vecinos,
                       Key     => Vecino1,
                       Value   => Ada.Calendar.Clock,
                       Success => Encontrado);

      Img.Get_IP_Port(Vecino1, IP, Puerto);
      Debug.Put_Line ("Add to neighbors " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);


      if Ada.Command_Line.Argument(7) = "9001" then
         CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                            Key     => Vecino1,
                            Value   => Seq_0,
                            Success => Encontrado);
      end if;

      if Ada.Command_Line.Argument_Count = 9 then
         CH.Neighbors.Put(M       => CH.Lista_Vecinos,
                          Key     => Vecino2,
                          Value   => Ada.Calendar.Clock,
                          Success => Encontrado);

         Img.Get_IP_Port(Vecino2, IP, Puerto);
         Debug.Put_Line ("Add to neighbors " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

      end if;

      Img.Get_IP_Port(EP_H_Creat, IP, Puerto);
      Debug.Put_Line("", Pantalla.Verde);
      Debug.Put_Line ("Admission Protocol Iniciated ...", Pantalla.Verde);

      -- Actualizamos el Latest_Messages.
      Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
      Debug.Put_Line("", Pantalla.Verde);
      Debug.Put_Line("Add to latest_messages " & ASU.To_String(IP) & ":" &
                     ASU.To_String(Puerto) & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);

      CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                         Key     => EP_H_Creat,
                         Value   => Seq_N,
                         Success => Encontrado);

      Img.Get_IP_Port (EP_H_Creat, IP, Puerto);
      Debug.Put("FLOOD Init ", Pantalla.Amarillo);
      Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
      Debug.Put (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
      Debug. Put_Line (" " & ASU.To_String(IP) & " ... " & ASU.To_String(Nickname), Pantalla.Verde);

      -- Envio el Mensaje.
      Enviar_Mensaje(Seq_N, EP_H);

   end Enviar_Init;

   procedure Esperar_Reject (EP_R: LLU.End_Point_Type;
                             Mensaje:in out TP.Message_Type;
                             EP_H: LLU.End_Point_Type;
                             Seq_N: in out T.Seq_N_T;
                             Nickname: ASU.Unbounded_String;
                             Expired:out Boolean) is

      Buffer: aliased LLU.Buffer_Type(1024);

      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      Confirm_Sent: Boolean;
      Success: Boolean;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;

   begin

      TP.P_Buffer_Main := new LLU.Buffer_Type(1024);

      LLU.Reset(Buffer);

      -- Espera a recibir el confirm o el reject.
      LLU.Receive (EP_R, Buffer'Access, 5.0, Expired);

      if Expired then
         --Envio el Confirm
         Mensaje := TP.Confirm;
         EP_H_Creat := EP_H;
         EP_H_Rsnd := EP_H;

         TP.Message_Type'Output(TP.P_Buffer_Main, Mensaje);
         LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Creat);
         T.Seq_N_T'Output(TP.P_Buffer_Main, Seq_N);
         LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Rsnd);
         ASU.Unbounded_String'Output(TP.P_Buffer_Main, Nickname);

         -- Actualizamos el Latest_Messages.
         Debug.Put_Line("Add to latest_messages " & ASU.To_String(IP) & ":" &
                        ASU.To_String(Puerto) & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);

         CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                            Key     => EP_H_Creat,
                            Value   => Seq_N,
                            Success => Success);

         --Escribo el mensaje.
         Img.Get_IP_Port (EP_H, IP, Puerto);
         Debug.Put ("FLOOD Confirm ", Pantalla.Amarillo);
         Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
         Debug.Put (" " & T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
         Debug. Put_Line (" " & ASU.To_String(IP) & " " & ASU.To_String(Nickname), Pantalla.Verde);

         --Envio el Mensaje
         Enviar_Mensaje(Seq_N, EP_H);

         Debug.Put_Line("");
         Debug.Put_Line("Admission Protocol end", Pantalla.Verde);

         --Doy la bienvenida al usuario.
         ATI.Put_Line("Chat-Peer v1.0");
         ATI.Put_Line ("==============");
         ATI.New_Line;
         ATI.Put ("Joining chat with Nick: ");
         ATI.Put_Line(ASU.To_String(Nickname));
         ATI.Put_Line (".h for help");

      else

         ATI.Put ("You have been refused because the Nick ");
         ATI.Put (ASU.To_String(Nickname));
         ATI.Put_Line (" was already in use.");

         --Envio en Logout.
         Mensaje := TP.Logout;
         EP_H_Creat := EP_H;
         EP_H_Rsnd := EP_H;
         Confirm_Sent := False;

         --Actualizamos el Latest_Messages.
         Debug.Put("Add to latest_msgs ", Pantalla.Verde);
         Img.Get_IP_Port (EP_H, IP, Puerto);
         Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
         Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);

         CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                            Key     => EP_H,
                            Value   => Seq_N,
                            Success => Success);

         Debug.Put ("FLOOD Logout ", Pantalla.Amarillo);
         Img.Get_IP_Port (EP_H, IP, Puerto);
         Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
         Debug.Put(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
         Debug.Put (" ", Pantalla.Verde);
         Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
         Debug.Put (" ", Pantalla.Verde);
         Debug.Put (ASU.To_String(Nickname), Pantalla.Verde);
         Debug.Put (" ", Pantalla.Verde);
         Debug.Put_Line (Boolean'Image(Confirm_Sent), Pantalla.Verde);

         TP.Message_Type'Output(TP.P_Buffer_Main, Mensaje);
         LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Creat);
         T.Seq_N_T'Output(TP.P_Buffer_Main, Seq_N);
         LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Rsnd);
         ASU.Unbounded_String'Output(TP.P_Buffer_Main, Nickname);
         Boolean'Output(TP.P_Buffer_Main, Confirm_Sent);

         -- Envio el Mensaje.
         Enviar_Mensaje(Seq_N, EP_H);

         delay 5.0;

      end if;

   end Esperar_Reject;

   procedure Escribir_Mensajes (Mensaje:in out TP.Message_Type;
                                EP_H: LLU.End_Point_Type;
                                Seq_N: in out T.Seq_N_T;
                                Nickname: ASU.Unbounded_String;
                                EP_R: LLU.End_Point_Type;
                                Prompt: in out Boolean) is

      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      Text: ASU.Unbounded_String;
      Fin: Boolean;
      Confirm_Sent: Boolean;
      Success: Boolean;
      Latest_Msgs_Array_Seq: CH.Latest_Msgs.Values_Array_Type;
      Latest_Msgs_Array_Keys: CH.Latest_Msgs.Keys_Array_Type;
      Neighbors_Array_Time: CH.Neighbors.Values_Array_Type;
      Neighbors_Array_Keys: CH.Neighbors.Keys_Array_Type;
      IP: ASU.Unbounded_String;
      Puerto: ASU.Unbounded_String;

   begin

      Mensaje := TP.Writer;
      EP_H_Creat := EP_H;
      EP_H_Rsnd := EP_H;

      Fin := True;
      while Fin loop

         TP.P_Buffer_Main := new LLU.Buffer_Type(1024);

         Text := ASU.To_Unbounded_String (ATI.Get_Line);

         if ASU.To_String(Text) = ".h" then
            Debug.Put_Line("              Comandos           Efectos", Pantalla.Rojo);
            Debug.Put_Line("              =============      =======", Pantalla.Rojo);
            Debug.Put_Line("              .nb .neighbors     List of neighbors", Pantalla.Rojo);
            Debug.Put_Line("              .lm latest_msgs    List of messages received", Pantalla.Rojo);
            Debug.Put_Line("              .sd .sender_dest   List of earring neighbors", Pantalla.Rojo);
            Debug.Put_Line("              .sb .sender_buffer Lista of earrings buffers", Pantalla.Rojo);
            Debug.Put_Line("              .debug             Toggle for debug info", Pantalla.Rojo);
            Debug.Put_Line("              .wai .whoami       Show on the screen: Nick|EP_H | EP_R", Pantalla.Rojo);
            Debug.Put_Line("              .prompt            Toggle for prompt info", Pantalla.Rojo);
            Debug.Put_Line("              .h .help           Show help info", Pantalla.Rojo);
            Debug.Put_Line("              .salir             End the program", Pantalla.Rojo);


         elsif ASU.To_String(Text) = ".quit" then

            --Envio en Logout.
            Mensaje := TP.Logout;
            EP_H_Creat := EP_H;
            EP_H_Rsnd := EP_H;
            Confirm_Sent := True;

            TP.Message_Type'Output(TP.P_Buffer_Main, Mensaje);
            LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Creat);
            T.Seq_N_T'Output(TP.P_Buffer_Main, Seq_N);
            LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Rsnd);
            ASU.Unbounded_String'Output(TP.P_Buffer_Main, Nickname);
            Boolean'Output(TP.P_Buffer_Main, Confirm_Sent);

            --Actualizamos el Latest_Messages.
            if not T.Prompt then
               Debug.Put("Add to latest_msgs ", Pantalla.Verde);
               Img.Get_IP_Port (EP_H, IP, Puerto);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
            end if;

            CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                               Key     => EP_H,
                               Value   => Seq_N,
                               Success => Success);

            if not T.Prompt then
               Debug.Put ("FLOOD Logout ", Pantalla.Amarillo);
               Img.Get_IP_Port (EP_H, IP, Puerto);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put (ASU.To_String(Nickname), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put_Line (Boolean'Image(Confirm_Sent), Pantalla.Verde);
            end if;

            -- Envio el Mensaje.
            Enviar_Mensaje(Seq_N, EP_H);

            Fin := False;

            delay 5.0;

         elsif ASU.To_String(Text) = ".nb" or ASU.To_String(Text) = ".neighbors" then

            Neighbors_Array_Keys := CH.Neighbors.Get_Keys(CH.Lista_Vecinos);
            Neighbors_Array_Time := CH.Neighbors.Get_Values(CH.Lista_Vecinos);

            Debug.Put_Line("             Neighbors", Pantalla.Rojo);
            Debug.Put_Line("             ------------------", Pantalla.Rojo);

            for i in 1..Max_Lenght loop
               if Neighbors_Array_Keys(i) /= Null then

                  Img.Get_IP_Port (Neighbors_Array_Keys(i), IP, Puerto);
                  Debug.Put("             [ (", Pantalla.Rojo);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Rojo);
                  Debug.Put("), ", Pantalla.Rojo);
                  Debug.Put(Img.Image_2(Neighbors_Array_Time(i)), Pantalla.Rojo);
                  Debug.Put_Line(" ]", Pantalla.Rojo);
               end if;
            end loop;

         elsif ASU.To_String(Text) = ".lm" or ASU.To_String(Text) = ".latest_msgs" then

            Latest_Msgs_Array_Keys := CH.Latest_Msgs.Get_Keys(CH.Lista_Mensajes);
            Latest_Msgs_Array_Seq := CH.Latest_Msgs.Get_Values(CH.Lista_Mensajes);

            Debug.Put_Line("             Latest_Msgs", Pantalla.Rojo);
            Debug.Put_Line("             ------------------", Pantalla.Rojo);

            for i in 1..CH.Latest_Msgs.Map_Length(CH.Lista_Mensajes) loop
               if Latest_Msgs_Array_Keys(i) /= Null then

                  Img.Get_IP_Port (Latest_Msgs_Array_Keys(i), IP, Puerto);
                  Debug.Put("             [ (", Pantalla.Rojo);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Rojo);
                  Debug.Put("), ", Pantalla.Rojo);
                  Debug.Put(T.Seq_N_T'Image(Latest_Msgs_Array_Seq(i)), Pantalla.Rojo);
                  Debug.Put_Line(" ]", Pantalla.Rojo);

               end if;
            end loop;

         elsif ASU.To_String(Text) = ".sd" or ASU.To_String(Text) = ".sender_dests" then

            Debug.Put_Line("             Sender_Dests", Pantalla.Rojo);
            Debug.Put_Line("             ------------------", Pantalla.Rojo);

            CH.Sender_Dests.Print_Map(CH.Lista_Dests);

         elsif ASU.To_String(Text) = ".sb" or ASU.To_String(Text) = ".sender_buffering" then

            Debug.Put_Line("             Sender_Buffering", Pantalla.Rojo);
            Debug.Put_Line("             ------------------", Pantalla.Rojo);

            CH.Sender_Buffering.Print_Map(CH.Lista_Buffer);

         elsif ASU.To_String(Text) = ".debug" then

            if Debug.Get_Status then
               Debug.Put_Line("Debug information Desactivated", Pantalla.Rojo);
               Debug.Set_Status(False);
            elsif not Debug.Get_Status then
               Debug.Set_Status(True);
               Debug.Put_Line("Debug information Activated", Pantalla.Rojo);
            end if;

         elsif ASU.To_String(Text) = ".wai" or ASU.To_String(Text) = ".whoami" then

            Debug.Put("Nick: " & ASU.To_String(Nickname) & " | ", Pantalla.Rojo);
            Img.Get_IP_Port (EP_H, IP, Puerto);
            Debug.Put("EP_H: " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto) & " | ", Pantalla.Rojo);
            Img.Get_IP_Port (EP_R, IP, Puerto);
            Debug.Put_Line("EP_R: " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Rojo);

         elsif ASU.To_String(Text) = ".prompt" then

            if T.Prompt then
               Debug.Put_Line("Prompt Desactivated", Pantalla.Rojo);
               T.Prompt := False;
            else
               Debug.Put_Line("Prompt Activated", Pantalla.Rojo);
               T.Prompt := True;

               ATI.Put (ASU.To_String(Nickname) & ">> ");
            end if;

         else

            TP.message_Type'Output(TP.P_Buffer_Main, Mensaje);
            LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Creat);
            T.Seq_N_T'Output(TP.P_Buffer_Main, Seq_N);
            LLU.End_Point_Type'Output(TP.P_Buffer_Main, EP_H_Rsnd);
            ASU.Unbounded_String'Output(TP.P_Buffer_Main, Nickname);
            ASU.Unbounded_String'Output(TP.P_Buffer_Main, Text);

            if not T.Prompt then
               Debug.Put ("FLOOD Writer ", Pantalla.Amarillo);
               Img.Get_IP_Port (EP_H, IP, Puerto);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put (ASU.To_String(Nickname), Pantalla.Verde);
               Debug.Put (" ", Pantalla.Verde);
               Debug.Put_Line (ASU.To_String(Text), Pantalla.Verde);
            end if;

            --Envio el mensaje.
            Enviar_Mensaje(Seq_N, EP_H);

            if not T.Prompt then
               Debug.Put("Add to latest_msgs ", Pantalla.Verde);
               Img.Get_IP_Port (EP_H, IP, Puerto);
               Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
               Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);
            end if;

               CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                                  Key     => EP_H,
                                  Value   => Seq_N,
                                  Success => Success);

            if T.Prompt then
               ATI.Put (ASU.To_String(Nickname) & ">> ");
            end if;

         end if;

      end loop;

   end Escribir_Mensajes;


   Port: Integer;
   Nickname: ASU.Unbounded_String;
   Min_Delay: Natural;
   Max_Delay: Natural;
   Fault_Pct: Natural;
   Vecino1: LLU.End_Point_Type;
   Vecino2: LLU.End_Point_Type;
   Mensaje: TP.Message_Type;
   EP_H: LLU.End_Point_Type;
   EP_R: LLU.End_Point_Type;
   Seq_N: T.Seq_N_T;
   Expired: Boolean;
   Exito: Boolean := False;
   IP: ASU.Unbounded_String;
   Puerto: ASU.Unbounded_String;


begin

   if Ada.Command_Line.Argument_Count = 5 or
     Ada.Command_Line.Argument_Count = 7 or
     Ada.Command_Line.Argument_Count = 9 then

      Port:= Integer'Value(Ada.Command_Line.Argument(1));
      Nickname:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));
      Min_Delay:= Natural'Value(Ada.Command_Line.Argument(3));
      Max_Delay:= Natural'Value(Ada.Command_Line.Argument(4));
      Fault_Pct:= Natural'Value(Ada.Command_Line.Argument(5));

      --Utiliza la pérdida de mensajes.
      LLU.Set_Faults_Percent (Fault_Pct);

      --Utiliza el retardo de mensajes.
      LLU.Set_Random_Propagation_Delay (Min_Delay, Max_Delay);

      --Establece el Plazo de Retransmisión.
      Plazo_Retransmision := 2 * Duration(Max_Delay) / 1000;

      --Inicializa el Mensaje a Init.
      Mensaje := TP.Init;

      --Inicializa el Seq_N.
      Seq_N := 1;

   else
      raise Usage_Error;
   end if;

   if Ada.Command_Line.Argument_Count = 5 then

      Debug.Put_Line ("No admission protocol because we do not have initial contacts ...", Pantalla.Verde);

      ATI.Put_Line("Chat-Peer v1.0");
      ATI.Put_Line ("===============");
      ATI.New_Line;
      ATI.Put ("Joining the chat with Nick: ");
      ATI.Put_Line(ASU.To_String(Nickname));
      ATI.Put_Line (".h for help");

   else
      if Ada.Command_Line.Argument_Count = 7 then
         Vecino1 :=LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(6)),
                               Integer'Value(Ada.Command_Line.Argument(7)));
      else
         if Ada.Command_Line.Argument_Count = 9 then
            Vecino1 :=LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(6)),
                                 Integer'Value(Ada.Command_Line.Argument(7)));

            Vecino2 := LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(8)),
                                  Integer'Value(Ada.Command_Line.Argument(9)));
         else
            raise Usage_Error;
         end if;
      end if;
   end if;

   -- Crea el las pérdidas de mensajes.
   LLU.Set_Faults_Percent (Fault_Pct);

   -- Construye el End_Point en el que recibirá los mensjes "Reject".
   LLU.Bind_Any(EP_R);

   -- Crea el Handler.
   Crear_Handler(EP_H, Port);

   --Envia el init a los demás usuarios.
   if Ada.Command_Line.Argument_Count >= 7 then
      Enviar_Init (Mensaje, Nickname, Seq_N, Vecino1, Vecino2, EP_H, EP_R);
      Esperar_Reject (EP_R, Mensaje, EP_H, Seq_N, Nickname, Expired);

      if Expired then
         Escribir_Mensajes(Mensaje, EP_H, Seq_N, Nickname, EP_R, T.Prompt);
      end if;
   end if;

   if Ada.Command_Line.Argument_Count = 5 then

      --Actualizamos el Latest_Messages.
      Debug.Put("Add to latest_msgs ", Pantalla.Verde);
      Img.Get_IP_Port (EP_H, IP, Puerto);
      Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

      Debug.Put_Line(T.Seq_N_T'Image(Seq_N), Pantalla.Verde);

      CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                         Key     => EP_H,
                         Value   => Seq_N,
                         Success => Exito);

      Escribir_Mensajes(Mensaje, EP_H, Seq_N, Nickname, EP_R, T.Prompt);
   end if;

   LLU.Finalize;
   TH.Finalize;

exception
   when Usage_Error => ATI.Put_Line ("Invalid Commands");
      LLU.Finalize;
      TH.Finalize;

end Chat_Peer_2;
