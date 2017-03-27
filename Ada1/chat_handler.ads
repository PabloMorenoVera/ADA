--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.

with Ada.Text_IO;
With Ada.Strings.Unbounded;
with Maps_G;
with Lower_Layer_UDP;
with Ada.Calendar;
with Image;
with Tipo_Mensajes;
with Maps_Protector_G;
with Ada.Command_Line;
with Debug;
with Pantalla;

package Chat_Handler is
   package ASU  renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;
   package LLU renames Lower_Layer_UDP;
   package Img renames Image;
   package TP renames Tipo_Mensajes;

   use type TP.Message_Type;
   use type LLU.End_Point_Type;
   use type ASU.Unbounded_String;

   type Seq_N_T is mod Integer'Last;

   package NH_Neighbors is new Maps_G (Key_Type => LLU.End_Point_Type,
                                       Value_Type => Ada.Calendar.Time,
                                       Null_Key => Null,
                                       Null_Value => Ada.Calendar.Time_Of(2000,1,1),
                                       Max_Length => 10,
                                       "=" => LLU."=",
                                       Key_To_String => LLU.Image,
                                       Value_To_String => Img.Image_3);

   package NP_Latest_Msgs is new Maps_G (Key_Type => LLU.End_Point_Type,
                                         Value_Type => Seq_N_T,
                                         Null_Key => Null,
                                         Null_Value => 0,
                                         Max_Length => 50,
                                         "=" => LLU."=",
                                         Key_To_String => LLU.Image,
                                         Value_To_String => Seq_N_T'Image);

   package Neighbors is new Maps_Protector_G(NH_Neighbors);

   Lista_Vecinos: Neighbors.Prot_Map;

   package Latest_Msgs is new Maps_Protector_G(NP_Latest_Msgs);

   Lista_Mensajes: Latest_Msgs.Prot_Map;

   procedure Handler (From: in LLU.End_Point_Type;
                      To: in LLU.End_Point_Type;
                      P_Buffer: access LLU.Buffer_Type);

end Chat_Handler;
