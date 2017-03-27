--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.

with Ada.Text_IO;
With Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Calendar;
with Ada.Command_Line;

with Maps_G;
with Image;
with Tipo_Mensajes;
with Maps_Protector_G;
with Debug;
with Pantalla;
with Ordered_Maps_G;
with Ordered_Maps_Protector_G;
with Ordered_Image;
with Types;
with Timed_Handlers;
with Use_Timed_Handler;

package Chat_Handler is
   package ASU  renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package Img renames Image;
   package TP renames Tipo_Mensajes;
   package T renames Types;
   package OI renames Ordered_Image;
   package TH renames Timed_Handlers;
   package UTH renames Use_Timed_Handler;

   use type TP.Message_Type;
   use type LLU.End_Point_Type;
   use type ASU.Unbounded_String;
   use type T.Seq_N_T;
   use type Ada.Calendar.Time;


   package NH_Neighbors is new Maps_G (Key_Type => LLU.End_Point_Type,
                                       Value_Type => Ada.Calendar.Time,
                                       Null_Key => Null,
                                       Null_Value => Ada.Calendar.Time_Of(2000,1,1),
                                       Max_Length => 10,
                                       "=" => LLU."=",
                                       Key_To_String => LLU.Image,
                                       Value_To_String => Img.Image_3);

   package NP_Latest_Msgs is new Maps_G (Key_Type => LLU.End_Point_Type,
                                         Value_Type => T.Seq_N_T,
                                         Null_Key => Null,
                                         Null_Value => 0,
                                         Max_Length => 50,
                                         "=" => LLU."=",
                                         Key_To_String => LLU.Image,
                                         Value_To_String => T.Seq_N_T'Image);

   package NP_Sender_Dests is new Ordered_Maps_G (Key_Type        => T.Mess_Id_T,
                                                  Value_Type      => T.Destinations_T,
                                                  "="             => OI.Sender_Dests_Iguales,
                                                  "<"             => OI.Sender_Dests_Menor,
                                                  ">"             => OI.Sender_Dests_Mayor,
                                                  Key_To_String   => Img.Mess_Image,
                                                  Value_To_String => Img.Destinations_Image);

   package NP_Sender_Buffering is new Ordered_Maps_G (Key_Type        => Ada.Calendar.Time,
                                                      Value_Type      => T.Value_T,
                                                      "="             => OI.Sender_Buffering_Iguales,
                                                      "<"             => OI.Sender_Buffering_Menor,
                                                      ">"             => OI.Sender_Buffering_Mayor,
                                                      Key_To_String   => Img.Image_3,
                                                      Value_To_String => Img.Value_Image);

   package Neighbors is new Maps_Protector_G(NH_Neighbors);

   Lista_Vecinos: Neighbors.Prot_Map;

   package Latest_Msgs is new Maps_Protector_G(NP_Latest_Msgs);

   Lista_Mensajes: Latest_Msgs.Prot_Map;

   package Sender_Dests is new Ordered_Maps_Protector_G(NP_Sender_Dests);

   Lista_Dests: Sender_Dests.Prot_Map;

   package Sender_Buffering is new Ordered_Maps_Protector_G(NP_Sender_Buffering);

   Lista_Buffer: Sender_Buffering.Prot_Map;

   procedure Handler (From: in LLU.End_Point_Type;
                      To: in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);

end Chat_Handler;
