//+------------------------------------------------------------------+
//| GestorActivos.mqh - Manejo de Activos en SmartQuantEA           |
//| Rama: feature/gestor-activos                                     |
//+------------------------------------------------------------------+
#include "Configuracion.mqh"
#include <Arrays\ArrayObj.mqh>
#include <Object.mqh>  
#include <JAson.mqh>

//+------------------------------------------------------------------+
//| Clase para representar la configuración de cada activo          |
//+------------------------------------------------------------------+
class CActivoConfig : public CObject {
public:
    string nombre;
    bool   activo;
    double max_spread;
    double spread_promedio;
    int    volumen_diario;
    double riesgo_permitido;
    int    sl_min, sl_max, tp_min, tp_max;

    void SetData(string _nombre, bool _activo, double _max_spread, double _spread_promedio,
                 int _volumen_diario, double _riesgo_permitido,
                 int _sl_min, int _sl_max, int _tp_min, int _tp_max) 
    {
        nombre            = _nombre;
        activo            = _activo;
        max_spread        = _max_spread;
        spread_promedio   = _spread_promedio;
        volumen_diario    = _volumen_diario;
        riesgo_permitido  = _riesgo_permitido;
        sl_min            = _sl_min;
        sl_max            = _sl_max;
        tp_min            = _tp_min;
        tp_max            = _tp_max;
    }
};

//+------------------------------------------------------------------+
//| Clase Gestor de Activos                                          |
//+------------------------------------------------------------------+
class CGestorActivos {
private:
    CArrayObj activosArray;

public:
    bool CargarActivos() 
    {
        // 1) Cargar el archivo en un string
        CJAVal root;
        string jsonStr = FileToString("Config/activos_config.json");
        if (jsonStr == "") 
        {
            Print("❌ Error: No se pudo abrir el archivo de activos.");
            return false;
        }

        // Depuración: imprimir el JSON antes de deserializarlo
        Print("📄 JSON cargado: ", jsonStr);

        // 2) Deserializar a un objeto root
        char jsonArray[];
        StringToCharArray(jsonStr, jsonArray);
        if (!root.Deserialize(jsonArray)) 
        {
            Print("❌ Error al analizar JSON de activos.");
            return false;
        }

        // 3) Bajar al nivel de la clave "activos"
        if (!root.HasKey("activos")) 
        {
            Print("❌ Error: El JSON no contiene la clave \"activos\".");
            return false;
        }

        CJAVal jsonActivos = root["activos"];

        // Verificar que "activos" sea un objeto
        if (jsonActivos.type != jtOBJ)
        {
            Print("❌ Error: La clave \"activos\" no es un objeto JSON.");
            return false;
        }

        // 4) Iterar sobre las claves dentro de "activos" (EURUSD, GBPUSD, etc.)
        for (int i = 0; i < jsonActivos.Size(); i++) 
        {
            // La i-ésima clave, p. ej. "EURUSD"
            string nombreActivo = jsonActivos[i].key;
            
            // Validar que exista esa clave
            if (!jsonActivos.HasKey(nombreActivo)) 
            {
                PrintFormat("❌ Error: No se encontró la configuración del activo: %s", nombreActivo);
                continue;
            }

            CJAVal activoJson = jsonActivos[nombreActivo];

            // Depuración: imprimir el JSON de cada activo
            PrintFormat("📊 Activo JSON [%s]: %s", nombreActivo, activoJson.Serialize());

            // Validar si es un objeto JSON
            if (activoJson.type != jtOBJ) 
            {
                PrintFormat("❌ Error: Formato incorrecto en la configuración del activo: %s", nombreActivo);
                continue;
            }

            // 5) Crear la configuración del activo
            CActivoConfig *config = new CActivoConfig;

            // Asignar valores de forma segura
            config.nombre          = nombreActivo;
            config.activo          = (activoJson.HasKey("activo") && activoJson["activo"].type == jtBOOL)
                                     ? activoJson["activo"].ToBool() : false;

            config.max_spread      = (activoJson.HasKey("max_spread"))
                                     ? StringToDouble(activoJson["max_spread"].ToStr()) : 0.0;

            config.spread_promedio = (activoJson.HasKey("spread_promedio"))
                                     ? StringToDouble(activoJson["spread_promedio"].ToStr()) : 0.0;

            config.volumen_diario  = (activoJson.HasKey("volumen_diario"))
                                     ? (int)StringToInteger(activoJson["volumen_diario"].ToStr()) : 0;

            config.riesgo_permitido= (activoJson.HasKey("riesgo_permitido"))
                                     ? StringToDouble(activoJson["riesgo_permitido"].ToStr()) : 0.0;

            // 6) Verificar existencia de sl_tp
            if (activoJson.HasKey("sl_tp") && activoJson["sl_tp"].type == jtOBJ) 
            {
                CJAVal slTpJson   = activoJson["sl_tp"];
                config.sl_min     = (slTpJson.HasKey("sl_min"))
                                    ? (int)StringToInteger(slTpJson["sl_min"].ToStr()) : 0;
                config.sl_max     = (slTpJson.HasKey("sl_max"))
                                    ? (int)StringToInteger(slTpJson["sl_max"].ToStr()) : 0;
                config.tp_min     = (slTpJson.HasKey("tp_min"))
                                    ? (int)StringToInteger(slTpJson["tp_min"].ToStr()) : 0;
                config.tp_max     = (slTpJson.HasKey("tp_max"))
                                    ? (int)StringToInteger(slTpJson["tp_max"].ToStr()) : 0;
            }
            else 
            {
                config.sl_min = 0; 
                config.sl_max = 0; 
                config.tp_min = 0; 
                config.tp_max = 0;
            }

            // Mensaje de depuración
            PrintFormat("✅ Activo cargado: %s | Activo: %s | Max Spread: %.2f | Riesgo: %.2f%%",
                        config.nombre, 
                        config.activo ? "true" : "false", 
                        config.max_spread, 
                        config.riesgo_permitido);

            // Agregar a nuestro array de activos
            activosArray.Add(config);
            PrintFormat("✅ Activo cargado: %s, Max Spread: %.2f, Riesgo: %.2f%%",
                        config.nombre, 
                        config.max_spread, 
                        config.riesgo_permitido);
        }

        Print("✅ Configuración de activos cargada correctamente.");
        return true;
    }

    // Método para obtener la cantidad total de activos
    int ObtenerTotalActivos() 
    {
        return activosArray.Total();
    }

    // Método para obtener un activo por índice
    CActivoConfig* ObtenerActivoPorIndice(int index) 
    {
        if (index < 0 || index >= activosArray.Total()) 
            return NULL;
        return (CActivoConfig*)activosArray.At(index);
    }
};
