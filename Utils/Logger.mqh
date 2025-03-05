//+------------------------------------------------------------------+
//| Logger - Manejo de Logs en SmartQuantEA                         |
//| Rama: feature/logger                                            |
//+------------------------------------------------------------------+
#include <Files\FileTxt.mqh>

// Definición de niveles de log
enum LOG_LEVEL {INFO, WARNING, ERROR};

// Variables globales
#define MAX_LOG_SIZE 5242880  // 5MB en bytes
#define MAX_LOG_DAYS 15       // Mantener solo los últimos 15 días
bool logs_habilitados = true; // Se cargará desde JSON
string logFileName;

//+------------------------------------------------------------------+
//| Inicializa el Logger con el nombre de archivo basado en fecha   |
//+------------------------------------------------------------------+
void Logger_Init() {
    logFileName = "Logs/execution_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
    VerificarRotacionLogs();
}

//+------------------------------------------------------------------+
//| Manejo de logs                                                  |
//+------------------------------------------------------------------+
void Logger_Print(LOG_LEVEL level, string message) {
    if (!logs_habilitados) return;
    
    string timestamp = TimeToString(TimeCurrent(), TIME_SECONDS);
    string levelStr;
    
    switch(level) {
        case INFO: levelStr = "INFO"; break;
        case WARNING: levelStr = "WARNING"; break;
        case ERROR: levelStr = "ERROR"; break;
    }
    
    string logMessage = "[" + timestamp + "] [" + levelStr + "] " + message;

    // Escribir en archivo
    int fileHandle = FileOpen(logFileName, FILE_READ|FILE_WRITE|FILE_TXT|FILE_SHARE_WRITE);
    if (fileHandle != INVALID_HANDLE) {
        FileSeek(fileHandle, 0, SEEK_END);
        FileWrite(fileHandle, logMessage);
        FileClose(fileHandle);
    }

    // Mostrar en consola de MetaTrader
    Print(logMessage);
    
    // Alertas y envíos según nivel
    if (level == ERROR) {
        Alert("❌ ERROR: " + message);
        EnviarErrorMySQL(logMessage);
        EnviarErrorTelegram(logMessage);
    }
}

//+------------------------------------------------------------------+
//| Rotación de logs                                                |
//+------------------------------------------------------------------+
void VerificarRotacionLogs() {
    // Si el archivo supera 5MB, crear un nuevo archivo
    int fileHandle = FileOpen(logFileName, FILE_READ);
    if (fileHandle != INVALID_HANDLE) {
        ulong fileSize = FileSize(fileHandle);
        FileClose(fileHandle);
        if (fileSize > MAX_LOG_SIZE) {
            string newLogFile = "Logs/execution_" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + ".log";
            if(!FileMove(logFileName, 0, newLogFile, FILE_REWRITE)){
               Print("❌ Error al mover el archivo de log: ", logFileName);
            }
        }
    }

    // Eliminar logs mayores a 15 días
    for (int i = MAX_LOG_DAYS + 1; i <= MAX_LOG_DAYS * 2; i++) {
        string oldDate = TimeToString(TimeCurrent() - i * 86400, TIME_DATE);
        string oldLogFile = "Logs/execution_" + oldDate + ".log";
        FileDelete(oldLogFile);
    }
}

//+------------------------------------------------------------------+
//| Enviar error a MySQL                                            |
//+------------------------------------------------------------------+
void EnviarErrorMySQL(string mensaje) {
    // Llamar a la función de conexión MySQL para insertar el log
    Print("🛠 Enviando error a MySQL: " + mensaje);
}

//+------------------------------------------------------------------+
//| Enviar error a Telegram                                         |
//+------------------------------------------------------------------+
void EnviarErrorTelegram(string mensaje) {
    string apiUrl = "https://api.telegram.org/7934629531:AAFY5KoCfy7lJfqHBdj-oBkWtESzHqZ49rQ/sendMessage?chat_id=-4605136076&text=" + mensaje;
    char result[];
    string response;
    string headers = "";
    char data[];
    
    int responseCode = WebRequest("GET", apiUrl, headers, 5000, data, result, response);
    
    if (responseCode != 200) {
        Print("❌ Error al enviar mensaje a Telegram: ", responseCode);
    }
}
