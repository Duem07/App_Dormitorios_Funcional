class ApiConfig {
 static const String baseUrl = 'http://10.30.0.64:5000/api'; // esto es lo que cambia 
// static String get baseUrl {
   // if (Platform.isAndroid) {
    //  return 'http://10.0.2.2:5000/api';
   // } else if (Platform.isIOS) {
       // Si corres el simulador en la MISMA máquina que el servidor:
       // return 'http://127.0.0.1:5000/api';
       
       // Si el servidor está en tu PC Windows y el simulador en otra (o VM):
   //    return 'http://192.168.1.68:5000/api'; // <--- Pon aquí la IP local de tu PC (ipconfig en cmd)
 //   }
 //   return 'http://localhost:5000/api';
 // }
  static const String ULVAPI = 'https://ulv-api.apps.isdapps.uk/api/datos/';
 static const String otpApiUrl = 'https://api-otp.app.syswork.online/api/v1';
}
