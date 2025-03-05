//+------------------------------------------------------------------+
//| Configuracion.mqh - Carga de Configuración JSON                 |
//| Rama: feature/configuracion                                      |
//+------------------------------------------------------------------+
#include <JAson.mqh>

// Variables globales
bool logs_habilitados;
int tiempo_espera_ordenes;
double maximo_riesgo_por_operacion;
string activos[];
CJAVal estrategias;

//+------------------------------------------------------------------+
//| Función para cargar la configuración del EA                     |
//+------------------------------------------------------------------+
bool CargarConfiguracion() {
    CJAVal jsonConfig;
    
    // Leer el archivo JSON y verificar errores
    string jsonStr = FileToString("Config/general_config.json");
    if (jsonStr == "") {
        Print("❌ Error: No se pudo abrir el archivo de configuración.");
        return false;
    }
    
    char jsonArray[];
    StringToCharArray(jsonStr, jsonArray);
    if (!jsonConfig.Deserialize(jsonArray)) {
        Print("❌ Error al analizar JSON.");
        return false;
    }

    // Cargar parámetros generales
    logs_habilitados = jsonConfig["logs_habilitados"].ToBool();
   tiempo_espera_ordenes = (int)jsonConfig["tiempo_espera_ordenes"].ToInt();
    maximo_riesgo_por_operacion = jsonConfig["maximo_riesgo_por_operacion"].ToDbl();

    // Cargar lista de activos
    CJAVal activosJson = jsonConfig["activos"];
    if (activosJson.type == jtARRAY) {
        ArrayResize(activos, activosJson.Size());
        for (int i = 0; i < activosJson.Size(); i++) {
            activos[i] = activosJson[i].ToStr();
        }
    } else {
        Print("❌ Error: 'activos' no es un array en el JSON.");
        return false;
    }

    // Cargar estrategias por activo
    estrategias = jsonConfig["estrategias"];

    Print("✅ Configuración cargada con éxito.");
    return true;
}

//+------------------------------------------------------------------+
//| Función auxiliar para leer JSON desde archivo                    |
//+------------------------------------------------------------------+
string FileToString(string filePath) {
    int fileHandle = FileOpen(filePath, FILE_READ | FILE_TXT | FILE_ANSI);
    if (fileHandle == INVALID_HANDLE) {
        Print("❌ No se pudo abrir el archivo: ", filePath);
        return "";
    }

    string contenido = "";
    while (!FileIsEnding(fileHandle)) {
        contenido += FileReadString(fileHandle) + "\n";
    }

    FileClose(fileHandle);
    return contenido;
}
