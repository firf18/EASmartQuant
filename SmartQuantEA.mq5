//+------------------------------------------------------------------+
//|                                                      SmartQuantEA|
//|                        Copyright 2025, Your Company Name          |
//|                                       your.email@example.com      |
//+------------------------------------------------------------------+
#include "Core/GestorActivos.mqh"

// Declaración global del gestor de activos
CGestorActivos gestorActivos;

//+------------------------------------------------------------------+
//| Función OnInit                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Cargar los activos desde el archivo JSON
   if (!gestorActivos.CargarActivos())
     {
      Print("❌ Error al cargar los activos desde JSON.");
      return INIT_FAILED;
     }

   // Mostrar los activos en la consola
   MostrarActivosEnConsola();

   // Mostrar los activos en el gráfico
   MostrarActivosEnGrafico();

   // Guardar los activos en un archivo de registro
   GuardarActivosEnArchivo();

   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//| Función OnTick                                                   |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Actualizar la visualización en el gráfico en cada tick
   MostrarActivosEnGrafico();
  }
//+------------------------------------------------------------------+
//| Función para mostrar activos en la consola                       |
//+------------------------------------------------------------------+
void MostrarActivosEnConsola() {
    Print("📌 Activos Cargados:");
    for (int i = 0; i < gestorActivos.ObtenerTotalActivos(); i++) {
        CActivoConfig *config = gestorActivos.ObtenerActivoPorIndice(i);
        if (config == NULL) continue;
        PrintFormat("%s: Activo=%s, Max Spread=%.2f",
                    config.nombre,
                    config.activo ? "Sí" : "No",
                    config.max_spread);
    }
}
//+------------------------------------------------------------------+
//| Función para mostrar activos en el gráfico                       |
//+------------------------------------------------------------------+
void MostrarActivosEnGrafico()
  {
   string mensaje = "📌 Activos Cargados:\n";
   for (int i = 0; i < gestorActivos.ObtenerTotalActivos(); i++)
     {
      CActivoConfig *config = (CActivoConfig*)gestorActivos.ObtenerActivoPorIndice(i);
      mensaje += StringFormat("%s: %s\n",
                              config.nombre,
                              config.activo ? "Activo" : "Inactivo");
     }
   Comment(mensaje);
  }
//+------------------------------------------------------------------+
//| Función para guardar activos en un archivo de registro           |
//+------------------------------------------------------------------+
void GuardarActivosEnArchivo()
  {
   int handle = FileOpen("ActivosLog.txt", FILE_WRITE | FILE_TXT);
   if (handle == INVALID_HANDLE)
     {
      Print("❌ Error al abrir el archivo de log.");
      return;
     }

   FileWrite(handle, "📌 Activos Cargados:");
   for (int i = 0; i < gestorActivos.ObtenerTotalActivos(); i++)
     {
      CActivoConfig *config = (CActivoConfig*)gestorActivos.ObtenerActivoPorIndice(i);
      FileWrite(handle, StringFormat("%s: Activo=%s, Max Spread=%.2f",
                                     config.nombre,
                                     config.activo ? "Sí" : "No",
                                     config.max_spread));
     }

   FileClose(handle);
   Print("✅ Log de activos guardado en 'Files/ActivosLog.txt'");
  }
//+------------------------------------------------------------------+
