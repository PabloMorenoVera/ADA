--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Command_Line;
with tipo_mensajes;
with chat_handler;
with Ada.Calendar;
with Debug;
with Pantalla;
with Image;


procedure Chat_Peer is
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;
   package TP renames tipo_mensajes;
   package CH renames chat_handler;
   package AC renames Ada.Calendar;
   package Img renames Image;
   use type TP.Message_Type;
   use type CH.Seq_N_T;
   use type CH.Neighbors.Keys_Array_Type;
   use type LLU.End_Point_Type;


   Port: Integer;
   Nickname: ASU.Unbounded_String;
   Vecino1: LLU.End_Point_Type;
   Vecino2: LLU.End_Point_Type;
   Mensaje: TP.Message_Type;
   EP_H: LLU.End_Point_Type;
   EP_R: LLU.End_Point_Type;
   Seq_N: CH.Seq_N_T;
   Expired: Boolean;
   Neighbors_Array_Keys: CH.Neighbors.Keys_Array_Type;
   Neighbors_Array_Time: CH.Neighbors.Values_Array_Type;
   Latest_Msgs_Array_Keys: CH.Latest_Msgs.Keys_Array_Type;
   Latest_Msgs_Array_Seq: CH.Latest_Msgs.Values_Array_Type;
   Max_Lenght: Integer:= 10;
   IP: ASU.Unbounded_String;
   Puerto: ASU.Unbounded_String;
   Prompt: Boolean := False;

   Usage_Error: exception;


   procedure Crear_Handler (EP_H:in out LLU.End_Point_Type; Port: Integer)is

   begin
      -- Construye un End_Point libre cualquiera
      --y se ata a él para recibir los mensajes.
      EP_H := LLU.Build (LLU.To_IP(LLU.Get_Host_Name), Port);
      LLU.Bind (EP_H, CH.Handler'Access);
   end Crear_Handler;

   procedure Enviar_Init(Mensaje: out TP.message_Type;
                         Nickname: ASU.Unbounded_String;
                         Seq_N: in out CH.Seq_N_T;
                         Vecino1:LLU.End_Point_Type;
                         Vecino2: LLU.End_Point_Type;
                         Neighbors_Array_Keys: in out CH.NH_Neighbors.Keys_Array_Type;
                         EP_H: LLU.End_Point_Type) is

      Buffer: aliased LLU.Buffer_Type(1024);
      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      EP_R_Creat: LLU.End_Point_Type;
      Encontrado: Boolean;
      Time: AC.Time;


   begin

      --Inicializa el Mensaje a Init.
      Mensaje := TP.Init;
      --Asigna el Nodo primario.
      EP_H_Creat := EP_H;
      --Asigna el Nodo que reenvia.
      EP_H_Rsnd :=EP_H;
      --Asigna el Nodo primario al que se le enviará el "Reject".
      EP_R_Creat := EP_R;

      -- Reinicializa el buffer para empezar a utilizarlo.
      LLU.Reset(Buffer);

      -- Introduce el los datos en el Buffer.
      TP.Message_Type'Output(Buffer'Access, Mensaje);
      LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
      CH.Seq_N_T'Output(Buffer'Access, Seq_N);
      LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
      LLU.End_Point_Type'Output(Buffer'Access, EP_R_Creat);
      ASU.Unbounded_String'Output(Buffer'Access, Nickname);

      Time := Ada.Calendar.Clock;
      CH.Neighbors.Put(M       => CH.Lista_Vecinos,
                       Key     => Vecino1,
                       Value   => Time,
                       Success => Encontrado);

      Img.Get_IP_Port(Vecino1, IP, Puerto);

      Debug.Put_Line ("Añadimos a neighbors " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

      CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                         Key     => Vecino1,
                         Value   => Seq_N,
                         Success => Encontrado);

      if Ada.Command_Line.Argument_Count = 6 then
         CH.Neighbors.Put(M       => CH.Lista_Vecinos,
                       Key     => Vecino2,
                       Value   => Time,
                          Success => Encontrado);

         CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                            Key     => Vecino2,
                            Value   => Seq_N,
                            Success => Encontrado);

         Img.Get_IP_Port(Vecino2, IP, Puerto);
         Debug.Put_Line ("Añadimos a neighbors " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

      end if;

      Debug.Put_Line("", Pantalla.Verde);
      Debug.Put_Line ("Iniciando Protocolo de Admisión ...", Pantalla.Verde);
      Debug.Put_Line("Añadimos a latest_messages" & ASU.To_String(IP) & ":" &
                     ASU.To_String(Puerto) & CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);

      CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                         Key     => EP_H,
                         Value   => Seq_N,
                         Success => Encontrado);

      Neighbors_Array_Keys := CH.Neighbors.Get_Keys(CH.Lista_Vecinos);

      Img.Get_IP_Port (EP_H, IP, Puerto);
      Debug.Put("FLOOD Init ", Pantalla.Amarillo);
      Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
      Debug.Put (" " & CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);
      Debug. Put_Line (" " & ASU.To_String(IP) & " ... " & ASU.To_String(Nickname), Pantalla.Verde);

      for i in 1..Max_Lenght loop
         if Neighbors_Array_Keys(i) /= Null then

            Img.Get_IP_Port (Neighbors_Array_Keys(i), IP, Puerto);
            Debug.Put ("        send to: ", Pantalla.Verde);
            Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

            --Envia el init.
            LLU.Send (Neighbors_Array_Keys(i), Buffer'Access);
         end if;
      end loop;
      Debug.Put_Line("", Pantalla.Verde);

      --Aumento el numero de secuencia.
      Seq_N := Seq_N+1;

      Debug.Put_Line("Añadimos a latest_messages" & ASU.To_String(IP) & ":" &
                     ASU.To_String(Puerto) & CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);

      CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                         Key     => EP_H,
                         Value   => Seq_N,
                         Success => Encontrado);
   end Enviar_Init;

   procedure Esperar_Reject (EP_R: LLU.End_Point_Type;
                             Mensaje:in out TP.Message_Type;
                             EP_H: LLU.End_Point_Type;
                             Seq_N: in out CH.Seq_N_T;
                             Nickname: ASU.Unbounded_String;
                             Expired:out Boolean) is

      Buffer: aliased LLU.Buffer_Type(1024);

      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      Confirm_Sent: Boolean;

   begin
      LLU.Reset(Buffer);

      -- Espera a recibir el confirm o el reject.
      LLU.Receive (EP_R, Buffer'Access, 2.0, Expired);

      if Expired then
         --Envio el Confirm
         Mensaje := TP.Confirm;
         EP_H_Creat := EP_H;
         EP_H_Rsnd := EP_H;

         LLU.Reset(Buffer);
         TP.Message_Type'Output(Buffer'Access, Mensaje);
         LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
         CH.Seq_N_T'Output(Buffer'Access, Seq_N);
         LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
         ASU.Unbounded_String'Output(Buffer'Access, Nickname);

         --Escribo el mensaje.
            Img.Get_IP_Port (EP_H, IP, Puerto);
            Debug.Put ("FLOOD Confirm ", Pantalla.Amarillo);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put (" " & CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Debug. Put_Line (" " & ASU.To_String(IP) & " " & ASU.To_String(Nickname), Pantalla.Verde);


         Neighbors_Array_Keys := CH.Neighbors.Get_Keys(CH.Lista_Vecinos);

         for i in 1..Max_Lenght loop
            if Neighbors_Array_Keys(i) /= Null then

               Img.Get_IP_Port (Neighbors_Array_Keys(i), IP, Puerto);
               Debug.Put ("        send to: ", Pantalla.Verde);
               Debug.Put_Line(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);

               LLU.Send (Neighbors_Array_Keys(i), Buffer'Access);
            end if;
         end loop;


         --Aumento el numero de secuencia.
         Seq_N := Seq_N+1;

         Debug.Put_Line("Finalizamos protocolo de admisión", Pantalla.Verde);
         --Doy la bienvenida al usuario.
         ATI.Put_Line("Chat-Peer v1.0");
         ATI.Put_Line ("==============");
         ATI.New_Line;
         ATI.Put ("Entramos en el chat con el nick: ");
         ATI.Put_Line(ASU.To_String(Nickname));
         ATI.Put_Line (".h para help");

      else
         ATI.Put ("Has sido rechazado porque el nick ");
         ATI.Put (ASU.To_String(Nickname));
         ATI.Put_Line (" ya existe.");

         --Envio en Logout.
         Mensaje := TP.Logout;
         EP_H_Creat := EP_H;
         EP_H_Rsnd := EP_H;
         Confirm_Sent := False;

         LLU.Reset(Buffer);
         TP.Message_Type'Output(Buffer'Access, Mensaje);
         LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
         CH.Seq_N_T'Output(Buffer'Access, Seq_N);
         LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
         ASU.Unbounded_String'Output(Buffer'Access, Nickname);
         Boolean'Output(Buffer'Access, Confirm_Sent);

         for i in 1..Max_Lenght loop
            if Neighbors_Array_Keys(i) /= Null then
               LLU.Send (Neighbors_Array_Keys(i), Buffer'Access);
            end if;
         end loop;

      end if;

   end Esperar_Reject;

   procedure Escribir_Mensajes (Mensaje:in out TP.Message_Type;
                                EP_H: LLU.End_Point_Type;
                                Seq_N: in out CH.Seq_N_T;
                                Nickname: ASU.Unbounded_String;
                                EP_R: LLU.End_Point_Type;
                                Prompt: in out Boolean) is

      Buffer: aliased LLU.Buffer_Type(1024);
      EP_H_Creat: LLU.End_Point_Type;
      EP_H_Rsnd: LLU.End_Point_Type;
      Text: ASU.Unbounded_String;
      Fin: Boolean;
      Confirm_Sent: Boolean;
      Success: Boolean;

   begin

      Mensaje := TP.Writer;
      EP_H_Creat := EP_H;
      EP_H_Rsnd := EP_H;

      Fin := True;
      while Fin loop

         LLU.Reset (Buffer);

         Text := ASU.To_Unbounded_String (ATI.Get_Line);

         if ASU.To_String(Text) = ".h" then
            Debug.Put_Line("              Comandos          Efectos", Pantalla.Rojo);
            Debug.Put_Line("              =============     =======", Pantalla.Rojo);
            Debug.Put_Line("              .nb .neighbors    Lista de vecinos", Pantalla.Rojo);
            Debug.Put_Line("              .lm latest_msgs   Lista de ultimos mensajes recibidos", Pantalla.Rojo);
            Debug.Put_Line("              .debug            Toggle para la info del debug", Pantalla.Rojo);
            Debug.Put_Line("              .wai .whoami      Muestra en pantalla nick|EP_H | EP_R", Pantalla.Rojo);
            Debug.Put_Line("              .prompt           Toggle para mostrar prompt", Pantalla.Rojo);
            Debug.Put_Line("              .h .help          Muestra esta informacion de ayuda", Pantalla.Rojo);
            Debug.Put_Line("              .salir            Termina el programa", Pantalla.Rojo);


         elsif ASU.To_String(Text) = ".salir" then

            --Envio en Logout.
            Mensaje := TP.Logout;
            EP_H_Creat := EP_H;
            EP_H_Rsnd := EP_H;
            Confirm_Sent := True;

            LLU.Reset(Buffer);
            TP.Message_Type'Output(Buffer'Access, Mensaje);
            LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
            CH.Seq_N_T'Output(Buffer'Access, Seq_N);
            LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
            ASU.Unbounded_String'Output(Buffer'Access, Nickname);
            Boolean'Output(Buffer'Access, Confirm_Sent);

            for i in 1..Max_Lenght loop
               if Neighbors_Array_Keys(i) /= Null then
                  LLU.Send (Neighbors_Array_Keys(i), Buffer'Access);
               end if;
            end loop;

            Fin := False;

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

            for i in 1..Max_Lenght loop
               if Latest_Msgs_Array_Keys(i) /= Null then

                  Img.Get_IP_Port (Latest_Msgs_Array_Keys(i), IP, Puerto);
                  Debug.Put("             [ (", Pantalla.Rojo);
                  Debug.Put(ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Rojo);
                  Debug.Put("), ", Pantalla.Rojo);
                  Debug.Put(CH.Seq_N_T'Image(Latest_Msgs_Array_Seq(i)), Pantalla.Rojo);
                  Debug.Put_Line(" ]", Pantalla.Rojo);

               end if;
            end loop;

         elsif ASU.To_String(Text) = ".debug" then
            if Debug.Get_Status then
               Debug.Put_Line("Desactivada información de Debug", Pantalla.Rojo);
               Debug.Set_Status(False);
            elsif not Debug.Get_Status then
               Debug.Set_Status(True);
               Debug.Put_Line("Activada información de Debug", Pantalla.Rojo);
            end if;

         elsif ASU.To_String(Text) = ".wai" or ASU.To_String(Text) = ".whoami" then
            Debug.Put("Nick: " & ASU.To_String(Nickname) & " | ", Pantalla.Rojo);
            Img.Get_IP_Port (EP_H, IP, Puerto);
            Debug.Put("EP_H: " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto) & " | ", Pantalla.Rojo);
            Img.Get_IP_Port (EP_R, IP, Puerto);
            Debug.Put_Line("EP_R: " & ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Rojo);

         elsif ASU.To_String(Text) = ".prompt" then
            if Prompt then
               Debug.Put_Line("Desactivado el Prompt", Pantalla.Rojo);
               Prompt := False;
            else
               Debug.Put_Line("Activado el Prompt", Pantalla.Rojo);
               Prompt := True;

               ATI.Put (ASU.To_String(Nickname) & ">> ");
            end if;

         else
            TP.message_Type'Output(Buffer'Access, Mensaje);
            LLU.End_Point_Type'Output(Buffer'Access, EP_H_Creat);
            CH.Seq_N_T'Output(Buffer'Access, Seq_N);
            LLU.End_Point_Type'Output(Buffer'Access, EP_H_Rsnd);
            ASU.Unbounded_String'Output(Buffer'Access, Nickname);
            ASU.Unbounded_String'Output(Buffer'Access, Text);

            Seq_N := Seq_N+1;

            Debug.Put("Añadimos a latest_msgs ", Pantalla.Verde);
            Img.Get_IP_Port (EP_H, IP, Puerto);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put_Line(CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);

            CH.Latest_Msgs.Put(M       => CH.Lista_Mensajes,
                               Key     => EP_H,
                               Value   => Seq_N,
                               Success => Success);

            Latest_Msgs_Array_Keys := CH.Latest_Msgs.Get_Keys(CH.Lista_Mensajes);
            Neighbors_Array_Keys := CH.Neighbors.Get_Keys(CH.Lista_Vecinos);

            Debug.Put ("FLOOD Writer", Pantalla.Amarillo);
            Img.Get_IP_Port (EP_H, IP, Puerto);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put(CH.Seq_N_T'Image(Seq_N), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);
            Debug.Put (ASU.To_String(IP) & ":" & ASU.To_String(Puerto), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);
            Debug.Put (ASU.To_String(Nickname), Pantalla.Verde);
            Debug.Put (" ", Pantalla.Verde);
            Debug.Put_Line (ASU.To_String(Text), Pantalla.Verde);

            for i in 1..Max_Lenght loop
               if Latest_Msgs_Array_Keys(i) /= Null then

                  LLU.Send (Latest_Msgs_Array_Keys(i), Buffer'Access);
               end if;
            end loop;


            if Prompt = True then
               ATI.Put (ASU.To_String(Nickname) & ">> ");
            end if;

         end if;

      end loop;

   end Escribir_Mensajes;


begin

   --Inicializa el Mensaje a Init.
   Mensaje := TP.Init;

   --Inicializa el Seq_N.
   Seq_N := 1;

   --Saca los datos de la linea de comandos.
   if Ada.Command_Line.Argument_Count = 2 then
      Port:= Integer'Value(Ada.Command_Line.Argument(1));
      Nickname:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));

      Debug.Put_Line ("No hacemos protocolo de admision pues no tenemos contactos iniciales ...", Pantalla.Verde);

      ATI.Put_Line("Chat-Peer v1.0");
      ATI.Put_Line ("===============");
      ATI.New_Line;
      ATI.Put ("Entramos en el chat con el nick: ");
      ATI.Put_Line(ASU.To_String(Nickname));
      ATI.Put_Line (".h para help");

   else
      Port:= Integer'Value(Ada.Command_Line.Argument(1));
      Nickname:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));

      if Ada.Command_Line.Argument_Count = 4 then
         Vecino1 :=LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(3)),
                               Integer'Value(Ada.Command_Line.Argument(4)));
      else
      Port:= Integer'Value(Ada.Command_Line.Argument(1));
         Nickname:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));

         if Ada.Command_Line.Argument_Count = 6 then
            Vecino1 :=LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(3)),
                                 Integer'Value(Ada.Command_Line.Argument(4)));

            Vecino2 := LLU.Build (LLU.To_IP(Ada.Command_Line.Argument(5)),
                                  Integer'Value(Ada.Command_Line.Argument(6)));
         else
            raise Usage_Error;
         end if;
      end if;
   end if;

   -- Construye el End_Point en el que recibirá los mensjes "Reject".
   LLU.Bind_Any(EP_R);

   --Crea el Handler.
   Crear_Handler(EP_H, Port);
   --Envia el init a los demás usuarios.
   if Ada.Command_Line.Argument_Count >= 4 then
      Enviar_Init (Mensaje, Nickname, Seq_N, Vecino1, Vecino2, Neighbors_Array_Keys, EP_H);
      Esperar_Reject (EP_R, Mensaje, EP_H, Seq_N, Nickname, Expired);

      if Expired then
         Escribir_Mensajes(Mensaje, EP_H, Seq_N, Nickname, EP_R, Prompt);
      end if;
   end if;

   if Ada.Command_Line.Argument_Count = 2 then
      Escribir_Mensajes(Mensaje, EP_H, Seq_N, Nickname, EP_R, Prompt);
   end if;

   LLU.Finalize;

exception
   when Usage_Error => ATI.Put_Line ("Comandos Invalidos");
      LLU.Finalize;

end Chat_Peer;


